import AppKit
import ApplicationServices
import Observation

/// One menu bar item belonging to another app, reachable via Accessibility.
struct MenuBarAppItem: Identifiable, Equatable {
  let pid: pid_t
  let appName: String
  let itemIndex: Int
  let title: String?

  var id: String { "\(pid)-\(itemIndex)" }

  var displayName: String {
    guard let title, !title.isEmpty else { return appName }
    return title == appName ? appName : "\(appName): \(title)"
  }
}

/// Lists third-party menu bar items and activates them via AXPress —
/// works without Screen Recording, needs only Accessibility permission.
/// (Coordinate-based clicking is impossible on macOS 26: other apps'
/// status window bounds are masked without Screen Recording.)
@Observable
@MainActor
final class MenuBarAppsService {
  private(set) var items: [MenuBarAppItem] = []
  private(set) var hasAccessibilityPermission = AXIsProcessTrusted()

  func refreshPermission() {
    hasAccessibilityPermission = AXIsProcessTrusted()
  }

  func requestAccessibilityPermission() {
    let options =
      [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
    AXIsProcessTrustedWithOptions(options)
    refreshPermission()
  }

  /// Re-scans running apps that own status-bar windows for AX menu bar extras.
  func refresh() {
    refreshPermission()
    guard hasAccessibilityPermission else {
      items = []
      return
    }
    let candidatePIDs = Self.statusWindowOwnerPIDs()
    var found: [MenuBarAppItem] = []
    for app in NSWorkspace.shared.runningApplications {
      guard candidatePIDs.contains(app.processIdentifier),
        app.processIdentifier != ProcessInfo.processInfo.processIdentifier,
        let bundleID = app.bundleIdentifier,
        !bundleID.hasPrefix("com.apple.")
      else { continue }
      found.append(contentsOf: extrasItems(of: app))
    }
    items = found.sorted {
      $0.appName.localizedCaseInsensitiveCompare($1.appName) == .orderedAscending
    }
  }

  func appIcon(for item: MenuBarAppItem) -> NSImage? {
    NSRunningApplication(processIdentifier: item.pid)?.icon
  }

  /// Expands the menu bar (so the item's menu can anchor properly),
  /// then presses the item via Accessibility.
  func activate(_ item: MenuBarAppItem, declutter: MenuBarDeclutterService) {
    let wasCollapsed = declutter.isCollapsed
    if wasCollapsed { declutter.expand() }
    Task {
      try? await Task.sleep(for: .milliseconds(wasCollapsed ? 350 : 50))
      guard
        let element = Self.extrasMenuBarChildren(pid: item.pid)?
          .dropFirst(item.itemIndex).first
      else { return }
      AXUIElementPerformAction(element, kAXPressAction as CFString)
    }
  }

  private func extrasItems(of app: NSRunningApplication) -> [MenuBarAppItem] {
    guard let children = Self.extrasMenuBarChildren(pid: app.processIdentifier) else {
      return []
    }
    let appName = app.localizedName ?? "Unknown"
    return children.enumerated().map { index, element in
      MenuBarAppItem(
        pid: app.processIdentifier,
        appName: appName,
        itemIndex: index,
        title: Self.stringAttribute(element, kAXTitleAttribute)
          ?? Self.stringAttribute(element, kAXDescriptionAttribute)
      )
    }
  }

  private static func extrasMenuBarChildren(pid: pid_t) -> [AXUIElement]? {
    let app = AXUIElementCreateApplication(pid)
    guard let menuBar: AXUIElement = copyAttribute(app, "AXExtrasMenuBar") else { return nil }
    guard let children: [AXUIElement] = copyAttribute(menuBar, kAXChildrenAttribute) else {
      return nil
    }
    return children
  }

  private static func copyAttribute<T>(_ element: AXUIElement, _ attribute: String) -> T? {
    var value: CFTypeRef?
    let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
    guard result == .success else { return nil }
    return value as? T
  }

  private static func stringAttribute(_ element: AXUIElement, _ attribute: String) -> String? {
    let value: String? = copyAttribute(element, attribute)
    guard let value, !value.isEmpty else { return nil }
    return value
  }

  /// PIDs owning status-layer windows — cheap pre-filter so we only make
  /// AX calls for actual menu bar apps. Bounds are masked without Screen
  /// Recording, but owner PIDs are always available.
  private static func statusWindowOwnerPIDs() -> Set<pid_t> {
    let options: CGWindowListOption = [.optionAll, .excludeDesktopElements]
    guard let list = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]]
    else { return [] }
    var pids: Set<pid_t> = []
    for entry in list {
      guard let layer = entry[kCGWindowLayer as String] as? Int,
        layer == 25,
        let pid = entry[kCGWindowOwnerPID as String] as? pid_t
      else { continue }
      pids.insert(pid)
    }
    return pids
  }
}
