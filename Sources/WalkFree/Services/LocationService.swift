import CoreLocation
import Foundation

@MainActor
class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
  private let locationManager = CLLocationManager()

  @Published var location: CLLocation?
  @Published var authorizationStatus: CLAuthorizationStatus
  @Published var authorizationError: AuthorizationError?

  var isContinuousTrackingEnabled: Bool {
    authorizationStatus == .authorizedAlways
  }

  enum AuthorizationError: LocalizedError {
    case denied
    case restricted

    var errorDescription: String? {
      switch self {
      case .denied:
        return "Location access was denied. Enable location access in Settings"
      case .restricted:
        return "Location access is restricted on this device"
      }
    }
  }

  override init() {
    let initialStatus = CLLocationManager().authorizationStatus
    self.authorizationStatus = initialStatus
    super.init()

    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyBest
    locationManager.pausesLocationUpdatesAutomatically = false
    locationManager.activityType = .fitness

    self.authorizationStatus = locationManager.authorizationStatus
  }

  func requestLocationPermission() {
    let currentStatus = locationManager.authorizationStatus
    authorizationStatus = currentStatus

    switch currentStatus {
    case .notDetermined:
      locationManager.requestWhenInUseAuthorization()
    case .authorizedWhenInUse, .authorizedAlways:
      startContinuousLocationUpdates()
    case .denied:
      authorizationError = .denied
    case .restricted:
      authorizationError = .restricted
    @unknown default:
      break
    }
  }

  func requestAlwaysAuthorization() {
    guard locationManager.authorizationStatus == .authorizedWhenInUse else {
      return
    }
    locationManager.requestAlwaysAuthorization()
  }

  func requestOneTimeLocation() {
    guard
      locationManager.authorizationStatus == .authorizedWhenInUse
        || locationManager.authorizationStatus == .authorizedAlways
    else {
      return
    }
    locationManager.requestLocation()
  }

  func startContinuousLocationUpdates() {
    let currentStatus = locationManager.authorizationStatus

    guard currentStatus == .authorizedWhenInUse || currentStatus == .authorizedAlways else {
      return
    }

    if currentStatus == .authorizedAlways {
      locationManager.allowsBackgroundLocationUpdates = true
    } else {
      locationManager.allowsBackgroundLocationUpdates = false
    }

    locationManager.startUpdatingLocation()
  }

  func stopContinuousLocationUpdates() {
    locationManager.stopUpdatingLocation()
    locationManager.allowsBackgroundLocationUpdates = false
  }

  func clearAuthorizationError() {
    authorizationError = nil
  }

  nonisolated func locationManager(
    _ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]
  ) {
    guard let location = locations.last else { return }
    Task { @MainActor in
      self.location = location
    }
  }

  nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    Task { @MainActor in
      print("Location error: \(error.localizedDescription)")
    }
  }

  nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    let status = manager.authorizationStatus
    Task { @MainActor in
      self.authorizationStatus = status

      switch status {
      case .authorizedWhenInUse, .authorizedAlways:
        self.authorizationError = nil

        if status == .authorizedAlways {
          self.locationManager.allowsBackgroundLocationUpdates = true
        } else {
          self.locationManager.allowsBackgroundLocationUpdates = false
        }

        self.startContinuousLocationUpdates()

      case .denied:
        self.authorizationError = .denied
        self.locationManager.allowsBackgroundLocationUpdates = false
        self.stopContinuousLocationUpdates()

      case .restricted:
        self.authorizationError = .restricted
        self.locationManager.allowsBackgroundLocationUpdates = false
        self.stopContinuousLocationUpdates()

      case .notDetermined:
        break

      @unknown default:
        break
      }
    }
  }
}
