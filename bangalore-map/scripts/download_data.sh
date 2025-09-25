#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="/workspace/bangalore-map"
RAW_DIR="${ROOT_DIR}/data/raw"
mkdir -p "${RAW_DIR}"

download() {
  local url="$1"; shift
  local out="$1"; shift
  echo "Downloading: ${url}" >&2
  curl -L --fail --retry 3 -o "${out}" "${url}"
}

# Geofabrik OSM extracts
download "https://download.geofabrik.de/asia/india/karnataka-latest-free.shp.zip" "${RAW_DIR}/karnataka-latest-free.shp.zip"
download "https://download.geofabrik.de/asia/india/karnataka-latest.osm.pbf" "${RAW_DIR}/karnataka.osm.pbf"

# Bengaluru boundary and wards
# Primary: OpenCity / DataMeet mirrors (community). These URLs may change; adjust if 404.
BOUNDARY_URL="https://raw.githubusercontent.com/datameet/Bengaluru/master/Administrative/BBMP/bbmp_boundary.geojson"
WARDS_URL="https://raw.githubusercontent.com/datameet/Bengaluru/master/Administrative/BBMP/bbmp_wards.geojson"

set +e
download "${BOUNDARY_URL}" "${RAW_DIR}/bbmp-boundary.geojson" || echo "Warning: boundary not fetched"
download "${WARDS_URL}" "${RAW_DIR}/bbmp-wards.geojson" || echo "Warning: wards not fetched"
set -e

echo "All downloads attempted."

