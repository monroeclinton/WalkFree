import Foundation
import MapKit

struct MapOverlayManager {
  static let overlayLineWidth: CGFloat = 4.0
  static let overlayAlpha: CGFloat = 0.8
  static let overlayColor = UIColor.red

  static func createOverlays(for streets: [Street]) -> [MKOverlay] {
    var overlays: [MKOverlay] = []

    for street in streets {
      for segment in street.segments where segment.isCompleted {
        guard segment.coordinates.count >= 2 else { continue }

        let coordinates = segment.coordinates.map {
          CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
        }

        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        overlays.append(polyline)
      }
    }

    return overlays
  }

  @MainActor
  static func createRenderer(for overlay: MKOverlay) -> MKOverlayRenderer {
    if let polyline = overlay as? MKPolyline {
      let renderer = MKPolylineRenderer(overlay: polyline)
      renderer.strokeColor = overlayColor
      renderer.lineWidth = overlayLineWidth
      renderer.alpha = overlayAlpha
      return renderer
    }
    return MKOverlayRenderer(overlay: overlay)
  }
}
