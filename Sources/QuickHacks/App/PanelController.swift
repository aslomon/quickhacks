import AppKit
import Observation
import SwiftUI

/// Where the anchor arrow sits, measured from the panel's left edge.
@Observable
@MainActor
final class PanelArrowAnchor {
  var midXFromLeft: CGFloat = DesignTokens.popoverWidth / 2
  static let height: CGFloat = 8
  static let width: CGFloat = 18
}

/// Borderless non-activating panel anchored below a status item button.
/// Replaces NSPopover, which positions unreliably for status items
/// (it can appear in a screen corner). Same approach as Ice's IceBarPanel.
@MainActor
final class PanelController {
  private let panel: NSPanel
  private let hostingController: NSViewController & PanelSizing
  private let arrowAnchor = PanelArrowAnchor()
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
      rootView:
        content
        .padding(.top, PanelArrowAnchor.height)
        .background(PanelBackground(arrow: arrowAnchor))
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

  /// Centers the panel under the anchor button, clamped to the screen,
  /// and points the arrow at the button's center.
  private func position(relativeTo button: NSStatusBarButton?) {
    guard let screen = button?.window?.screen ?? NSScreen.main else { return }
    let size = panel.frame.size
    let anchorMidX = button?.window.map { $0.frame.midX } ?? screen.visibleFrame.maxX
    let menuBarBottom = screen.visibleFrame.maxY

    var x = anchorMidX - size.width / 2
    x = min(max(x, screen.frame.minX + 8), screen.frame.maxX - size.width - 8)
    let y = menuBarBottom - size.height
    panel.setFrameOrigin(NSPoint(x: x, y: y))

    let inset = PanelArrowAnchor.width / 2 + 12
    arrowAnchor.midXFromLeft = min(max(anchorMidX - x, inset), size.width - inset)
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

/// Rounded material backdrop with an anchor arrow, like NSPopover's chrome.
private struct PanelBackground: View {
  var arrow: PanelArrowAnchor

  var body: some View {
    let shape = PanelShape(
      cornerRadius: 12,
      arrowMidX: arrow.midXFromLeft,
      arrowWidth: PanelArrowAnchor.width,
      arrowHeight: PanelArrowAnchor.height
    )
    shape
      .fill(.regularMaterial)
      .overlay(shape.stroke(Color.primary.opacity(0.1), lineWidth: 1))
  }
}

/// Rounded rectangle whose top edge carries a popover-style arrow.
private struct PanelShape: Shape {
  let cornerRadius: CGFloat
  let arrowMidX: CGFloat
  let arrowWidth: CGFloat
  let arrowHeight: CGFloat

  func path(in rect: CGRect) -> Path {
    let body = CGRect(
      x: rect.minX, y: rect.minY + arrowHeight,
      width: rect.width, height: rect.height - arrowHeight)
    var path = Path(roundedRect: body, cornerRadius: cornerRadius, style: .continuous)
    path.move(to: CGPoint(x: arrowMidX - arrowWidth / 2, y: body.minY))
    path.addLine(to: CGPoint(x: arrowMidX, y: rect.minY))
    path.addLine(to: CGPoint(x: arrowMidX + arrowWidth / 2, y: body.minY))
    path.closeSubpath()
    return path
  }
}
