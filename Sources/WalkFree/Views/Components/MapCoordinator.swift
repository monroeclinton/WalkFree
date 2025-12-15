import CoreLocation
import Foundation
import MapKit

final class MapCoordinator: NSObject, MKMapViewDelegate {
  weak var mapView: MKMapView?
  var streets: [Street] = []
  var lastSelectedStreetId: String?
  var selectedStreetAnnotation: MKPointAnnotation?

  func updateSelectedStreet(
    _ street: Street?,
    userLocation: CLLocation?,
    in mapView: MKMapView
  ) {
    self.mapView = mapView

    if let street = street, street.id != lastSelectedStreetId {
      handleStreetSelection(street, userLocation: userLocation, in: mapView)
    } else if street == nil && lastSelectedStreetId != nil {
      handleStreetDeselection(in: mapView)
    }
  }

  func updateOverlays(for streets: [Street], in mapView: MKMapView) {
    self.streets = streets

    mapView.removeOverlays(mapView.overlays)

    DispatchQueue.main.async {
      let overlays = MapOverlayManager.createOverlays(for: streets)
      mapView.addOverlays(overlays)
    }
  }

  func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
    return MapOverlayManager.createRenderer(for: overlay)
  }

  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    return MapAnnotationManager.createAnnotationView(for: annotation, in: mapView)
  }

  func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
  }

  private func handleStreetSelection(
    _ street: Street,
    userLocation: CLLocation?,
    in mapView: MKMapView
  ) {
    lastSelectedStreetId = street.id

    let pinCoordinate = MapAnnotationManager.findClosestCoordinate(
      in: street,
      to: userLocation
    )

    let annotation = MapAnnotationManager.createAnnotation(
      for: street,
      at: pinCoordinate
    )

    removeSelectedStreetPin(in: mapView)
    selectedStreetAnnotation = annotation
    mapView.addAnnotation(annotation)

    if let region = MapRegionManager.regionForStreet(street, centerCoordinate: pinCoordinate) {
      mapView.setRegion(region, animated: true)
    }
  }

  private func handleStreetDeselection(in mapView: MKMapView) {
    removeSelectedStreetPin(in: mapView)
    lastSelectedStreetId = nil
  }

  private func removeSelectedStreetPin(in mapView: MKMapView) {
    if let annotation = selectedStreetAnnotation {
      mapView.removeAnnotation(annotation)
      selectedStreetAnnotation = nil
    }
  }
}
