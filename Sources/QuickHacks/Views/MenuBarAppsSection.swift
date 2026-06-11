import SwiftUI

/// Lists third-party menu bar apps; clicking a chip opens that app's
/// menu bar item directly from the panel.
struct MenuBarAppsSection: View {
  @Bindable var menuBarApps: MenuBarAppsService
  let declutter: MenuBarDeclutterService
  var onActivateItem: (() -> Void)?

  private let columns = [GridItem(.adaptive(minimum: 92), spacing: DesignTokens.spaceXS)]

  var body: some View {
    CollapsibleSection(title: "Menu bar apps", key: "menuBarApps") {
      if !menuBarApps.hasAccessibilityPermission {
        permissionPrompt
      } else if menuBarApps.items.isEmpty {
        Text("No third-party menu bar apps found.")
          .font(.qhCaption)
          .foregroundStyle(.secondary)
          .padding(.horizontal, DesignTokens.spaceS)
      } else {
        LazyVGrid(columns: columns, alignment: .leading, spacing: DesignTokens.spaceXS) {
          ForEach(menuBarApps.items) { item in
            MenuBarAppChip(item: item, icon: menuBarApps.appIcon(for: item)) {
              onActivateItem?()
              menuBarApps.activate(item, declutter: declutter)
            }
          }
        }
      }
    }
  }

  private var permissionPrompt: some View {
    VStack(alignment: .leading, spacing: DesignTokens.spaceXS) {
      Text("QuickHacks needs Accessibility access to open menu bar apps from here.")
        .font(.qhCaption)
        .foregroundStyle(.secondary)
      Button("Grant access…") {
        menuBarApps.requestAccessibilityPermission()
      }
      .buttonStyle(.bordered)
      .controlSize(.small)
    }
    .padding(.horizontal, DesignTokens.spaceS)
  }
}

private struct MenuBarAppChip: View {
  let item: MenuBarAppItem
  let icon: NSImage?
  let action: () -> Void

  @State private var isHovered = false

  var body: some View {
    Button(action: action) {
      HStack(spacing: DesignTokens.spaceXS) {
        if let icon {
          Image(nsImage: icon)
            .resizable()
            .frame(width: 16, height: 16)
        } else {
          Image(systemName: "app.dashed")
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
        }
        Text(item.appName)
          .font(.qhCaption)
          .lineLimit(1)
      }
      .padding(.horizontal, DesignTokens.spaceS)
      .padding(.vertical, DesignTokens.spaceXS)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(
        RoundedRectangle(cornerRadius: DesignTokens.radiusChip, style: .continuous)
          .fill(isHovered ? DesignTokens.accentSoft : Color.primary.opacity(0.04))
      )
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .onHover { isHovered = $0 }
    .help("Open \(item.displayName)")
  }
}
