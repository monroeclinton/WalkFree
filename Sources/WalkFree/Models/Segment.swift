import CoreLocation
import Foundation

struct Segment: Sendable {
  let id: String
  let coordinates: [Coordinate]
  var isCompleted: Bool
  var completedDate: Date?

  init(
    id: String, coordinates: [Coordinate] = [], isCompleted: Bool = false,
    completedDate: Date? = nil
  ) {
    self.id = id
    self.coordinates = coordinates
    self.isCompleted = isCompleted
    self.completedDate = completedDate
  }
}
