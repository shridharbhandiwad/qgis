#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
qmake bangalore_map.pro
make -j"${JOBS:-$(nproc)}"
echo "Built: ./bangalore_map"

