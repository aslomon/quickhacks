import SwiftUI

/// Design tokens per DESIGN.md — the only place visual constants live.
enum DesignTokens {
  // Colors
  static let accent = Color(red: 0.91, green: 0.365, blue: 0.227)  // #E85D3A
  static let accentSoft = accent.opacity(0.12)
  static let dangerText = Color(red: 0.78, green: 0.224, blue: 0.169)  // #C7392B
  static let divider = Color.primary.opacity(0.08)

  // Spacing (8pt grid)
  static let spaceXS: CGFloat = 4
  static let spaceS: CGFloat = 8
  static let spaceM: CGFloat = 12
  static let spaceL: CGFloat = 16
  static let spaceXL: CGFloat = 24

  // Shape
  static let radiusRow: CGFloat = 8
  static let radiusChip: CGFloat = 6

  // Layout
  static let popoverWidth: CGFloat = 320
  static let popoverHeight: CGFloat = 520
  static let rowMinHeight: CGFloat = 28
  static let iconFrame: CGFloat = 18

  // Motion
  static let spring = Animation.spring(duration: 0.25, bounce: 0.15)
}

extension Font {
  static let qhDisplay = Font.system(size: 15, weight: .semibold, design: .rounded)
  static let qhHeading = Font.system(size: 11, weight: .semibold)
  static let qhBody = Font.system(size: 13)
  static let qhCaption = Font.system(size: 11)
  static let qhMono = Font.system(size: 11, design: .monospaced)
}
