import SwiftUI

struct PopoverRootView: View {
  let services: AppServices

  private enum Tab: String, CaseIterable, Identifiable {
    case hacks = "Hacks"
    case settings = "Settings"
    var id: String { rawValue }
  }

  @State private var activeTab: Tab = .hacks

  var body: some View {
    VStack(spacing: 0) {
      header
        .padding(DesignTokens.spaceM)
      Rectangle().fill(DesignTokens.divider).frame(height: 1)
      ScrollView {
        VStack(alignment: .leading, spacing: DesignTokens.spaceL) {
          switch activeTab {
          case .hacks: hacksContent
          case .settings: SettingsView(services: services)
          }
        }
        .padding(DesignTokens.spaceM)
        .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
    .frame(width: DesignTokens.popoverWidth, height: DesignTokens.popoverHeight)
  }

  @ViewBuilder
  private var hacksContent: some View {
    MenuBarAppsSection(
      menuBarApps: services.menuBarApps,
      declutter: services.declutter,
      onActivateItem: { services.closePanel?() }
    )
    DeclutterSection(declutter: services.declutter, settings: services.settings)
    KeepAwakeSection(keepAwake: services.keepAwake)
    BluetoothSection(bluetooth: services.bluetoothGuard, settings: services.settings)
    QuickTogglesSection(toggles: services.quickToggles)
  }

  private var header: some View {
    HStack(spacing: DesignTokens.spaceS) {
      Image(systemName: "bolt.square.fill")
        .font(.system(size: 15, weight: .semibold))
        .foregroundStyle(DesignTokens.accent)
      Text("QuickHacks")
        .font(.qhDisplay)
      Spacer(minLength: 0)
      Picker("", selection: $activeTab) {
        ForEach(Tab.allCases) { tab in
          Image(systemName: tab == .hacks ? "bolt" : "gearshape")
            .tag(tab)
        }
      }
      .labelsHidden()
      .pickerStyle(.segmented)
      .controlSize(.small)
      .frame(width: 88)
      Button {
        NSApp.terminate(nil)
      } label: {
        Image(systemName: "power")
          .font(.system(size: 12, weight: .medium))
          .foregroundStyle(.secondary)
      }
      .buttonStyle(.plain)
      .help("Quit QuickHacks")
    }
  }
}
