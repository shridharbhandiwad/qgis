// SPDX-License-Identifier: MIT
#include "MainWindow.h"

#include <QApplication>

#include <qgsapplication.h>
#include <qgsproviderregistry.h>

int main(int argc, char** argv) {
  // Initialize Qt
  QApplication app(argc, argv);

  // Initialize QGIS application (no GUI paths required for system install)
  QgsApplication qgsApp(argc, argv, true);
  QgsApplication::initQgis();

  MainWindow w;
  w.resize(1200, 800);
  w.show();

  const int rc = app.exec();
  QgsApplication::exitQgis();
  return rc;
}

