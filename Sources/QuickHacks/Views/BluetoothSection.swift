import SwiftUI

struct BluetoothSection: View {
  @ObservedObject var bluetooth: BluetoothGuardService
  var settings: SettingsStore

  @State private var showAll = false

  private static let compactCount = 4

  var body: some View {
    CollapsibleSection(title: "Bluetooth guard", key: "bluetooth") {
      if bluetooth.devices.isEmpty {
        Text("No paired devices")
          .font(.qhCaption)
          .foregroundStyle(.secondary)
          .padding(.horizontal, DesignTokens.spaceS)
      }
      ForEach(visibleDevices) { device in
        DeviceRow(
          device: device,
          isBlocked: settings.isBlocked(address: device.address),
          bluetooth: bluetooth
        )
      }
      if sortedDevices.count > Self.compactCount {
        Button(showAll ? "Show fewer" : "Show all (\(sortedDevices.count))") {
          withAnimation(DesignTokens.spring) { showAll.toggle() }
        }
        .buttonStyle(.plain)
        .font(.qhCaption)
        .foregroundStyle(DesignTokens.accent)
        .padding(.horizontal, DesignTokens.spaceS)
      }
      if let name = bluetooth.lastEnforcement {
        Text("Blocked \(name) from connecting")
          .font(.qhCaption)
          .foregroundStyle(DesignTokens.accent)
          .padding(.horizontal, DesignTokens.spaceS)
          .transition(.opacity)
      }
    }
    .onAppear { bluetooth.refresh() }
  }

  /// Connected and blocked devices first, then the rest alphabetically.
  private var sortedDevices: [BluetoothDeviceInfo] {
    bluetooth.devices.sorted { a, b in
      let aRank = rank(a)
      let bRank = rank(b)
      if aRank != bRank { return aRank < bRank }
      return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
    }
  }

  private var visibleDevices: [BluetoothDeviceInfo] {
    showAll ? sortedDevices : Array(sortedDevices.prefix(Self.compactCount))
  }

  private func rank(_ device: BluetoothDeviceInfo) -> Int {
    if device.isConnected { return 0 }
    if settings.isBlocked(address: device.address) { return 1 }
    return 2
  }
}

private struct DeviceRow: View {
  let device: BluetoothDeviceInfo
  let isBlocked: Bool
  let bluetooth: BluetoothGuardService

  @State private var isHovered = false

  var body: some View {
    HStack(spacing: DesignTokens.spaceS) {
      Image(systemName: device.symbolName)
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(device.isConnected ? Color.green : Color.secondary)
        .frame(width: DesignTokens.iconFrame)
      VStack(alignment: .leading, spacing: 1) {
        Text(device.name)
          .font(.qhBody)
          .lineLimit(1)
        Text(stateCaption)
          .font(.qhCaption)
          .foregroundStyle(isBlocked ? DesignTokens.accent : .secondary)
      }
      Spacer(minLength: 0)
      if isHovered, !isBlocked {
        Button(device.isConnected ? "Disconnect" : "Connect") {
          device.isConnected ? bluetooth.disconnect(device) : bluetooth.connect(device)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
      }
      Button {
        bluetooth.toggleBlocked(device)
      } label: {
        Image(systemName: "nosign")
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(isBlocked ? DesignTokens.accent : .secondary)
      }
      .buttonStyle(.plain)
      .help(isBlocked ? "Allow this device" : "Block this device")
    }
    .padding(.horizontal, DesignTokens.spaceS)
    .frame(minHeight: DesignTokens.rowMinHeight + DesignTokens.spaceXS)
    .background(
      RoundedRectangle(cornerRadius: DesignTokens.radiusChip, style: .continuous)
        .fill(isHovered ? DesignTokens.accentSoft : .clear)
    )
    .onHover { isHovered = $0 }
  }

  private var stateCaption: String {
    if isBlocked { return "Blocked" }
    return device.isConnected ? "Connected" : "Not connected"
  }
}
