import Foundation
import Observation
import ServiceManagement

/// Wraps SMAppService for the launch-at-login toggle.
@Observable
@MainActor
final class LoginItemService {
  private(set) var isEnabled: Bool
  private(set) var lastError: String?

  init() {
    isEnabled = SMAppService.mainApp.status == .enabled
  }

  func setEnabled(_ enabled: Bool) {
    lastError = nil
    do {
      if enabled {
        try SMAppService.mainApp.register()
      } else {
        try SMAppService.mainApp.unregister()
      }
      isEnabled = SMAppService.mainApp.status == .enabled
    } catch {
      // Running from a bare binary (swift run) has no bundle to register.
      lastError = error.localizedDescription
      isEnabled = SMAppService.mainApp.status == .enabled
    }
  }
}
