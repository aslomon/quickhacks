import AppKit
import Observation

/// Hides third-party menu bar icons using the proven Hidden Bar technique:
/// a separator NSStatusItem expands, pushing every item to its left
/// off-screen. Users arrange icons with ⌘-drag.
///
/// Safety rules (learned the hard way):
/// - Never collapse automatically on launch.
/// - Never collapse while our own items sit left of the separator —
///   that would hide the app's own controls.
/// - Cap the separator length to roughly one screen width, not 10000.
@Observable
@MainActor
final class MenuBarDeclutterService {
  private(set) var isCollapsed = false
  /// True when collapsing was refused because our items are misarranged.
  private(set) var needsArrangement = false

  private let settings: SettingsStore
  private var chevronItem: NSStatusItem?
  private var separatorItem: NSStatusItem?
  private var autoCollapseTask: Task<Void, Never>?

  private static let expandedSeparatorLength: CGFloat = 8

  /// Hidden Bar's formula: enough to push one screen's worth of icons off.
  private static var collapsedSeparatorLength: CGFloat {
    let widest = NSScreen.screens.map(\.frame.width).max() ?? 2000
    return max(500, min(widest + 200, 4000))
  }

  init(settings: SettingsStore) {
    self.settings = settings
  }

  /// Creation order matters: new status items insert at the LEFT of
  /// existing ones. The main bolt item already exists, so creating the
  /// chevron first and the separator second yields, left to right:
  /// [separator][chevron][bolt] — nothing of ours left of the separator.
  func activate() {
    guard settings.declutterEnabled, chevronItem == nil else { return }
    makeChevronItem()
    makeSeparatorItem()
  }

  func deactivate() {
    autoCollapseTask?.cancel()
    if let chevronItem { NSStatusBar.system.removeStatusItem(chevronItem) }
    if let separatorItem { NSStatusBar.system.removeStatusItem(separatorItem) }
    chevronItem = nil
    separatorItem = nil
    isCollapsed = false
    needsArrangement = false
  }

  func setEnabled(_ enabled: Bool) {
    settings.declutterEnabled = enabled
    enabled ? activate() : deactivate()
  }

  @objc func toggleCollapse() {
    isCollapsed ? expand() : collapse()
  }

  func collapse() {
    guard ownItemsAreRightOfSeparator() else {
      needsArrangement = true
      return
    }
    needsArrangement = false
    autoCollapseTask?.cancel()
    separatorItem?.length = Self.collapsedSeparatorLength
    isCollapsed = true
    updateChevronIcon()
  }

  func expand() {
    separatorItem?.length = Self.expandedSeparatorLength
    isCollapsed = false
    updateChevronIcon()
    scheduleAutoCollapse()
  }

  /// The separator must sit left of the chevron AND left of the main item,
  /// otherwise collapsing would push our own controls off-screen.
  private func ownItemsAreRightOfSeparator() -> Bool {
    guard let separatorWindow = separatorItem?.button?.window else { return false }
    let ownStatusWindows = NSApp.windows.filter {
      $0.className.contains("NSStatusBarWindow") && $0 !== separatorWindow
    }
    guard !ownStatusWindows.isEmpty else { return false }
    return ownStatusWindows.allSatisfy { $0.frame.minX > separatorWindow.frame.minX }
  }

  private func makeSeparatorItem() {
    let item = NSStatusBar.system.statusItem(withLength: Self.expandedSeparatorLength)
    item.autosaveName = "qh_separator"
    if let button = item.button {
      let image = NSImage(
        systemSymbolName: "line.diagonal", accessibilityDescription: "QuickHacks separator")
      image?.isTemplate = true
      button.image = image
      button.appearsDisabled = true
    }
    separatorItem = item
  }

  private func makeChevronItem() {
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    item.autosaveName = "qh_chevron"
    if let button = item.button {
      button.target = self
      button.action = #selector(toggleCollapse)
    }
    chevronItem = item
    updateChevronIcon()
  }

  private func updateChevronIcon() {
    guard let button = chevronItem?.button else { return }
    let symbol = isCollapsed ? "chevron.left" : "chevron.right"
    let image = NSImage(
      systemSymbolName: symbol,
      accessibilityDescription: isCollapsed ? "Show hidden icons" : "Hide icons"
    )
    image?.isTemplate = true
    button.image = image
  }

  private func scheduleAutoCollapse() {
    autoCollapseTask?.cancel()
    let seconds = settings.autoCollapseSeconds
    guard seconds > 0 else { return }
    autoCollapseTask = Task { [weak self] in
      try? await Task.sleep(for: .seconds(seconds))
      guard !Task.isCancelled else { return }
      self?.collapse()
    }
  }
}
