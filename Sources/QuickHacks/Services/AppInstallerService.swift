import AppKit
import Observation

/// Offers to move the app bundle into /Applications and relaunch from there
/// (required for reliable launch-at-login and update installs).
@Observable
@MainActor
final class AppInstallerService {
  private(set) var lastError: String?

  var isInApplications: Bool {
    Bundle.main.bundlePath.hasPrefix("/Applications/")
  }

  var isRunningFromBundle: Bool {
    Bundle.main.bundlePath.hasSuffix(".app")
  }

  func moveToApplications() {
    lastError = nil
    let source = URL(fileURLWithPath: Bundle.main.bundlePath)
    let target = URL(fileURLWithPath: "/Applications")
      .appendingPathComponent(source.lastPathComponent)
    do {
      let fileManager = FileManager.default
      if fileManager.fileExists(atPath: target.path) {
        try fileManager.removeItem(at: target)
      }
      try fileManager.copyItem(at: source, to: target)
      relaunch(from: target)
    } catch {
      lastError = error.localizedDescription
    }
  }

  private func relaunch(from url: URL) {
    let configuration = NSWorkspace.OpenConfiguration()
    configuration.createsNewApplicationInstance = true
    NSWorkspace.shared.openApplication(at: url, configuration: configuration) { _, _ in
      Task { @MainActor in NSApp.terminate(nil) }
    }
  }
}
