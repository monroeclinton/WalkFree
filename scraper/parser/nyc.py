import hashlib
import json
import math
from pathlib import Path
from typing import Any

COUNTY_MAP = {
    "relation/2552485": "Manhattan",  # New York County
    "relation/369519": "Queens",  # Queens County
    "relation/369518": "Brooklyn",  # Kings County
    "relation/2552450": "The Bronx",  # Bronx County
    "relation/962876": "Staten Island",  # Richmond County
}


EARTH_RADIUS_METERS = 6371000
DEFAULT_MAX_DISTANCE_METERS = 750.0
DEFAULT_CITY = "New York"
DEFAULT_STATE = "NY"
DEFAULT_COUNTRY = "US"


def load_county_boundaries(areas_path: str = "areas/nyc.geojson") -> list[dict[str, Any]]:
    """
    Args:
        areas_path: Path to the areas GeoJSON file

    Returns:
        List of county boundary dictionaries with geometry and name

    Raises:
        FileNotFoundError: If the areas GeoJSON file cannot be found
        json.JSONDecodeError: If the file is not valid JSON
    """
    areas_file = Path(areas_path)
    if not areas_file.exists():
        # Try relative to scraper directory
        areas_file = Path(__file__).parent.parent / areas_path
        if not areas_file.exists():
            raise FileNotFoundError(f"Areas GeoJSON file not found: {areas_path}")

    with open(areas_file, encoding="utf-8") as f:
        geojson_data = json.load(f)

    boundaries = []

    if geojson_data.get("type") == "FeatureCollection":
        for feature in geojson_data.get("features", []):
            if feature.get("type") == "Feature":
                properties = feature.get("properties", {})
                geometry = feature.get("geometry", {})
                feature_id = properties.get("@id", "")

                # Only process county boundaries
                if feature_id in COUNTY_MAP:
                    county_name = COUNTY_MAP[feature_id]
                    boundaries.append({"name": county_name, "id": feature_id, "geometry": geometry})

    return boundaries


_county_boundaries_cache: list[dict[str, Any]] | None = None


def get_cached_county_boundaries() -> list[dict[str, Any]]:
    global _county_boundaries_cache
    if _county_boundaries_cache is None:
        _county_boundaries_cache = load_county_boundaries()
    return _county_boundaries_cache


def point_in_polygon(point: tuple[float, float], polygon: list[list[float]]) -> bool:
    """
    Args:
        point: Tuple of (longitude, latitude)
        polygon: List of coordinate pairs [[lon, lat], ...]

    Returns:
        True if point is inside polygon, False otherwise
    """
    if not polygon:
        return False

    x, y = point
    n = len(polygon)
    inside = False

    p1x, p1y = polygon[0]
    for i in range(1, n + 1):
        p2x, p2y = polygon[i % n]
        if y > min(p1y, p2y):
            if y <= max(p1y, p2y):
                if x <= max(p1x, p2x):
                    if p1y != p2y:
                        xinters = (y - p1y) * (p2x - p1x) / (p2y - p1y) + p1x
                    if p1x == p2x or x <= xinters:
                        inside = not inside
        p1x, p1y = p2x, p2y

    return inside


def point_in_multipolygon(
    point: tuple[float, float], multipolygon: list[list[list[list[float]]]]
) -> bool:
    """
    Args:
        point: Tuple of (longitude, latitude)
        multipolygon: MultiPolygon coordinates structure

    Returns:
        True if point is inside any polygon in the MultiPolygon
    """
    for polygon in multipolygon:
        # Each polygon is a list of rings, first ring is outer boundary
        if polygon and len(polygon) > 0:
            outer_ring = polygon[0]
            if point_in_polygon(point, outer_ring):
                # Check if point is in any holes (inner rings)
                in_hole = False
                for inner_ring in polygon[1:]:
                    if point_in_polygon(point, inner_ring):
                        in_hole = True
                        break
                if not in_hole:
                    return True
    return False


def haversine_distance(coord1: list[float], coord2: list[float]) -> float:
    """
    Args:
        coord1: [longitude, latitude] of first point
        coord2: [longitude, latitude] of second point

    Returns:
        Distance in meters. Returns infinity if coordinates are invalid
    """
    if len(coord1) < 2 or len(coord2) < 2:
        return float("inf")

    lon1, lat1 = math.radians(coord1[0]), math.radians(coord1[1])
    lon2, lat2 = math.radians(coord2[0]), math.radians(coord2[1])

    dlon = lon2 - lon1
    dlat = lat2 - lat1

    a = math.sin(dlat / 2) ** 2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon / 2) ** 2
    c = 2 * math.asin(math.sqrt(a))

    return c * EARTH_RADIUS_METERS


