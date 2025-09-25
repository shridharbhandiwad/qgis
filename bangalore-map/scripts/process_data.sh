#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="/workspace/bangalore-map"
RAW_DIR="${ROOT_DIR}/data/raw"
PROC_DIR="${ROOT_DIR}/data/processed"
mkdir -p "${PROC_DIR}"

# Requires: gdal-bin (ogr2ogr), unzip

# Unzip OSM shapefiles if present
if [[ -f "${RAW_DIR}/karnataka-latest-free.shp.zip" ]]; then
  echo "Unzipping Geofabrik shapefiles..." >&2
  mkdir -p "${PROC_DIR}/karnataka_shp"
  unzip -o "${RAW_DIR}/karnataka-latest-free.shp.zip" -d "${PROC_DIR}/karnataka_shp"
fi

BOUNDARY_GEOJSON="${RAW_DIR}/bbmp-boundary.geojson"
WARDS_GEOJSON="${RAW_DIR}/bbmp-wards.geojson"

if [[ ! -s "${BOUNDARY_GEOJSON}" ]]; then
  # Try nominatim fallback
  if command -v python3 >/dev/null 2>&1; then
    echo "Fetching boundary via Nominatim fallback..." >&2
    python3 "/workspace/bangalore-map/scripts/fetch_boundary_nominatim.py" || true
  fi
fi

if [[ -s "${BOUNDARY_GEOJSON}" ]]; then
  echo "Reprojecting boundary to EPSG:4326 and saving GeoPackage..." >&2
  ogr2ogr -t_srs EPSG:4326 -f GPKG "${PROC_DIR}/bangalore.gpkg" "${BOUNDARY_GEOJSON}" -nln bangalore_boundary -nlt MULTIPOLYGON -overwrite
else
  echo "Warning: boundary not found or empty. Skipping boundary processing." >&2
fi

if [[ -s "${WARDS_GEOJSON}" ]]; then
  echo "Reprojecting wards to EPSG:4326 and adding to GeoPackage..." >&2
  ogr2ogr -t_srs EPSG:4326 -f GPKG "${PROC_DIR}/bangalore.gpkg" "${WARDS_GEOJSON}" -nln bbmp_wards -nlt MULTIPOLYGON -update
else
  echo "Warning: wards not found or empty. Skipping wards processing." >&2
fi

# Clip selected OSM layers (roads, waterways, landuse) to Bangalore boundary if available
if [[ -s "${PROC_DIR}/bangalore.gpkg" ]]; then
  HAS_BOUNDARY=$(ogrinfo -so "${PROC_DIR}/bangalore.gpkg" bangalore_boundary >/dev/null 2>&1; echo $?)
  if [[ "$HAS_BOUNDARY" -eq 0 ]]; then
    echo "Preparing clip mask from boundary..." >&2
    CLIP_SRC="${PROC_DIR}/bangalore.gpkg"
    CLIP_LAYER="bangalore_boundary"

    # Roads
    ROADS_SHP_DIR="${PROC_DIR}/karnataka_shp/gis_osm_roads_free_1.shp"
    if [[ -f "${ROADS_SHP_DIR}" ]]; then
      echo "Clipping roads..." >&2
      ogr2ogr -t_srs EPSG:4326 -clipsrc "${CLIP_SRC}" -clipsrclayer "${CLIP_LAYER}" -f GPKG "${PROC_DIR}/bangalore.gpkg" "${PROC_DIR}/karnataka_shp/gis_osm_roads_free_1.shp" -nln roads -nlt MULTILINESTRING -update
    fi

    # Waterways
    if [[ -f "${PROC_DIR}/karnataka_shp/gis_osm_waterways_free_1.shp" ]]; then
      echo "Clipping waterways..." >&2
      ogr2ogr -t_srs EPSG:4326 -clipsrc "${CLIP_SRC}" -clipsrclayer "${CLIP_LAYER}" -f GPKG "${PROC_DIR}/bangalore.gpkg" "${PROC_DIR}/karnataka_shp/gis_osm_waterways_free_1.shp" -nln waterways -nlt MULTILINESTRING -update
    fi

    # Landuse
    if [[ -f "${PROC_DIR}/karnataka_shp/gis_osm_landuse_a_free_1.shp" ]]; then
      echo "Clipping landuse..." >&2
      ogr2ogr -t_srs EPSG:4326 -clipsrc "${CLIP_SRC}" -clipsrclayer "${CLIP_LAYER}" -f GPKG "${PROC_DIR}/bangalore.gpkg" "${PROC_DIR}/karnataka_shp/gis_osm_landuse_a_free_1.shp" -nln landuse -nlt MULTIPOLYGON -update
    fi

    # Buildings (optional, may be large)
    if [[ -f "${PROC_DIR}/karnataka_shp/gis_osm_buildings_a_free_1.shp" ]]; then
      echo "Clipping buildings (this may take time)..." >&2
      ogr2ogr -t_srs EPSG:4326 -clipsrc "${CLIP_SRC}" -clipsrclayer "${CLIP_LAYER}" -f GPKG "${PROC_DIR}/bangalore.gpkg" "${PROC_DIR}/karnataka_shp/gis_osm_buildings_a_free_1.shp" -nln buildings -nlt MULTIPOLYGON -update
    fi

  else
    echo "Boundary layer not found inside GeoPackage. Skipping clipping." >&2
  fi
else
  echo "GeoPackage not found. Skipping clipping." >&2
fi

echo "Processing complete. Output: ${PROC_DIR}/bangalore.gpkg (if inputs existed)"

