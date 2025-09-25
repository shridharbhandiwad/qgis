## Qt C++ QGIS App (qmake)

This is a Qt Widgets C++ app embedding QGIS (`QgsMapCanvas`) to explore a detailed Bengaluru map with XYZ basemaps and layers from `data/processed/bangalore.gpkg`.

### Dependencies
- Qt 5.15 (Widgets)
- QGIS 3.x SDK libraries (qgis_core, qgis_gui, qgis_analysis)
- pkg-config (recommended)

On Ubuntu:
```bash
sudo apt update
sudo apt install -y qtbase5-dev qgis python3-qgis libqgis-dev pkg-config build-essential
```

### Build
```bash
cd /workspace/bangalore-map/qt-app
qmake bangalore_map.pro
make -j$(nproc)
./bangalore_map
```

Optional: set `BANGALORE_MAP_ROOT` to point to your project root (defaults to `/workspace/bangalore-map`).

### Features
- `QgsMapCanvas` with pan/zoom tools
- Layer tree dock to toggle visibility
- Load XYZ basemaps (OSM, ESRI Satellite, Carto Light)
- Load GeoPackage layers: `bangalore_boundary`, `bbmp_wards`, `roads`, `waterways`, `landuse`, `buildings`
- Identify tool to query features

### Notes
- Ensure `data/processed/bangalore.gpkg` exists (run the data scripts in the repo root)
- If QGIS libs are not found via `pkg-config`, edit `bangalore_map.pro` include/lib paths accordingly

