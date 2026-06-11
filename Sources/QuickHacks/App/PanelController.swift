import AppKit
import SwiftUI

/// Borderless non-activating panel anchored below a status item button.
/// Replaces NSPopover, which positions unreliably for status items
/// (it can appear in a screen corner). Same approach as Ice's IceBarPanel.
@MainActor
final class PanelController {
  private let panel: NSPanel
  private let hostingController: NSViewController & PanelSizing
  private var clickOutsideMonitor: Any?

  var isShown: Bool { panel.isVisible }

  init<Content: View>(content: Content) {
    panel = NSPanel(
      contentRect: .zero,
      styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
      backing: .buffered,
      defer: false
    )
    panel.level = NSWindow.Level(rawValue: NSWindow.Level.mainMenu.rawValue + 1)
    panel.collectionBehavior = [.fullScreenAuxiliary, .ignoresCycle, .moveToActiveSpace]
    panel.isOpaque = false
    panel.backgroundColor = .clear
    panel.hasShadow = true
    panel.isMovable = false
    panel.hidesOnDeactivate = false

    let controller = SizingHostingController(
      rootView: content.background(PanelBackground())
    )
    hostingController = controller
    panel.contentViewController = controller
  }

  func toggle(relativeTo button: NSStatusBarButton?) {
    isShown ? hide() : show(relativeTo: button)
  }

  func show(relativeTo button: NSStatusBarButton?) {
    // A borderless panel created with a zero rect never picks up the SwiftUI
    // content size on its own — measure and apply it before positioning.
    let size = hostingController.idealSize(
      maximum: NSSize(width: 480, height: 1400))
    if size.width > 1, size.height > 1 {
      panel.setContentSize(size)
    }
    position(relativeTo: button)
    panel.orderFrontRegardless()
    panel.makeKey()
    installClickOutsideMonitor()
  }

  func hide() {
    removeClickOutsideMonitor()
    panel.orderOut(nil)
  }

  /// Centers the panel under the anchor button, clamped to the screen.
  private func position(relativeTo button: NSStatusBarButton?) {
    guard let screen = button?.window?.screen ?? NSScreen.main else { return }
    let size = panel.frame.size
    let anchorMidX = button?.window.map { $0.frame.midX } ?? screen.visibleFrame.maxX
    let menuBarBottom = screen.visibleFrame.maxY

    var x = anchorMidX - size.width / 2
    x = min(max(x, screen.frame.minX + 8), screen.frame.maxX - size.width - 8)
    let y = menuBarBottom - size.height - 4
    panel.setFrameOrigin(NSPoint(x: x, y: y))
  }

  private func installClickOutsideMonitor() {
    removeClickOutsideMonitor()
    clickOutsideMonitor = NSEvent.addGlobalMonitorForEvents(
      matching: [.leftMouseDown, .rightMouseDown]
    ) { [weak self] _ in
      Task { @MainActor [weak self] in self?.hide() }
    }
  }

  private func removeClickOutsideMonitor() {
    if let monitor = clickOutsideMonitor {
      NSEvent.removeMonitor(monitor)
      clickOutsideMonitor = nil
    }
  }
}

/// Lets PanelController measure SwiftUI content without knowing Content's type.
@MainActor
protocol PanelSizing {
  func idealSize(maximum: NSSize) -> NSSize
}

private final class SizingHostingController<Content: View>: NSHostingController<Content>,
  PanelSizing
{
  func idealSize(maximum: NSSize) -> NSSize {
    sizeThatFits(in: maximum)
  }
}

/// Rounded material backdrop matching the system popover look.
private struct PanelBackground: View {
  var body: some View {
    RoundedRectangle(cornerRadius: 12, style: .continuous)
      .fill(.regularMaterial)
      .overlay(
        RoundedRectangle(cornerRadius: 12, style: .continuous)
          .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
      )
  }
}
