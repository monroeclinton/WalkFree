import Foundation

protocol CompletionServiceProtocol: Sendable {
  func getSegmentCompletionState(for segmentId: String) -> (isCompleted: Bool, completedDate: Date?)
  func setSegmentCompletionState(for segmentId: String, isCompleted: Bool, completedDate: Date?)
  func loadCompletionStates(for streets: [Street]) -> [Street]
}

final class CompletionService: @unchecked Sendable, CompletionServiceProtocol {
  static let shared = CompletionService()

  private let userDefaults: UserDefaults
  private let completionKey = "WalkFree.SegmentCompletions"
  private let completionDateKey = "WalkFree.SegmentCompletionDates"

  private init(userDefaults: UserDefaults = .standard) {
    self.userDefaults = userDefaults
  }

  nonisolated func getSegmentCompletionState(for segmentId: String) -> (
    isCompleted: Bool, completedDate: Date?
  ) {
    let completions = userDefaults.dictionary(forKey: completionKey) as? [String: Bool] ?? [:]
    let dates = userDefaults.dictionary(forKey: completionDateKey) as? [String: TimeInterval] ?? [:]

    let isCompleted = completions[segmentId] ?? false
    let date: Date?
    if let timeInterval = dates[segmentId] {
      date = Date(timeIntervalSince1970: timeInterval)
    } else {
      date = nil
    }

    return (isCompleted, date)
  }

  nonisolated func setSegmentCompletionState(
    for segmentId: String, isCompleted: Bool, completedDate: Date?
  ) {
    var completions = userDefaults.dictionary(forKey: completionKey) as? [String: Bool] ?? [:]
    var dates = userDefaults.dictionary(forKey: completionDateKey) as? [String: TimeInterval] ?? [:]

    if isCompleted {
      completions[segmentId] = true
      if let date = completedDate {
        dates[segmentId] = date.timeIntervalSince1970
      }
    } else {
      completions.removeValue(forKey: segmentId)
      dates.removeValue(forKey: segmentId)
    }

    userDefaults.set(completions, forKey: completionKey)
    userDefaults.set(dates, forKey: completionDateKey)
  }

  nonisolated func loadCompletionStates(for streets: [Street]) -> [Street] {
    let completions = userDefaults.dictionary(forKey: completionKey) as? [String: Bool] ?? [:]
    let dates = userDefaults.dictionary(forKey: completionDateKey) as? [String: TimeInterval] ?? [:]

    return streets.map { street in
      let updatedSegments = street.segments.map { segment in
        let isCompleted = completions[segment.id] ?? false
        let completedDate: Date?
        if let timeInterval = dates[segment.id] {
          completedDate = Date(timeIntervalSince1970: timeInterval)
        } else {
          completedDate = nil
        }

        var updatedSegment = segment
        updatedSegment.isCompleted = isCompleted
        updatedSegment.completedDate = completedDate
        return updatedSegment
      }

      var updatedStreet = street
      updatedStreet.segments = updatedSegments
      return updatedStreet
    }
  }
}
