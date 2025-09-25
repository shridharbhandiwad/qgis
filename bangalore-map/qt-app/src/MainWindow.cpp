// SPDX-License-Identifier: MIT
#include "MainWindow.h"

#include <QAction>
#include <QApplication>
#include <QDockWidget>
#include <QFileDialog>
#include <QMenuBar>
#include <QStatusBar>
#include <QToolBar>

#include <qgsapplication.h>
#include <qgscoordinatereferencesystem.h>
#include <qgslayertree.h>
#include <qgslayertreemodel.h>
#include <qgslayertreeview.h>
#include <qgsmapcanvas.h>
#include <qgsmaplayer.h>
#include <qgsrectangle.h>
#include <qgsmaptoolidentifyfeature.h>
#include <qgsmaptoolpan.h>
#include <qgsmaptoolzoom.h>
#include <qgsproject.h>
#include <qgsrasterlayer.h>
#include <qgsvectorlayer.h>

namespace {
QString projectRoot() {
  // Default to workspace, allow override by env
  const QByteArray env = qgetenv("BANGALORE_MAP_ROOT");
  if (!env.isEmpty()) return QString::fromUtf8(env);
  return QStringLiteral("/workspace/bangalore-map");
}
}

MainWindow::MainWindow(QWidget* parent) : QMainWindow(parent) {
  createUi();
  createActions();
  createDock();
  loadDefaultLayers();
}

MainWindow::~MainWindow() = default;

void MainWindow::createUi() {
  m_canvas = new QgsMapCanvas(this);
  m_canvas->setCanvasColor(Qt::white);
  // CRS transforms are automatic in modern QGIS; no explicit toggle needed
  m_canvas->setDestinationCrs(QgsCoordinateReferenceSystem::fromEpsgId(4326));

  setCentralWidget(m_canvas);

  auto* tb = addToolBar(tr("Map"));
  tb->setMovable(false);

  statusBar()->showMessage(tr("Ready"));
}

void MainWindow::createActions() {
  // File
  auto* mFile = menuBar()->addMenu(tr("&File"));
  m_actOpen = new QAction(tr("Open Project…"), this);
  connect(m_actOpen, &QAction::triggered, this, &MainWindow::onOpenProject);
  mFile->addAction(m_actOpen);

  // View
  auto* mView = menuBar()->addMenu(tr("&View"));
  m_actZoomFull = new QAction(tr("Zoom Full"), this);
  connect(m_actZoomFull, &QAction::triggered, this, &MainWindow::onZoomFull);
  mView->addAction(m_actZoomFull);

  // Tools toolbar
  auto* tb = addToolBar(tr("Tools"));
  m_panTool = new QgsMapToolPan(m_canvas);
  m_panTool->setAction(nullptr);
  m_actPan = tb->addAction(tr("Pan"));
  connect(m_actPan, &QAction::triggered, this, [this] { m_canvas->setMapTool(m_panTool); });

  m_zoomInTool = new QgsMapToolZoom(m_canvas, false);
  m_actZoomIn = tb->addAction(tr("Zoom +"));
  connect(m_actZoomIn, &QAction::triggered, this, [this] { m_canvas->setMapTool(m_zoomInTool); });

  m_zoomOutTool = new QgsMapToolZoom(m_canvas, true);
  m_actZoomOut = tb->addAction(tr("Zoom -"));
  connect(m_actZoomOut, &QAction::triggered, this, [this] { m_canvas->setMapTool(m_zoomOutTool); });

  m_identifyTool = new QgsMapToolIdentifyFeature(m_canvas);
  m_actIdentify = tb->addAction(tr("Identify"));
  m_actIdentify->setCheckable(true);
  connect(m_actIdentify, &QAction::toggled, this, &MainWindow::onIdentifyToggled);
}

