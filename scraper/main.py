import argparse
import json
from pathlib import Path
from typing import Any

import requests

DEFAULT_OVERPASS_ENDPOINT = "https://overpass-api.de/api/interpreter"
DEFAULT_QUERY_TIMEOUT = 300
DEFAULT_OUTPUT_DIR = "export"
OUTPUT_FILENAME = "nyc_streets.geojson"


NYC_STREETS_QUERY = """[out:json];

// NYC administrative boundary
relation(175905);
map_to_area -> .nycArea;

// Only streets that have a name
way
  ["highway"]
  ["name"]
  (area.nycArea);

// Output only tags (includes name)
out geom;"""


def run_overpass_query(
    query: str, endpoint: str = DEFAULT_OVERPASS_ENDPOINT, timeout: int = DEFAULT_QUERY_TIMEOUT
) -> dict[str, Any]:
    """
    Args:
        query: The Overpass QL query string
        endpoint: The Overpass API endpoint URL
        timeout: Request timeout in seconds

    Returns:
        The JSON response from the Overpass API

    Raises:
        requests.RequestException: If the request fails
    """
    print("Running Overpass query")
    response = requests.post(
        endpoint, data=query, headers={"Content-Type": "text/plain"}, timeout=timeout
    )
    response.raise_for_status()
    return response.json()


def osm_to_geojson(osm_data: dict[str, Any]) -> dict[str, Any]:
    """
    Args:
        osm_data: OSM JSON data from Overpass API

    Returns:
        GeoJSON FeatureCollection with street features
    """
    features = []

    elements = osm_data.get("elements", [])
    for element in elements:
        if element.get("type") != "way" or "geometry" not in element:
            continue

        properties = element.get("tags", {}).copy()

        if "id" in element:
            properties["@id"] = f"way/{element['id']}"

        geometry_coords = element.get("geometry", [])
        coordinates = [[coord["lon"], coord["lat"]] for coord in geometry_coords]

        feature = {
            "type": "Feature",
            "properties": properties,
            "geometry": {"type": "LineString", "coordinates": coordinates},
        }
        features.append(feature)

    return {"type": "FeatureCollection", "features": features}


def export_nyc_streets(output_dir: str = DEFAULT_OUTPUT_DIR) -> Path:
    """
    Args:
        output_dir: Directory to save the exported GeoJSON file

    Returns:
        Path to the exported GeoJSON file

    Raises:
        requests.RequestException: If the Overpass API request fails
        OSError: If the file cannot be written
    """
    export_path = Path(output_dir)
    export_path.mkdir(parents=True, exist_ok=True)

    osm_data = run_overpass_query(NYC_STREETS_QUERY)
    num_elements = len(osm_data.get("elements", []))
    print(f"Query returned {num_elements} elements")

    geojson_data = osm_to_geojson(osm_data)
    num_features = len(geojson_data["features"])

    output_file = export_path / OUTPUT_FILENAME
    with open(output_file, "w", encoding="utf-8") as f:
        json.dump(geojson_data, f, indent=2, ensure_ascii=False)

    print(f"Exported {num_features} features to {output_file}")
    return output_file


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Scrape street data from Overpass API",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "--output",
        "-o",
        default=DEFAULT_OUTPUT_DIR,
        help=f"Output directory for exported GeoJSON (default: {DEFAULT_OUTPUT_DIR})",
    )

    args = parser.parse_args()

    try:
        print("Starting streets export...")
        export_nyc_streets(args.output)
        print("Export complete!")
    except requests.RequestException as e:
        print(f"Error: Failed to fetch data from Overpass API: {e}")
        raise SystemExit(1)
    except OSError as e:
        print(f"Error: Failed to write output file: {e}")
        raise SystemExit(1)
    except Exception as e:
        print(f"Error: Unexpected error occurred: {e}")
        raise SystemExit(1)


if __name__ == "__main__":
    main()