def min_distance_between_segments(seg1: list[list[float]], seg2: list[list[float]]) -> float:
    """
    Calculate the minimum distance between two line segments.

    Args:
        seg1: First segment as list of [lon, lat] coordinates
        seg2: Second segment as list of [lon, lat] coordinates

    Returns:
        Minimum distance in meters
    """
    min_dist = float("inf")

    # Check distance between all point pairs
    for p1 in seg1:
        for p2 in seg2:
            dist = haversine_distance(p1, p2)
            if dist < min_dist:
                min_dist = dist

    return min_dist


def group_segments_by_proximity(
    segments: list[dict[str, Any]], max_distance: float = DEFAULT_MAX_DISTANCE_METERS
) -> list[list[dict[str, Any]]]:
    """
    Args:
        segments: List of street segment dictionaries
        max_distance: Maximum distance in meters to consider segments as connected (default: 750)

    Returns:
        List of groups, where each group is a list of segment dictionaries
    """
    if not segments:
        return []

    if len(segments) == 1:
        return [segments]

    # Build a graph of which segments are connected (within max_distance)
    # Use union-find approach, each segment initially points to itself
    parent = list(range(len(segments)))

    def find(x: int) -> int:
        if parent[x] != x:
            parent[x] = find(parent[x])  # Path shrink
        return parent[x]

    def union(x: int, y: int):
        root_x = find(x)
        root_y = find(y)
        if root_x != root_y:
            parent[root_y] = root_x

    # Check all pairs of segments and union them if within max_distance
    for i in range(len(segments)):
        for j in range(i + 1, len(segments)):
            seg1_coords = segments[i].get("coordinates", [])
            seg2_coords = segments[j].get("coordinates", [])

            if not seg1_coords or not seg2_coords:
                continue

            min_dist = min_distance_between_segments(seg1_coords, seg2_coords)

            if min_dist <= max_distance:
                union(i, j)

    groups_dict: dict[int, list[int]] = {}
    for i in range(len(segments)):
        root = find(i)
        if root not in groups_dict:
            groups_dict[root] = []
        groups_dict[root].append(i)

    result = []
    for group_indices in groups_dict.values():
        result.append([segments[idx] for idx in group_indices])

    return result


def get_county(coordinate: list[float]) -> str | None:
    """
    Args:
        coordinate: List of [longitude, latitude]

    Returns:
        County name (Manhattan, Queens, Brooklyn, The Bronx, or Staten Island),
        or None if coordinate is not in any county
    """
    if len(coordinate) < 2:
        return None

    lon, lat = coordinate[0], coordinate[1]
    point = (lon, lat)

    try:
        boundaries = get_cached_county_boundaries()

        for boundary in boundaries:
            geometry = boundary["geometry"]
            geom_type = geometry.get("type")
            coords = geometry.get("coordinates", [])

            if geom_type == "Polygon":
                if coords and len(coords) > 0:
                    outer_ring = coords[0]
                    if point_in_polygon(point, outer_ring):
                        # Check if point is in any holes
                        in_hole = False
                        for inner_ring in coords[1:]:
                            if point_in_polygon(point, inner_ring):
                                in_hole = True
                                break
                        if not in_hole:
                            return boundary["name"]

            elif geom_type == "MultiPolygon":
                if point_in_multipolygon(point, coords):
                    return boundary["name"]

        return None
    except Exception as e:
        print(f"Error determining county: {e}")
        return None


