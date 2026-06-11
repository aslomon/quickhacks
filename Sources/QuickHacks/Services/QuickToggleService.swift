import AppKit
import Observation

/// System tweaks that macOS Control Center does NOT cover (research-backed):
/// Finder visibility toggles, Dock auto-hide, microphone mute, eject, Trash.
@Observable
@MainActor
final class QuickToggleService {
  /// Last error per action, surfaced inline in the UI.
  var lastError: [QuickToggleAction: String] = [:]

  var hiddenFilesShown: Bool
  var desktopIconsHidden: Bool
  var dockAutoHidden: Bool
  var microphoneMuted: Bool

  private static let savedMicVolumeKey = "qh.v1.savedMicVolume"

  init() {
    hiddenFilesShown = Self.readDefaultsBool("com.apple.finder", "AppleShowAllFiles", false)
    desktopIconsHidden = !Self.readDefaultsBool("com.apple.finder", "CreateDesktop", true)
    dockAutoHidden = Self.readDefaultsBool("com.apple.dock", "autohide", false)
    microphoneMuted = Self.readMicrophoneVolume() == 0
  }

  func perform(_ action: QuickToggleAction) {
    lastError[action] = nil
    Task { await execute(action) }
  }

  private func execute(_ action: QuickToggleAction) async {
    let result: Result<Void, ShellError>
    switch action {
    case .toggleHiddenFiles:
      result = await setDefaultsBool(
        "com.apple.finder", "AppleShowAllFiles", !hiddenFilesShown, restart: "Finder")
      if case .success = result { hiddenFilesShown.toggle() }
    case .toggleDesktopIcons:
      result = await setDefaultsBool(
        "com.apple.finder", "CreateDesktop", desktopIconsHidden, restart: "Finder")
      if case .success = result { desktopIconsHidden.toggle() }
    case .toggleDockAutoHide:
      result = await setDefaultsBool(
        "com.apple.dock", "autohide", !dockAutoHidden, restart: "Dock")
      if case .success = result { dockAutoHidden.toggle() }
    case .toggleMicrophoneMute:
      result = toggleMicrophone()
    case .ejectAllDisks:
      result = runAppleScript(
        "tell application \"Finder\" to eject (every disk whose ejectable is true)")
    case .emptyTrash:
      result = runAppleScript("tell application \"Finder\" to empty trash")
    }
    if case .failure(let error) = result {
      lastError[action] = error.errorDescription
      scheduleErrorDismiss(for: action)
    }
  }

  private func toggleMicrophone() -> Result<Void, ShellError> {
    if microphoneMuted {
      let saved = UserDefaults.standard.object(forKey: Self.savedMicVolumeKey) as? Int ?? 75
      let result = runAppleScript("set volume input volume \(saved)")
      if case .success = result { microphoneMuted = false }
      return result
    }
    let current = Self.readMicrophoneVolume() ?? 75
    UserDefaults.standard.set(max(current, 1), forKey: Self.savedMicVolumeKey)
    let result = runAppleScript("set volume input volume 0")
    if case .success = result { microphoneMuted = true }
    return result
  }

  private func setDefaultsBool(
    _ domain: String, _ key: String, _ value: Bool, restart process: String
  ) async -> Result<Void, ShellError> {
    let write = await ShellRunner.run(
      "/usr/bin/defaults",
      ["write", domain, key, "-bool", value ? "true" : "false"]
    ).map { _ in () }
    guard case .success = write else { return write }
    return await ShellRunner.run("/usr/bin/killall", [process]).map { _ in () }
  }

  private func runAppleScript(_ source: String) -> Result<Void, ShellError> {
    var errorInfo: NSDictionary?
    NSAppleScript(source: source)?.executeAndReturnError(&errorInfo)
    if let message = errorInfo?[NSAppleScript.errorMessage] as? String {
      return .failure(.launchFailed(message))
    }
    return .success(())
  }

  private func scheduleErrorDismiss(for action: QuickToggleAction) {
    Task {
      try? await Task.sleep(for: .seconds(5))
      lastError[action] = nil
    }
  }

  private static func readDefaultsBool(_ domain: String, _ key: String, _ fallback: Bool) -> Bool {
    UserDefaults(suiteName: domain)?.object(forKey: key) as? Bool ?? fallback
  }

  private static func readMicrophoneVolume() -> Int? {
    var errorInfo: NSDictionary?
    let script = NSAppleScript(source: "input volume of (get volume settings)")
    guard let descriptor = script?.executeAndReturnError(&errorInfo), errorInfo == nil else {
      return nil
    }
    return Int(descriptor.int32Value)
  }
}

enum QuickToggleAction: String, CaseIterable, Identifiable {
  case toggleHiddenFiles
  case toggleDesktopIcons
  case toggleDockAutoHide
  case toggleMicrophoneMute
  case ejectAllDisks
  case emptyTrash

  var id: String { rawValue }
}
