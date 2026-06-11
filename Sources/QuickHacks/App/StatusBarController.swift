import AppKit
import SwiftUI

/// Owns the main menu bar item and the QuickHacks panel.
@MainActor
final class StatusBarController: NSObject {
  private let services: AppServices
  private let statusItem: NSStatusItem
  private var panelController: PanelController?

  init(services: AppServices) {
    self.services = services
    self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    super.init()
    configureStatusItem()
    panelController = PanelController(content: PopoverRootView(services: services))
    services.closePanel = { [weak self] in self?.panelController?.hide() }
    services.declutter.activate()
  }

  func tearDown() {
    services.keepAwake.stop()
    services.declutter.deactivate()
  }

  private func configureStatusItem() {
    statusItem.autosaveName = "qh_main"
    guard let button = statusItem.button else { return }
    let image = NSImage(
      systemSymbolName: "bolt.square.fill",
      accessibilityDescription: "QuickHacks"
    )
    image?.isTemplate = true
    button.image = image
    button.target = self
    button.action = #selector(togglePanel)
  }

  @objc private func togglePanel() {
    services.menuBarApps.refresh()
    services.bluetoothGuard.refresh()
    panelController?.toggle(relativeTo: statusItem.button)
  }
}
