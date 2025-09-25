// SPDX-License-Identifier: MIT
#pragma once

#include <QMainWindow>
#include <QPointer>

class QAction;
class QDockWidget;
class QTreeView;

class QgsMapCanvas;
class QgsLayerTreeView;
class QgsLayerTreeModel;
class QgsProject;
class QgsMapToolPan;
class QgsMapToolZoom;
class QgsMapToolIdentifyFeature;

class MainWindow : public QMainWindow {
  Q_OBJECT
public:
  explicit MainWindow(QWidget* parent = nullptr);
  ~MainWindow() override;

private slots:
  void onOpenProject();
  void onZoomFull();
  void onIdentifyToggled(bool checked);

private:
  void createUi();
  void createActions();
  void createDock();
  void loadDefaultLayers();
  void addXyzBasemap(const QString& name, const QString& urlTemplate);

private:
  QPointer<QgsMapCanvas> m_canvas;
  QPointer<QgsLayerTreeView> m_layerTree;
  QPointer<QgsLayerTreeModel> m_layerModel;
  QDockWidget* m_layerDock {nullptr};

  // Tools
  QPointer<QgsMapToolPan> m_panTool;
  QPointer<QgsMapToolZoom> m_zoomInTool;
  QPointer<QgsMapToolZoom> m_zoomOutTool;
  QPointer<QgsMapToolIdentifyFeature> m_identifyTool;

  // Actions
  QAction* m_actOpen {nullptr};
  QAction* m_actZoomFull {nullptr};
  QAction* m_actPan {nullptr};
  QAction* m_actZoomIn {nullptr};
  QAction* m_actZoomOut {nullptr};
  QAction* m_actIdentify {nullptr};
};

