import Foundation
import Observation

/// A Bluetooth device the user has blocked from staying connected.
struct BlockedDevice: Codable, Equatable, Identifiable {
  let address: String
  let name: String
  var id: String { address }
}

/// UserDefaults-backed app settings. All keys are versioned under "qh.v1.".
@Observable
@MainActor
final class SettingsStore {
  private enum Keys {
    static let blockedDevices = "qh.v1.blockedDevices"
    static let declutterEnabled = "qh.v1.declutterEnabled"
    static let autoCollapseSeconds = "qh.v1.autoCollapseSeconds"
  }

  private let defaults: UserDefaults

  var blockedDevices: [BlockedDevice] {
    didSet { saveBlockedDevices() }
  }

  var declutterEnabled: Bool {
    didSet { defaults.set(declutterEnabled, forKey: Keys.declutterEnabled) }
  }

  /// 0 = auto-collapse off. Otherwise seconds until the menu bar re-collapses.
  var autoCollapseSeconds: Int {
    didSet { defaults.set(autoCollapseSeconds, forKey: Keys.autoCollapseSeconds) }
  }

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    self.blockedDevices = Self.loadBlockedDevices(from: defaults, key: Keys.blockedDevices)
    self.declutterEnabled =
      defaults.object(forKey: Keys.declutterEnabled) as? Bool ?? true
    self.autoCollapseSeconds =
      defaults.object(forKey: Keys.autoCollapseSeconds) as? Int ?? 30
  }

  func isBlocked(address: String) -> Bool {
    blockedDevices.contains { $0.address == address }
  }

  func toggleBlocked(address: String, name: String) {
    if let index = blockedDevices.firstIndex(where: { $0.address == address }) {
      blockedDevices.remove(at: index)
    } else {
      blockedDevices.append(BlockedDevice(address: address, name: name))
    }
  }

  private func saveBlockedDevices() {
    guard let data = try? JSONEncoder().encode(blockedDevices) else { return }
    defaults.set(data, forKey: Keys.blockedDevices)
  }

  private static func loadBlockedDevices(
    from defaults: UserDefaults, key: String
  ) -> [BlockedDevice] {
    guard let data = defaults.data(forKey: key),
      let devices = try? JSONDecoder().decode([BlockedDevice].self, from: data)
    else { return [] }
    return devices
  }
}
