import Foundation

struct City: Identifiable, Sendable {
  let id = UUID()
  let name: String
  var streets: [Street]
  let totalStreets: Int

  init(name: String, streets: [Street], totalStreets: Int? = nil) {
    self.name = name
    self.streets = streets
    self.totalStreets = totalStreets ?? streets.count
  }

  var completedCount: Int {
    streets.filter { $0.isCompleted }.count
  }
}
