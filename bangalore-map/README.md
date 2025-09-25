# Bangalore QGIS Map

This repository builds a detailed QGIS 3.44 project of Bengaluru (BBMP) with OSM-derived layers, wards, and multiple XYZ basemaps. It includes scripts to install QGIS on Ubuntu, download/process data, and auto-generate a styled QGIS project.

## Prerequisites
- Ubuntu with `sudo`
- Internet access

## Install QGIS 3.44 (Qt 5.15)
```bash
sudo bash scripts/setup_qgis_ubuntu.sh
```

Notes:
- On unsupported Ubuntu releases, the script falls back to using the 24.04 (noble) QGIS repo.

## Download and process data
```bash
bash scripts/download_data.sh
bash scripts/process_data.sh
```

Outputs a GeoPackage at `data/processed/bangalore.gpkg` with boundary, wards, and clipped OSM layers.

## Build the QGIS project
Run from within a PyQGIS environment (e.g., `qgis` Python console) or using `qgis_process run` with a Python runner.
Simplest approach: open QGIS and run `scripts/build_project.py` in the Python console.

Expected output: `project/bangalore_map.qgz`

## Enhanced options to play around the map
- Enable plugins: QuickMapServices, DataPlotly, qgis2web, TimeManager (if needed)
- Add more XYZ sources: in QGIS, `Browser` > `XYZ Tiles` > `New Connection`
- Use Styling Panel to tweak colors, labels (e.g., label wards by name), and layer ordering
- Set Scale-Based Visibility for buildings/roads for performance and clarity
- Create Bookmarks for key areas (MG Road, Electronic City, Whitefield, Airport)
- Use Map Themes to quickly switch between Light, Dark, Satellite blends

## Troubleshooting
- If ward/boundary downloads fail, update URLs in `scripts/download_data.sh` to alternative authoritative sources (BBMP/KSRSAC/open data portals)
- If XYZ tiles don't load, verify network/proxy and try alternate servers
