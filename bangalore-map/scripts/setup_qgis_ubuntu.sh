#!/usr/bin/env bash
set -euo pipefail

# Install QGIS 3.44 (Qt 5.15) on Ubuntu with sensible fallbacks
# - Prefers official QGIS APT repo
# - On unsupported Ubuntu codenames (e.g., 25.04 plucky), falls back to noble (24.04) repo

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  echo "Please run as root or with sudo: sudo bash $0" >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-install-recommends software-properties-common wget gnupg ca-certificates lsb-release

UBU_CODENAME=$(lsb_release -sc || true)
if [[ -z "${UBU_CODENAME}" ]]; then
  # Try to read from /etc/os-release
  UBU_CODENAME=$(grep -E '^VERSION_CODENAME=' /etc/os-release | cut -d'=' -f2 || true)
fi

echo "Detected Ubuntu codename: ${UBU_CODENAME:-unknown}" >&2

# If codename is not supported by QGIS repo, fallback to noble (24.04 LTS)
FALLBACK_CODENAME=noble

add_qgis_repo() {
  local codename="$1"
  echo "Adding QGIS repo for ${codename}" >&2
  echo "deb [signed-by=/etc/apt/trusted.gpg.d/qgis-archive.gpg] https://qgis.org/ubuntu ${codename} main" \
    > /etc/apt/sources.list.d/qgis.sources.list
  wget -qO- https://qgis.org/downloads/qgis-2020.gpg.key | gpg --dearmor -o /etc/apt/trusted.gpg.d/qgis-archive.gpg
}

add_qgis_repo "${UBU_CODENAME:-$FALLBACK_CODENAME}" || true
apt-get update -y || true

# If update fails or cannot find packages, try fallback
if ! apt-cache policy qgis | grep -q "Candidate"; then
  echo "Primary repo may be unsupported. Falling back to ${FALLBACK_CODENAME}" >&2
  add_qgis_repo "${FALLBACK_CODENAME}"
  apt-get update -y
fi

apt-get install -y qgis qgis-plugin-grass gdal-bin python3-gdal unzip curl

echo "QGIS installation complete. Version:" >&2
qgis --version || true

