import SwiftUI

struct QuickTogglesSection: View {
  @Bindable var toggles: QuickToggleService

  var body: some View {
    CollapsibleSection(title: "Quick toggles", key: "quickToggles") {
      ToggleRow(
        symbol: "mic.slash",
        label: "Mute microphone",
        isOn: binding(for: .toggleMicrophoneMute, value: toggles.microphoneMuted)
      )
      error(for: .toggleMicrophoneMute)
      ToggleRow(
        symbol: "eye",
        label: "Show hidden files",
        isOn: binding(for: .toggleHiddenFiles, value: toggles.hiddenFilesShown)
      )
      error(for: .toggleHiddenFiles)
      ToggleRow(
        symbol: "menubar.dock.rectangle",
        label: "Hide desktop icons",
        isOn: binding(for: .toggleDesktopIcons, value: toggles.desktopIconsHidden)
      )
      error(for: .toggleDesktopIcons)
      ToggleRow(
        symbol: "dock.rectangle",
        label: "Auto-hide Dock",
        isOn: binding(for: .toggleDockAutoHide, value: toggles.dockAutoHidden)
      )
      error(for: .toggleDockAutoHide)
      ActionRow(symbol: "externaldrive.badge.minus", label: "Eject all disks") {
        toggles.perform(.ejectAllDisks)
      }
      error(for: .ejectAllDisks)
      ActionRow(
        symbol: "trash", label: "Empty Trash", labelColor: DesignTokens.dangerText
      ) {
        toggles.perform(.emptyTrash)
      }
      error(for: .emptyTrash)
    }
  }

  private func binding(for action: QuickToggleAction, value: Bool) -> Binding<Bool> {
    Binding(
      get: { value },
      set: { _ in toggles.perform(action) }
    )
  }

  @ViewBuilder
  private func error(for action: QuickToggleAction) -> some View {
    if let message = toggles.lastError[action] {
      InlineError(message: message)
    }
  }
}
