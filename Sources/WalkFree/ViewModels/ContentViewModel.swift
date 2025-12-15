import CoreLocation
import Foundation
import SwiftUI

@MainActor
class ContentViewModel: ObservableObject {
  @Published var cities: [City] = []
  @Published var selectedCityIndex: Int = 0 {
    didSet { invalidateFilterCache() }
  }
  @Published var searchText: String = "" {
    didSet { invalidateFilterCache() }
  }
  @Published var selectedCounty: String? = nil {
    didSet { invalidateFilterCache() }
  }
  @Published var selectedTab: Int = 0
  @Published var isLoading: Bool = true
  @Published var showCitySelection: Bool = false

  private let dataService: DataServiceProtocol
  private let locationService: LocationService
  private let completionService: CompletionServiceProtocol

  // Cache for street distances
  private var streetDistances: [String: CLLocationDistance] = [:]
  private var hasComputedDistances: Bool = false

  // Cache for filtered streets
  private var cachedFilteredStreets: [Street] = []
  private var cachedCompletedStreets: [Street] = []
  private var cachedIncompleteStreets: [Street] = []
  private var lastFilterCacheKey: String = ""

  var selectedCity: City {
    guard !cities.isEmpty, selectedCityIndex < cities.count else {
      return City(name: "New York", streets: [], totalStreets: 0)
    }
    return cities[selectedCityIndex]
  }

  var uniqueCounties: [String] {
    let counties = Set(selectedCity.streets.compactMap { $0.county })
    return Array(counties).sorted()
  }

  var hasMultipleCounties: Bool {
    uniqueCounties.count > 1
  }