def parse_nyc_streets(geojson_path: str) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    """
    Args:
        geojson_path: Path to the GeoJSON file

    Returns:
        Tuple of (grouped_streets, skipped_features) where:
        - grouped_streets: List of grouped street dictionaries with segments
        - skipped_features: List of features that were skipped during parsing

    Raises:
        FileNotFoundError: If the GeoJSON file cannot be found
        json.JSONDecodeError: If the file is not valid JSON
    """
    geojson_file = Path(geojson_path)

    if not geojson_file.exists():
        raise FileNotFoundError(f"GeoJSON file not found: {geojson_path}")

    with open(geojson_file, encoding="utf-8") as f:
        geojson_data = json.load(f)

    streets = []
    skipped = []

    if geojson_data.get("type") == "FeatureCollection":
        for feature in geojson_data.get("features", []):
            if feature.get("type") == "Feature":
                properties = feature.get("properties", {})
                geometry = feature.get("geometry", {})

                name = properties.get("name", "")
                street_id = properties.get("@id", "")

                if not name or not street_id:
                    skipped.append(feature)
                    continue

                coordinates = []
                if geometry.get("type") == "LineString":
                    coordinates = geometry.get("coordinates", [])
                elif geometry.get("type") == "Polygon":
                    coords = geometry.get("coordinates", [])
                    if coords:
                        coordinates = coords[0]

                if not coordinates:
                    skipped.append(feature)
                    continue

                county = None
                for coordinate in coordinates:
                    county = get_county(coordinate)
                    if county:
                        break

                street_data = {
                    "@id": street_id,
                    "name": name,
                    "county": county,
                    "city": DEFAULT_CITY,
                    "state": DEFAULT_STATE,
                    "country": DEFAULT_COUNTRY,
                    "coordinates": coordinates,
                }

                streets.append(street_data)

    grouped_streets = group_streets_by_name_and_proximity(streets)

    return grouped_streets, skipped


def group_streets_by_name_and_proximity(
    streets: list[dict[str, Any]], max_distance: float = DEFAULT_MAX_DISTANCE_METERS
) -> list[dict[str, Any]]:
    """
    Args:
        streets: List of street dictionaries
        max_distance: Maximum distance in meters to consider segments as connected

    Returns:
        List of grouped street dictionaries with segments array
    """
    streets_by_name: dict[str, list[dict[str, Any]]] = {}
    for street in streets:
        name = street.get("name", "")
        streets_by_name.setdefault(name, []).append(street)

    grouped_streets = []

    for name, name_segments in streets_by_name.items():
        proximity_groups = group_segments_by_proximity(name_segments, max_distance)

        for group in proximity_groups:
            segment_ids = [seg.get("@id") for seg in group if seg.get("@id")]
            segment_ids_sorted = sorted(segment_ids)

            segment_ids_str = "|".join(segment_ids_sorted)
            street_id = hashlib.sha256(segment_ids_str.encode("utf-8")).hexdigest()

            if len(group) == 1:
                street = group[0]
                grouped_streets.append(
                    {
                        "id": street_id,
                        "name": name,
                        "county": street.get("county"),
                        "city": street.get("city", DEFAULT_CITY),
                        "state": street.get("state", DEFAULT_STATE),
                        "country": street.get("country", DEFAULT_COUNTRY),
                        "segments": [
                            {
                                "id": street.get("@id"),
                                "coordinates": street.get("coordinates", []),
                            }
                        ],
                    }
                )
            else:
                first_segment = group[0]

                segments = [
                    {"id": seg.get("@id"), "coordinates": seg.get("coordinates", [])}
                    for seg in group
                ]

                grouped_streets.append(
                    {
                        "id": street_id,
                        "name": name,
                        "county": first_segment.get("county"),
                        "city": first_segment.get("city", DEFAULT_CITY),
                        "state": first_segment.get("state", DEFAULT_STATE),
                        "country": first_segment.get("country", DEFAULT_COUNTRY),
                        "segments": segments,
                    }
                )

    return grouped_streets


def export_parsed_streets(
    streets: list[dict[str, Any]], output_path: str = "export/nyc_streets_parsed.json"
):
    """
    Args:
        streets: List of street dictionaries
        output_path: Path to save the output JSON file
    """
    output_file = Path(output_path)
    output_file.parent.mkdir(parents=True, exist_ok=True)

    with open(output_file, "w", encoding="utf-8") as f:
        json.dump(streets, f, indent=2, ensure_ascii=False)

    print(f"Exported {len(streets)} streets to {output_path}")


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Parse NYC streets GeoJSON file")
    parser.add_argument(
        "--input",
        "-i",
        default="export/nyc_streets.geojson",
        help="Input GeoJSON file path (default: export/nyc_streets.geojson)",
    )
    parser.add_argument(
        "--output",
        "-o",
        default="export/nyc_streets_parsed.json",
        help="Output JSON file path (default: export/nyc_streets_parsed.json)",
    )

    args = parser.parse_args()

    print(f"Parsing NYC streets from {args.input}...")
    streets, skipped = parse_nyc_streets(args.input)
    print(f"Parsed {len(streets)} streets")
    print(f"Skipped {len(skipped)} streets")

    export_parsed_streets(streets, args.output)
    print("Parsing complete!")


if __name__ == "__main__":
    main()
