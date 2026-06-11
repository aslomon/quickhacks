import SwiftUI

struct SettingsView: View {
  let services: AppServices

  var body: some View {
    VStack(alignment: .leading, spacing: DesignTokens.spaceL) {
      generalSection
      updateSection
      installSection
    }
  }

  private var generalSection: some View {
    VStack(alignment: .leading, spacing: DesignTokens.spaceXS) {
      SectionHeader(title: "General")
      ToggleRow(
        symbol: "power.circle",
        label: "Launch at login",
        isOn: Binding(
          get: { services.loginItem.isEnabled },
          set: { services.loginItem.setEnabled($0) }
        )
      )
      if let error = services.loginItem.lastError {
        InlineError(message: error)
      }
    }
  }

  private var updateSection: some View {
    VStack(alignment: .leading, spacing: DesignTokens.spaceXS) {
      SectionHeader(title: "Updates")
      UpdateRow(updater: services.updater)
    }
  }

  @ViewBuilder
  private var installSection: some View {
    if services.installer.isRunningFromBundle, !services.installer.isInApplications {
      VStack(alignment: .leading, spacing: DesignTokens.spaceXS) {
        SectionHeader(title: "Install")
        Text("QuickHacks is not in your Applications folder yet.")
          .font(.qhCaption)
          .foregroundStyle(.secondary)
          .padding(.horizontal, DesignTokens.spaceS)
        Button("Move to Applications and relaunch") {
          services.installer.moveToApplications()
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .padding(.horizontal, DesignTokens.spaceS)
        if let error = services.installer.lastError {
          InlineError(message: error)
        }
      }
    }
  }
}

private struct UpdateRow: View {
  @Bindable var updater: UpdateService
  @State private var repositoryDraft: String = ""

  var body: some View {
    VStack(alignment: .leading, spacing: DesignTokens.spaceXS) {
      HStack(spacing: DesignTokens.spaceS) {
        TextField("GitHub repo (owner/name)", text: $repositoryDraft)
          .textFieldStyle(.roundedBorder)
          .controlSize(.small)
          .font(.qhCaption)
          .onSubmit { updater.repository = repositoryDraft }
        Button("Check") {
          updater.repository = repositoryDraft
          Task { await updater.checkForUpdates() }
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
      }
      .padding(.horizontal, DesignTokens.spaceS)
      statusLine
        .padding(.horizontal, DesignTokens.spaceS)
    }
    .onAppear { repositoryDraft = updater.repository }
  }

  @ViewBuilder
  private var statusLine: some View {
    switch updater.state {
    case .idle:
      Text("Version \(updater.currentVersion)")
        .font(.qhCaption)
        .foregroundStyle(.secondary)
    case .checking:
      Text("Checking…")
        .font(.qhCaption)
        .foregroundStyle(.secondary)
    case .upToDate:
      Text("Up to date (\(updater.currentVersion))")
        .font(.qhCaption)
        .foregroundStyle(.secondary)
    case .updateAvailable(let version, let url):
      HStack(spacing: DesignTokens.spaceXS) {
        Text("\(version) available")
          .font(.qhCaption)
          .foregroundStyle(DesignTokens.accent)
        Link("Open release page", destination: url)
          .font(.qhCaption)
      }
    case .failed(let message):
      InlineError(message: message)
    case .notConfigured:
      Text("Set a GitHub repository to enable update checks.")
        .font(.qhCaption)
        .foregroundStyle(.secondary)
    }
  }
}
