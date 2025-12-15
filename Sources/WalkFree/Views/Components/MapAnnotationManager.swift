import CoreLocation
import Foundation
import MapKit

struct MapAnnotationManager {
  static let selectedStreetIdentifier = "SelectedStreetMarker"

  static func findClosestCoordinate(
    in street: Street,
    to userLocation: CLLocation?
  ) -> CLLocationCoordinate2D {
    let allCoordinates = collectAllCoordinates(from: street)
    guard !allCoordinates.isEmpty else {
      return MapRegionManager.defaultNYCCenter
    }

    guard let userLocation = userLocation else {
      return calculateCenter(from: allCoordinates)
    }

    return findClosestCoordinate(to: userLocation, in: allCoordinates)
  }

  static func createAnnotation(
    for street: Street,
    at coordinate: CLLocationCoordinate2D
  ) -> MKPointAnnotation {
    let annotation = MKPointAnnotation()
    annotation.coordinate = coordinate
    annotation.title = street.name
    annotation.subtitle = street.county
    return annotation
  }

  @MainActor
  static func createAnnotationView(
    for annotation: MKAnnotation,
    in mapView: MKMapView
  ) -> MKAnnotationView? {
    if annotation is MKUserLocation {
      return nil
    }

    var annotationView = mapView.dequeueReusableAnnotationView(
      withIdentifier: selectedStreetIdentifier)

    if annotationView == nil {
      annotationView = MKMarkerAnnotationView(
        annotation: annotation, reuseIdentifier: selectedStreetIdentifier)
      annotationView?.canShowCallout = true
    } else {
      annotationView?.annotation = annotation
    }

    if let markerView = annotationView as? MKMarkerAnnotationView {
      markerView.markerTintColor = .systemBlue
      markerView.glyphImage = nil
      markerView.animatesWhenAdded = true
    }

    return annotationView
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

  private static func findClosestCoordinate(
    to userLocation: CLLocation,
    in coordinates: [CLLocationCoordinate2D]
  ) -> CLLocationCoordinate2D {
    var minDistance = Double.infinity
    var closestCoordinate = coordinates[0]

    for coord in coordinates {
      let location = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
      let distance = location.distance(from: userLocation)
      if distance < minDistance {
        minDistance = distance
        closestCoordinate = coord
      }
    }

    return closestCoordinate
  }

  private static func calculateCenter(from coordinates: [CLLocationCoordinate2D])
    -> CLLocationCoordinate2D
  {
    let latitudes = coordinates.map { $0.latitude }
    let longitudes = coordinates.map { $0.longitude }

    return CLLocationCoordinate2D(
      latitude: (latitudes.min()! + latitudes.max()!) / 2,
      longitude: (longitudes.min()! + longitudes.max()!) / 2
    )
  }
}
