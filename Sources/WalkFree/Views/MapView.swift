import MapKit
import SwiftUI

struct MapView: UIViewRepresentable {

  let streets: [Street]
  let userLocation: CLLocation?
  @Binding var selectedStreet: Street?

  func makeCoordinator() -> MapCoordinator {
    MapCoordinator()
  }

  func makeUIView(context: Context) -> MKMapView {
    let mapView = MKMapView()
    mapView.delegate = context.coordinator
    mapView.showsUserLocation = true
    mapView.userTrackingMode = .none
    mapView.pointOfInterestFilter = MKPointOfInterestFilter(including: [])

    let initialRegion = MapRegionManager.initialRegion(userLocation: userLocation)
    mapView.setRegion(initialRegion, animated: false)

    context.coordinator.updateOverlays(for: streets, in: mapView)

    return mapView
  }

  func updateUIView(_ mapView: MKMapView, context: Context) {
    let streetIds = Set(streets.map { $0.id })
    let currentStreetIds = Set(context.coordinator.streets.map { $0.id })

    if streetIds != currentStreetIds {
      context.coordinator.updateOverlays(for: streets, in: mapView)
    }

    context.coordinator.updateSelectedStreet(
      selectedStreet,
      userLocation: userLocation,
      in: mapView
    )
  }
}