void MainWindow::createDock() {
  auto* root = QgsProject::instance()->layerTreeRoot();
  m_layerModel = new QgsLayerTreeModel(root, this);
  m_layerModel->setFlag(QgsLayerTreeModel::AllowNodeChangeVisibility);
  m_layerModel->setFlag(QgsLayerTreeModel::UseEmbeddedWidgets);

  m_layerTree = new QgsLayerTreeView(this);
  m_layerTree->setModel(m_layerModel);

  m_layerDock = new QDockWidget(tr("Layers"), this);
  m_layerDock->setWidget(m_layerTree);
  addDockWidget(Qt::LeftDockWidgetArea, m_layerDock);
}

void MainWindow::loadDefaultLayers() {
  const QString root = projectRoot();
  const QString gpkg = root + QStringLiteral("/data/processed/bangalore.gpkg");

  // Add XYZ basemaps first so they sit at the bottom
  addXyzBasemap("OpenStreetMap", "https://tile.openstreetmap.org/{z}/{x}/{y}.png");
  addXyzBasemap("ESRI Satellite", "https://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}");
  addXyzBasemap("Carto Light", "https://cartodb-basemaps-a.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png");

  if (QFile::exists(gpkg)) {
    const struct LayerSpec { const char* name; const char* title; } specs[] = {
      {"bangalore_boundary", "Bangalore Boundary"},
      {"bbmp_wards", "BBMP Wards"},
      {"roads", "Roads"},
      {"waterways", "Waterways"},
      {"landuse", "Landuse"},
      {"buildings", "Buildings"},
    };
    for (const auto& s : specs) {
      const QString uri = QStringLiteral("%1|layername=%2").arg(gpkg, s.name);
      auto* v = new QgsVectorLayer(uri, QString::fromUtf8(s.title), "ogr");
      if (v->isValid()) {
        QgsProject::instance()->addMapLayer(v);
      } else {
        v->deleteLater();
      }
    }
  }

  // Set canvas layers and extent
  const auto layers = QgsProject::instance()->mapLayers().values();
  m_canvas->setLayers(layers);
  if (!layers.isEmpty()) {
    m_canvas->setExtent(layers.first()->extent());
    m_canvas->refresh();
  }
}

void MainWindow::addXyzBasemap(const QString& name, const QString& urlTemplate) {
  const QString uri = QStringLiteral("type=xyz&url=%1").arg(urlTemplate);
  auto* rl = new QgsRasterLayer(uri, name, "wms");
  if (rl->isValid()) {
    QgsProject::instance()->addMapLayer(rl);
  } else {
    rl->deleteLater();
  }
}

void MainWindow::onOpenProject() {
  const QString fn = QFileDialog::getOpenFileName(this, tr("Open QGIS Project"), projectRoot() + "/project", tr("QGIS Project (*.qgz *.qgs)"));
  if (fn.isEmpty()) return;
  if (!QgsProject::instance()->read(fn)) {
    statusBar()->showMessage(tr("Failed to open project"), 4000);
    return;
  }
  const auto layers = QgsProject::instance()->mapLayers().values();
  m_canvas->setLayers(layers);
  if (!layers.isEmpty()) {
    m_canvas->setExtent(layers.first()->extent());
  }
  m_canvas->refresh();
}

void MainWindow::onZoomFull() {
  const auto layers = QgsProject::instance()->mapLayers().values();
  if (layers.isEmpty()) return;
  QgsRectangle extent;
  bool first = true;
  for (auto* lyr : layers) {
    if (!lyr) continue;
    if (first) { extent = lyr->extent(); first = false; }
    else { extent.combineExtentWith(lyr->extent()); }
  }
  if (!first) {
    m_canvas->setExtent(extent);
    m_canvas->refresh();
  }
}

void MainWindow::onIdentifyToggled(bool checked) {
  if (checked) {
    m_canvas->setMapTool(m_identifyTool);
  } else {
    m_canvas->unsetMapTool(m_identifyTool);
  }
}

