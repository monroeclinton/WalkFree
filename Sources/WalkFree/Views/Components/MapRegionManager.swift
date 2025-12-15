import CoreLocation
import Foundation
import MapKit

struct MapRegionManager {
  static let defaultNYCCenter = CLLocationCoordinate2D(latitude: 40.7128, longitude: -73.9352)
  static let defaultNYCRadius: CLLocationDistance = 10000
  static let userLocationRadius: CLLocationDistance = 1000
  static let zoomPaddingMultiplier: Double = 1.1
  static let minSpanDelta: Double = 0.01

  static func initialRegion(userLocation: CLLocation?) -> MKCoordinateRegion {
    if let userLocation = userLocation {
      return MKCoordinateRegion(
        center: userLocation.coordinate,
        latitudinalMeters: userLocationRadius,
        longitudinalMeters: userLocationRadius
      )
    } else {
      return MKCoordinateRegion(
        center: defaultNYCCenter,
        latitudinalMeters: defaultNYCRadius,
        longitudinalMeters: defaultNYCRadius
      )
    }
  }

  static func regionForStreet(
    _ street: Street,
    centerCoordinate: CLLocationCoordinate2D
  ) -> MKCoordinateRegion? {
    let allCoordinates = collectAllCoordinates(from: street)
    guard !allCoordinates.isEmpty else { return nil }

    let boundingBox = calculateBoundingBox(from: allCoordinates)
    let latDelta = max(boundingBox.latDelta, minSpanDelta) * zoomPaddingMultiplier
    let lonDelta = max(boundingBox.lonDelta, minSpanDelta) * zoomPaddingMultiplier

    return MKCoordinateRegion(
      center: centerCoordinate,
      span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
    )
  }

  private static func collectAllCoordinates(from street: Street) -> [CLLocationCoordinate2D] {
    var allCoordinates: [CLLocationCoordinate2D] = []
    for segment in street.segments {
      let segmentCoords = segment.coordinates.map {
        CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
      }
      allCoordinates.append(contentsOf: segmentCoords)
    }
    return allCoordinates
  }

  private static func calculateBoundingBox(from coordinates: [CLLocationCoordinate2D]) -> (
    latDelta: Double, lonDelta: Double
  ) {
    let latitudes = coordinates.map { $0.latitude }
    let longitudes = coordinates.map { $0.longitude }

    let minLat = latitudes.min()!
    let maxLat = latitudes.max()!
    let minLon = longitudes.min()!
    let maxLon = longitudes.max()!

    return (
      latDelta: maxLat - minLat,
      lonDelta: maxLon - minLon
    )
  }
}
