import SwiftUI

/// The signature element per DESIGN.md: a quiet row that morphs into an
/// accent capsule with live countdown while Keep Awake is active.
struct KeepAwakeSection: View {
  @Bindable var keepAwake: KeepAwakeService

  var body: some View {
    CollapsibleSection(title: "Keep awake", key: "keepAwake") {
      if keepAwake.isActive {
        activeCapsule
      } else {
        durationPicker
      }
    }
    .animation(DesignTokens.spring, value: keepAwake.isActive)
  }

  private var durationPicker: some View {
    HStack(spacing: DesignTokens.spaceXS) {
      Image(systemName: "bolt")
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(.secondary)
        .frame(width: DesignTokens.iconFrame)
      ForEach(KeepAwakeDuration.allCases) { duration in
        Button(duration.label) {
          keepAwake.start(duration)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
      }
      Spacer(minLength: 0)
    }
    .padding(.horizontal, DesignTokens.spaceS)
    .frame(minHeight: DesignTokens.rowMinHeight)
  }

  private var activeCapsule: some View {
    HStack(spacing: DesignTokens.spaceS) {
      Image(systemName: "bolt.fill")
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(DesignTokens.accent)
        .symbolEffect(.pulse, options: .repeating)
        .frame(width: DesignTokens.iconFrame)
      Text("Awake")
        .font(.qhBody)
      Spacer(minLength: 0)
      if let expiresAt = keepAwake.expiresAt {
        Text(expiresAt, style: .timer)
          .font(.qhMono)
          .foregroundStyle(.secondary)
          .contentTransition(.numericText())
      }
      Button("Off") { keepAwake.stop() }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }
    .padding(.horizontal, DesignTokens.spaceS)
    .frame(minHeight: DesignTokens.rowMinHeight + DesignTokens.spaceXS)
    .background(
      RoundedRectangle(cornerRadius: DesignTokens.radiusRow, style: .continuous)
        .fill(DesignTokens.accentSoft)
    )
  }
}
