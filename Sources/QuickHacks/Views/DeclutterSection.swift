import SwiftUI

struct DeclutterSection: View {
  @Bindable var declutter: MenuBarDeclutterService
  @Bindable var settings: SettingsStore

  var body: some View {
    CollapsibleSection(title: "Menu bar", key: "menuBar") {
      ToggleRow(
        symbol: "menubar.rectangle",
        label: "Declutter menu bar",
        isOn: Binding(
          get: { settings.declutterEnabled },
          set: { declutter.setEnabled($0) }
        )
      )
      if settings.declutterEnabled {
        ActionRow(
          symbol: declutter.isCollapsed ? "chevron.left.2" : "chevron.right.2",
          label: declutter.isCollapsed ? "Show hidden icons" : "Hide icons now"
        ) {
          declutter.toggleCollapse()
        }
        autoCollapsePicker
        if declutter.needsArrangement {
          Text(
            "Can't hide: the ⟋ separator must sit left of the QuickHacks icons. ⌘-drag it there first."
          )
          .font(.qhCaption)
          .foregroundStyle(DesignTokens.dangerText)
          .padding(.horizontal, DesignTokens.spaceS)
        }
        Text("⌘-drag icons to the left of the ⟋ separator to hide them.")
          .font(.qhCaption)
          .foregroundStyle(.secondary)
          .padding(.horizontal, DesignTokens.spaceS)
      }
    }
  }

  private var autoCollapsePicker: some View {
    HStack(spacing: DesignTokens.spaceS) {
      Image(systemName: "timer")
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(.secondary)
        .frame(width: DesignTokens.iconFrame)
      Text("Auto-hide after")
        .font(.qhBody)
      Spacer(minLength: 0)
      Picker("", selection: $settings.autoCollapseSeconds) {
        Text("Off").tag(0)
        Text("15 s").tag(15)
        Text("30 s").tag(30)
        Text("60 s").tag(60)
      }
      .labelsHidden()
      .pickerStyle(.menu)
      .controlSize(.small)
      .frame(width: 70)
    }
    .padding(.horizontal, DesignTokens.spaceS)
    .frame(minHeight: DesignTokens.rowMinHeight)
  }
}
