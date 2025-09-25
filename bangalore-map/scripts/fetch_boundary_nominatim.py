#!/usr/bin/env python3
import json
import os
import sys
import urllib.parse
import urllib.request

RAW_DIR = "/workspace/bangalore-map/data/raw"
OUT_PATH = os.path.join(RAW_DIR, "bbmp-boundary.geojson")


def fetch_nominatim_boundary(query: str) -> dict:
    params = {
        "q": query,
        "format": "jsonv2",
        "polygon_geojson": 1,
        "addressdetails": 1,
        "limit": 5,
    }
    url = "https://nominatim.openstreetmap.org/search?" + urllib.parse.urlencode(params)
    req = urllib.request.Request(url, headers={"User-Agent": "bangalore-map-qgis/1.0 (contact: local)"})
    with urllib.request.urlopen(req, timeout=60) as resp:
        data = json.loads(resp.read().decode("utf-8"))
    # Filter results for Karnataka, India and city/administrative types
    candidates = []
    for item in data:
        addr = item.get("address", {})
        state = addr.get("state") or addr.get("state_district")
        country = addr.get("country")
        class_ = item.get("class")
        type_ = item.get("type")
        if country != "India":
            continue
        if state and "Karnataka" not in state:
            continue
        # Prefer city or boundary results
        rank = 0
        if class_ == "boundary" or type_ in {"administrative"}:
            rank = 2
        if class_ == "place" and type_ in {"city", "town"}:
            rank = max(rank, 1)
        candidates.append((rank, item))

    if not candidates and data:
        candidates = [(0, data[0])]

    if not candidates:
        raise RuntimeError("No Nominatim results for Bengaluru/Bangalore")

    candidates.sort(key=lambda x: x[0], reverse=True)
    best = candidates[0][1]
    geojson = {
        "type": "FeatureCollection",
        "features": [
            {
                "type": "Feature",
                "properties": {
                    "display_name": best.get("display_name"),
                    "osm_type": best.get("osm_type"),
                    "osm_id": best.get("osm_id"),
                    "class": best.get("class"),
                    "type": best.get("type"),
                },
                "geometry": best.get("geojson"),
            }
        ],
    }
    return geojson


def main() -> int:
    os.makedirs(RAW_DIR, exist_ok=True)
    queries = [
        "Bengaluru, Karnataka, India",
        "Bangalore, Karnataka, India",
        "Bruhat Bengaluru Mahanagara Palike, Karnataka, India",
    ]
    last_err = None
    for q in queries:
        try:
            gj = fetch_nominatim_boundary(q)
            with open(OUT_PATH, "w", encoding="utf-8") as f:
                json.dump(gj, f)
            print(f"Saved boundary to {OUT_PATH}")
            return 0
        except Exception as exc:  # pragma: no cover
            last_err = exc
            continue
    print(f"Failed to fetch boundary via Nominatim: {last_err}", file=sys.stderr)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())

