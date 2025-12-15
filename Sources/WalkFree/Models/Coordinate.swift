import CoreLocation
import Foundation

struct Coordinate: Sendable {
  let longitude: Double
  let latitude: Double

  var clLocation: CLLocation {
    CLLocation(latitude: latitude, longitude: longitude)
  }

  func distance(to location: CLLocation) -> CLLocationDistance {
    clLocation.distance(from: location)
  }
}
