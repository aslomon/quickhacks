import SwiftUI

/// Uppercase section header per DESIGN.md heading scale.
struct SectionHeader: View {
  let title: String

  var body: some View {
    Text(title.uppercased())
      .font(.qhHeading)
      .kerning(0.6)
      .foregroundStyle(.secondary)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, DesignTokens.spaceXS)
  }
}

/// A row with icon + label and a whole-row click action, hover-highlighted.
struct ActionRow: View {
  let symbol: String
  let label: String
  var labelColor: Color = .primary
  let action: () -> Void

  @State private var isHovered = false

  var body: some View {
    Button(action: action) {
      HStack(spacing: DesignTokens.spaceS) {
        Image(systemName: symbol)
          .font(.system(size: 13, weight: .medium))
          .foregroundStyle(.secondary)
          .frame(width: DesignTokens.iconFrame)
        Text(label)
          .font(.qhBody)
          .foregroundStyle(labelColor)
        Spacer(minLength: 0)
      }
      .padding(.horizontal, DesignTokens.spaceS)
      .frame(minHeight: DesignTokens.rowMinHeight)
      .contentShape(Rectangle())
      .background(
        RoundedRectangle(cornerRadius: DesignTokens.radiusChip, style: .continuous)
          .fill(isHovered ? DesignTokens.accentSoft : .clear)
      )
    }
    .buttonStyle(.plain)
    .onHover { isHovered = $0 }
  }
}

/// A row with icon + label and a trailing switch toggle.
struct ToggleRow: View {
  let symbol: String
  let label: String
  @Binding var isOn: Bool

  var body: some View {
    HStack(spacing: DesignTokens.spaceS) {
      Image(systemName: symbol)
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(isOn ? DesignTokens.accent : .secondary)
        .frame(width: DesignTokens.iconFrame)
      Text(label)
        .font(.qhBody)
      Spacer(minLength: 0)
      Toggle("", isOn: $isOn)
        .labelsHidden()
        .toggleStyle(.switch)
        .controlSize(.mini)
        .tint(DesignTokens.accent)
    }
    .padding(.horizontal, DesignTokens.spaceS)
    .frame(minHeight: DesignTokens.rowMinHeight)
  }
}

/// Section with a clickable header that expands/collapses its content.
/// Expansion state persists per section key.
struct CollapsibleSection<Content: View>: View {
  let title: String
  @AppStorage private var isExpanded: Bool
  @ViewBuilder let content: () -> Content

  init(
    title: String, key: String, initiallyExpanded: Bool = true,
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.title = title
    self._isExpanded = AppStorage(wrappedValue: initiallyExpanded, "qh.v1.section.\(key)")
    self.content = content
  }

  var body: some View {
    VStack(alignment: .leading, spacing: DesignTokens.spaceXS) {
      Button {
        withAnimation(DesignTokens.spring) { isExpanded.toggle() }
      } label: {
        HStack(spacing: DesignTokens.spaceXS) {
          Text(title.uppercased())
            .font(.qhHeading)
            .kerning(0.6)
            .foregroundStyle(.secondary)
          Spacer(minLength: 0)
          Image(systemName: "chevron.down")
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(.secondary)
            .rotationEffect(.degrees(isExpanded ? 0 : -90))
        }
        .padding(.horizontal, DesignTokens.spaceXS)
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      if isExpanded {
        content()
      }
    }
  }
}

/// Inline error caption per DESIGN.md error surfaces.
struct InlineError: View {
  let message: String

  var body: some View {
    Text(message)
      .font(.qhCaption)
      .foregroundStyle(DesignTokens.dangerText)
      .padding(.horizontal, DesignTokens.spaceS)
      .transition(.opacity)
  }
}
