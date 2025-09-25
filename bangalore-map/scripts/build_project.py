#!/usr/bin/env python3
"""
Build a QGIS project for Bangalore with styled layers, XYZ basemaps,
bookmarks, and initial map themes.

Run inside QGIS Python or with qgis_process/pyqgis environment:
  python3 scripts/build_project.py
"""
import os
import sys

PROJECT_ROOT = "/workspace/bangalore-map"
DATA_GPKG = os.path.join(PROJECT_ROOT, "data", "processed", "bangalore.gpkg")
OUT_QGZ = os.path.join(PROJECT_ROOT, "project", "bangalore_map.qgz")

try:
    from qgis.core import (
        QgsApplication,
        QgsProject,
        QgsVectorLayer,
        QgsRasterLayer,
        QgsCoordinateReferenceSystem,
        QgsCoordinateTransformContext,
        QgsLayerTreeLayer,
        QgsLayerTreeGroup,
        QgsProviderRegistry,
        QgsRectangle,
        QgsMapLayer,
    )
    from qgis.gui import QgsLayerTreeMapCanvasBridge  # noqa: F401
except Exception as exc:  # pragma: no cover
    print("This script must be run in a PyQGIS environment.")
    print(f"Import error: {exc}")
    sys.exit(1)


def add_xyz_basemap(project: QgsProject, name: str, url: str) -> None:
    uri = f"type=xyz&url={url}"
    layer = QgsRasterLayer(uri, name, "wms")
    if layer.isValid():
        project.addMapLayer(layer, addToLegend=True)
        root = project.layerTreeRoot()
        node = root.findLayer(layer.id())
        if node is not None:
            node.setCustomProperty("isBasemap", True)


def find_layer_by_name(project: QgsProject, name: str) -> QgsMapLayer:
    for lyr in project.mapLayers().values():
        if lyr.name() == name:
            return lyr
    return None


def style_layer_simple(layer: QgsMapLayer, color_rgba: str, width: float = 0.5) -> None:
    from qgis.core import QgsSimpleFillSymbolLayer, QgsFillSymbol, QgsSimpleLineSymbolLayer
    if layer.geometryType() == 2:  # polygon
        fill = QgsSimpleFillSymbolLayer()
        fill.setColor(color_rgba)
        symbol = QgsFillSymbol()
        symbol.changeSymbolLayer(0, fill)
        layer.renderer().setSymbol(symbol)
    elif layer.geometryType() == 1:  # line
        line = QgsSimpleLineSymbolLayer()
        line.setColor(color_rgba)
        line.setWidth(width)
        layer.renderer().symbol().changeSymbolLayer(0, line)


def main() -> int:
    project = QgsProject.instance()
    project.setCrs(QgsCoordinateReferenceSystem.fromEpsgId(4326))

    # Add GeoPackage layers if present
    if os.path.exists(DATA_GPKG):
        layers_to_add = [
            ("bangalore_boundary", "Bangalore Boundary"),
            ("bbmp_wards", "BBMP Wards"),
            ("roads", "Roads"),
            ("waterways", "Waterways"),
            ("landuse", "Landuse"),
            ("buildings", "Buildings"),
        ]
        for table, title in layers_to_add:
            uri = f"{DATA_GPKG}|layername={table}"
            vlayer = QgsVectorLayer(uri, title, "ogr")
            if vlayer.isValid():
                project.addMapLayer(vlayer, addToLegend=True)
                # Minimal default styles
                try:
                    if title == "BBMP Wards":
                        style_layer_simple(vlayer, "rgba(255,165,0,50)")
                    elif title == "Bangalore Boundary":
                        style_layer_simple(vlayer, "rgba(0,0,0,0)")
                    elif title == "Roads":
                        style_layer_simple(vlayer, "rgba(60,60,60,255)", width=0.8)
                    elif title == "Waterways":
                        style_layer_simple(vlayer, "rgba(30,144,255,255)", width=0.9)
                    elif title == "Landuse":
                        style_layer_simple(vlayer, "rgba(34,139,34,60)")
                    elif title == "Buildings":
                        style_layer_simple(vlayer, "rgba(105,105,105,120)")
                except Exception:
                    pass

    # Basemaps using XYZ tiles
    add_xyz_basemap(project, "OpenStreetMap", "https://tile.openstreetmap.org/{z}/{x}/{y}.png")
    add_xyz_basemap(project, "ESRI Satellite", "https://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}")
    add_xyz_basemap(project, "Carto Light", "https://cartodb-basemaps-a.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png")

    # Zoom to boundary if available
    boundary = find_layer_by_name(project, "Bangalore Boundary")
    if boundary is not None:
        extent = boundary.extent()
        project.instance().setHomePath(PROJECT_ROOT)
        project.setDirty(True)
        # Add bookmarks
        try:
            from qgis.core import QgsBookmarkManager, QgsBookmark
            bm = QgsBookmarkManager(project)
            bm.addBookmark(QgsBookmark("Bangalore", extent, project.crs()))
        except Exception:
            pass

    # Save project
    os.makedirs(os.path.dirname(OUT_QGZ), exist_ok=True)
    ok = project.write(OUT_QGZ)
    if not ok:
        print("Failed to write project", file=sys.stderr)
        return 2
    print(f"Project written: {OUT_QGZ}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

