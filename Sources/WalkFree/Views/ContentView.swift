import SwiftUI

struct ContentView: View {
  @StateObject private var locationService = LocationService()
  @StateObject private var viewModel: ContentViewModel
  @State private var showPercentageTooltip = false
  @State private var selectedView: ViewType = .list
  @State private var selectedStreet: Street? = nil

  init() {
    let locationService = LocationService()
    _locationService = StateObject(wrappedValue: locationService)
    _viewModel = StateObject(wrappedValue: ContentViewModel(locationService: locationService))
  }

  var body: some View {
    NavigationView {
      mainContent
        // Navigation Bar Configuration
        .toolbar {
          ToolbarItem(placement: .principal) {
            EmptyView()
          }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(true)
        // Sheet Presentations
        .sheet(isPresented: $viewModel.showCitySelection) {
          CitySelectionView(
            selectedCityIndex: $viewModel.selectedCityIndex,
            isPresented: $viewModel.showCitySelection,
            cities: viewModel.cities
          )
        }
        // Lifecycle Handlers
        .onAppear {
          handleAppear()
        }
        .onChange(of: locationService.location) {
          handleLocationChange()
        }
        .onChange(of: selectedView) {
          if selectedView == .list {
            selectedStreet = nil
          }
        }
        // Overlays
        .overlay {
          LoadingOverlay(isLoading: viewModel.isLoading)
        }
    }
  }

  // Main Content

  private var mainContent: some View {
    ZStack {
      contentView
      ViewSwitcherBar(selectedView: $selectedView)
      tooltipDismissOverlay
    }
  }

  @ViewBuilder
  private var contentView: some View {
    if selectedView == .map {
      mapView
    } else {
      listView
    }
  }

  private var mapView: some View {
    MapView(
      streets: viewModel.filteredStreets,
      userLocation: locationService.location,
      selectedStreet: $selectedStreet
    )
    .ignoresSafeArea()
  }

  private var listView: some View {
    ScrollView {
      VStack(spacing: 0) {
        if !locationService.isContinuousTrackingEnabled {
          trackingWarningBanner
        }

        CitySelectorButton(cityName: viewModel.selectedCity.name) {
          viewModel.showCitySelection = true
        }

        ProgressHeaderView(
          completedCount: viewModel.completedCount,
          totalStreets: viewModel.totalStreets,
          showPercentageTooltip: $showPercentageTooltip
        )

        SearchBarView(searchText: $viewModel.searchText)

        if viewModel.hasMultipleCounties {
          CountyPickerView(
            uniqueCounties: viewModel.uniqueCounties,
            selectedCounty: $viewModel.selectedCounty
          )
        }

        TabPickerView(selectedTab: $viewModel.selectedTab)

        streetListContent
      }
    }
  }

  @ViewBuilder
  private var streetListContent: some View {
    if viewModel.selectedTab == 0 {
      StreetListView(
        streets: viewModel.incompleteStreets,
        isCompletedTab: false,
        searchText: viewModel.searchText,
        onToggleCompletion: { street in
          viewModel.toggleStreetCompletion(street)
        },
        onSelectStreet: { street in
          selectedStreet = street
          selectedView = .map
        }
      )
    } else {
      StreetListView(
        streets: viewModel.completedStreets,
        isCompletedTab: true,
        searchText: viewModel.searchText,
        onToggleCompletion: { street in
          viewModel.toggleStreetCompletion(street)
        },
        onSelectStreet: { street in
          selectedStreet = street
          selectedView = .map
        }
      )
    }
  }

  @ViewBuilder
  private var tooltipDismissOverlay: some View {
    if showPercentageTooltip {
      Color.clear
        .contentShape(Rectangle())
        .onTapGesture {
          showPercentageTooltip = false
        }
        .allowsHitTesting(true)
    }
  }

  @ViewBuilder
  private var trackingWarningBanner: some View {
    HStack(spacing: 12) {
      Image(systemName: "exclamationmark.triangle.fill")
        .foregroundColor(.orange)
        .font(.title3)

      VStack(alignment: .leading, spacing: 4) {
        Text("Background tracking not enabled")
          .font(.subheadline)
          .fontWeight(.semibold)
          .foregroundColor(.primary)

        Text(bannerMessage)
          .font(.caption)
          .foregroundColor(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }

      Spacer()

      if locationService.authorizationStatus == .authorizedWhenInUse {
        Button(action: {
          locationService.requestAlwaysAuthorization()
        }) {
          Text("Enable")
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.blue)
            .cornerRadius(8)
        }
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .background(Color(.systemBackground))
    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
  }

  private var bannerMessage: String {
    switch locationService.authorizationStatus {
    case .notDetermined:
      return
        "Grant location access to track streets. Enable \"Always\" permission for background tracking."
    case .authorizedWhenInUse:
      return "Enable \"Always\" location access to track streets when the app is in the background"
    default:
      return "Enable \"Always\" location access to track streets when the app is in the background"
    }
  }

  // Lifecycle Handlers

  private func handleAppear() {
    if viewModel.isLoading {
      Task {
        await viewModel.loadCities()
      }
    }
    locationService.requestLocationPermission()
  }

  private func handleLocationChange() {
    viewModel.checkAndComputeDistances()
    viewModel.checkLocationForStreetCompletion()
  }

}
