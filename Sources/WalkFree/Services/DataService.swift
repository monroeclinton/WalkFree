import Foundation

protocol DataServiceProtocol: Sendable {
  func loadCities() async throws -> [City]
  var completionService: CompletionServiceProtocol { get }
}

final class DataService: @unchecked Sendable, DataServiceProtocol {
  static let shared = DataService()

  let completionService: CompletionServiceProtocol = CompletionService.shared

  private let fileName = "nyc"
  private let fileExtension = "json"

  private init() {}

  nonisolated func loadCities() async throws -> [City] {
    guard let url = findResourceURL() else {
      throw DataServiceError.resourceNotFound
    }

    return await Task.detached {
      let streetData = JSONParser.parseStreets(from: url)

      let streets = streetData.map { data in
        return Street(
          id: data.id,
          name: data.name,
          county: data.county,
          segments: data.segments
        )
      }

      let streetsWithCompletion = CompletionService.shared.loadCompletionStates(for: streets)

      return [
        City(
          name: "New York", streets: streetsWithCompletion,
          totalStreets: streetsWithCompletion.count)
      ]
    }.value
  }

  nonisolated private func findResourceURL() -> URL? {
    if let bundleUrl = Bundle.module.url(forResource: fileName, withExtension: fileExtension) {
      return bundleUrl
    }

    if let mainUrl = Bundle.main.url(forResource: fileName, withExtension: fileExtension) {
      return mainUrl
    }

    let filePath =
      "/home/user/Documents/WalkFree/Sources/WalkFree/Resources/\(fileName).\(fileExtension)"
    if FileManager.default.fileExists(atPath: filePath) {
      return URL(fileURLWithPath: filePath)
    }

    return nil
  }
}

enum DataServiceError: Error {
  case resourceNotFound
  case invalidData
  case saveFailed
}
