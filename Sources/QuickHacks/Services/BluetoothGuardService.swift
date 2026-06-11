import Foundation
import IOBluetooth
import Observation

/// Snapshot of a paired device for the UI.
struct BluetoothDeviceInfo: Identifiable, Equatable {
  let address: String
  let name: String
  let isConnected: Bool
  let majorClass: BluetoothDeviceClassMajor
  var id: String { address }

  var symbolName: String {
    switch Int(majorClass) {
    case kBluetoothDeviceClassMajorAudio: return "headphones"
    case kBluetoothDeviceClassMajorPeripheral: return "keyboard"
    case kBluetoothDeviceClassMajorPhone: return "iphone"
    case kBluetoothDeviceClassMajorComputer: return "laptopcomputer"
    default: return "wave.3.right.circle"
    }
  }
}

/// Lists paired devices and enforces the blocklist: a blocked device is
/// disconnected immediately whenever it connects.
@MainActor
final class BluetoothGuardService: NSObject, ObservableObject {
  @Published private(set) var devices: [BluetoothDeviceInfo] = []
  @Published private(set) var lastEnforcement: String?

  private let settings: SettingsStore
  private var connectNotification: IOBluetoothUserNotification?

  init(settings: SettingsStore) {
    self.settings = settings
    super.init()
    connectNotification = IOBluetoothDevice.register(
      forConnectNotifications: self,
      selector: #selector(deviceConnected(_:device:))
    )
    refresh()
  }

  deinit {
    connectNotification?.unregister()
  }

  func refresh() {
    let paired = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] ?? []
    devices = paired.compactMap { device in
      guard let address = device.addressString else { return nil }
      return BluetoothDeviceInfo(
        address: address,
        name: device.name ?? "Unknown device",
        isConnected: device.isConnected(),
        majorClass: device.deviceClassMajor
      )
    }
  }

  func toggleBlocked(_ info: BluetoothDeviceInfo) {
    settings.toggleBlocked(address: info.address, name: info.name)
    if settings.isBlocked(address: info.address), info.isConnected {
      disconnect(info)
    }
  }

  func connect(_ info: BluetoothDeviceInfo) {
    guard let device = IOBluetoothDevice(addressString: info.address) else { return }
    device.openConnection()
    refresh()
  }

  func disconnect(_ info: BluetoothDeviceInfo) {
    guard let device = IOBluetoothDevice(addressString: info.address) else { return }
    device.closeConnection()
    refresh()
  }

  @objc private func deviceConnected(
    _ notification: IOBluetoothUserNotification, device: IOBluetoothDevice
  ) {
    defer { refresh() }
    guard let address = device.addressString,
      settings.isBlocked(address: address)
    else { return }
    // Give the stack a moment to finish the connection before tearing it down.
    Task { [weak self] in
      try? await Task.sleep(for: .milliseconds(300))
      device.closeConnection()
      self?.lastEnforcement = device.name ?? address
      self?.refresh()
      self?.scheduleEnforcementDismiss()
    }
  }

  private func scheduleEnforcementDismiss() {
    Task { [weak self] in
      try? await Task.sleep(for: .seconds(5))
      self?.lastEnforcement = nil
    }
  }
}