  var filteredStreets: [Street] {
    let cacheKey = "\(selectedCityIndex)-\(selectedCounty ?? "all")-\(searchText)"

    if cacheKey == lastFilterCacheKey && !cachedFilteredStreets.isEmpty {
      return cachedFilteredStreets
    }

    // Compute distances once for all streets
    let userLocation = locationService.location
    if let userLocation = userLocation, !hasComputedDistances, !selectedCity.streets.isEmpty {
      computeDistances(for: selectedCity.streets, userLocation: userLocation)
    }

    var streets = selectedCity.streets

    if let selectedCounty = selectedCounty {
      streets = streets.filter { $0.county == selectedCounty }
    }

    if !searchText.isEmpty {
      streets = streets.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    if !streetDistances.isEmpty {
      streets = streets.sorted { street1, street2 in
        let distance1 = streetDistances[street1.id] ?? Double.infinity
        let distance2 = streetDistances[street2.id] ?? Double.infinity
        return distance1 < distance2
      }
    }

    cachedFilteredStreets = streets
    cachedCompletedStreets = streets.filter { $0.isCompleted }
    cachedIncompleteStreets = streets.filter { !$0.isCompleted }
    lastFilterCacheKey = cacheKey

    return streets
  }

  var completedStreets: [Street] {
    _ = filteredStreets
    return cachedCompletedStreets
  }

  var incompleteStreets: [Street] {
    _ = filteredStreets
    return cachedIncompleteStreets
  }

  var completedCount: Int {
    completedStreets.count
  }

  var totalStreets: Int {
    filteredStreets.count
  }

  init(
    dataService: DataServiceProtocol = DataService.shared, locationService: LocationService,
    completionService: CompletionServiceProtocol = CompletionService.shared
  ) {
    self.dataService = dataService
    self.locationService = locationService
    self.completionService = completionService
  }

  func loadCities() async {
    isLoading = true
    defer { isLoading = false }

    do {
      cities = try await dataService.loadCities()
      invalidateCaches()
      if let userLocation = locationService.location, !cities.isEmpty, !selectedCity.streets.isEmpty
      {
        computeDistances(for: selectedCity.streets, userLocation: userLocation)
      }
    } catch {
      print("Error loading cities: \(error)")
      cities = [City(name: "New York", streets: [], totalStreets: 0)]
      invalidateCaches()
    }
  }

  func checkAndComputeDistances() {
    if let userLocation = locationService.location, !hasComputedDistances, !cities.isEmpty,
      !selectedCity.streets.isEmpty
    {
      computeDistances(for: selectedCity.streets, userLocation: userLocation)
    }
  }

  func checkLocationForStreetCompletion() {
    guard let userLocation = locationService.location, !cities.isEmpty else { return }

    let distanceThreshold: CLLocationDistance = 20.0

    var hasUpdates = false

    for cityIndex in cities.indices {
      for streetIndex in cities[cityIndex].streets.indices {
        var street = cities[cityIndex].streets[streetIndex]
        var segmentUpdated = false

        for segmentIndex in street.segments.indices {
          let segment = street.segments[segmentIndex]

          if segment.isCompleted {
            continue
          }

          var isOnSegment = false
          for coordinate in segment.coordinates {
            let distance = coordinate.distance(to: userLocation)
            if distance <= distanceThreshold {
              isOnSegment = true
              break
            }
          }

          if isOnSegment {
            let completedDate = Date()

            completionService.setSegmentCompletionState(
              for: segment.id, isCompleted: true, completedDate: completedDate)

            var updatedSegments = street.segments
            updatedSegments[segmentIndex].isCompleted = true
            updatedSegments[segmentIndex].completedDate = completedDate
            street.segments = updatedSegments
            segmentUpdated = true
            hasUpdates = true
          }
        }

        if segmentUpdated {
          var updatedCity = cities[cityIndex]
          var updatedStreets = updatedCity.streets
          updatedStreets[streetIndex] = street
          updatedCity.streets = updatedStreets
          cities[cityIndex] = updatedCity
        }
      }
    }

    if hasUpdates {
      invalidateFilterCache()
      objectWillChange.send()
    }
  }

  func toggleStreetCompletion(_ street: Street) {
    guard !cities.isEmpty, selectedCityIndex < cities.count else { return }

    let shouldComplete = !street.isCompleted
    let completedDate = shouldComplete ? Date() : nil

    for cityIndex in cities.indices {
      if let streetIndex = cities[cityIndex].streets.firstIndex(where: { $0.id == street.id }) {
        var updatedCity = cities[cityIndex]
        var updatedStreets = updatedCity.streets
        var updatedStreet = updatedStreets[streetIndex]

        for segmentIndex in updatedStreet.segments.indices {
          let segment = updatedStreet.segments[segmentIndex]

          completionService.setSegmentCompletionState(
            for: segment.id, isCompleted: shouldComplete, completedDate: completedDate)

          updatedStreet.segments[segmentIndex].isCompleted = shouldComplete
          updatedStreet.segments[segmentIndex].completedDate = completedDate
        }

        updatedStreets[streetIndex] = updatedStreet
        updatedCity.streets = updatedStreets
        cities[cityIndex] = updatedCity
      }
    }

    invalidateFilterCache()

    objectWillChange.send()
  }

  private func computeDistances(for streets: [Street], userLocation: CLLocation) {
    guard !hasComputedDistances else { return }

    for street in streets {
      let distance = distanceFromUser(to: street, userLocation: userLocation)
      streetDistances[street.id] = distance
    }

    hasComputedDistances = true
  }

  private func distanceFromUser(to street: Street, userLocation: CLLocation) -> CLLocationDistance {
    var minDistance = Double.infinity

    for segment in street.segments {
      for coordinate in segment.coordinates {
        let distance = coordinate.distance(to: userLocation)
        if distance < minDistance {
          minDistance = distance
        }
      }
    }

    return minDistance
  }

  private func invalidateCaches() {
    streetDistances.removeAll()
    hasComputedDistances = false
    invalidateFilterCache()
  }

  private func invalidateFilterCache() {
    cachedFilteredStreets.removeAll()
    cachedCompletedStreets.removeAll()
    cachedIncompleteStreets.removeAll()
    lastFilterCacheKey = ""
  }

}
