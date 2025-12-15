import CoreLocation
import Foundation

struct Street: Identifiable, Sendable {
  let id: String
  let name: String
  let county: String?
  var segments: [Segment]

  var isCompleted: Bool {
    !segments.isEmpty && segments.allSatisfy { $0.isCompleted }
  }

  var completedDate: Date? {
    let dates = segments.compactMap { $0.completedDate }
    return dates.max()
  }

  var completionProgress: Double {
    guard !segments.isEmpty else { return 0.0 }
    let completedCount = segments.filter { $0.isCompleted }.count
    return Double(completedCount) / Double(segments.count)
  }

  var isPartiallyCompleted: Bool {
    !isCompleted && completionProgress > 0
  }

  init(id: String, name: String, county: String? = nil, segments: [Segment] = []) {
    self.id = id
    self.name = name
    self.county = county
    self.segments = segments
  }
}
