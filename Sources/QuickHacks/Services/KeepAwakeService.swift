import Foundation
import IOKit.pwr_mgt
import Observation

/// Available Keep Awake durations. `nil` interval means indefinitely.
enum KeepAwakeDuration: String, CaseIterable, Identifiable {
  case fifteenMinutes
  case oneHour
  case fourHours
  case indefinitely

  var id: String { rawValue }

  var interval: TimeInterval? {
    switch self {
    case .fifteenMinutes: return 15 * 60
    case .oneHour: return 60 * 60
    case .fourHours: return 4 * 60 * 60
    case .indefinitely: return nil
    }
  }

  var label: String {
    switch self {
    case .fifteenMinutes: return "15 min"
    case .oneHour: return "1 h"
    case .fourHours: return "4 h"
    case .indefinitely: return "∞"
    }
  }
}

/// Prevents display sleep via an IOPM assertion, with optional auto-expiry.
@Observable
@MainActor
final class KeepAwakeService {
  private(set) var isActive = false
  private(set) var expiresAt: Date?
  private var assertionID: IOPMAssertionID = 0
  private var expiryTask: Task<Void, Never>?

  func start(_ duration: KeepAwakeDuration) {
    stop()
    var id: IOPMAssertionID = 0
    let status = IOPMAssertionCreateWithName(
      kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
      IOPMAssertionLevel(kIOPMAssertionLevelOn),
      "QuickHacks Keep Awake" as CFString,
      &id
    )
    guard status == kIOReturnSuccess else { return }
    assertionID = id
    isActive = true
    scheduleExpiry(duration.interval)
  }

  func stop() {
    expiryTask?.cancel()
    expiryTask = nil
    expiresAt = nil
    guard isActive else { return }
    IOPMAssertionRelease(assertionID)
    assertionID = 0
    isActive = false
  }

  private func scheduleExpiry(_ interval: TimeInterval?) {
    guard let interval else { return }
    expiresAt = Date().addingTimeInterval(interval)
    expiryTask = Task { [weak self] in
      try? await Task.sleep(for: .seconds(interval))
      guard !Task.isCancelled else { return }
      self?.stop()
    }
  }
}
