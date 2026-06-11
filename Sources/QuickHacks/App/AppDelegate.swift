import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
  private var statusBarController: StatusBarController?

  func applicationDidFinishLaunching(_ notification: Notification) {
    let settings = SettingsStore()
    let services = AppServices(settings: settings)
    statusBarController = StatusBarController(services: services)
  }

  func applicationWillTerminate(_ notification: Notification) {
    statusBarController?.tearDown()
  }
}

/// Dependency container wiring all feature services to one settings store.
@MainActor
final class AppServices {
  let settings: SettingsStore
  let keepAwake: KeepAwakeService
  let quickToggles: QuickToggleService
  let bluetoothGuard: BluetoothGuardService
  let declutter: MenuBarDeclutterService
  let menuBarApps: MenuBarAppsService
  let loginItem: LoginItemService
  let updater: UpdateService
  let installer: AppInstallerService

  /// Set by StatusBarController so views can dismiss the panel before
  /// triggering actions that need an unobstructed menu bar.
  var closePanel: (() -> Void)?

  init(settings: SettingsStore) {
    self.settings = settings
    self.keepAwake = KeepAwakeService()
    self.quickToggles = QuickToggleService()
    self.bluetoothGuard = BluetoothGuardService(settings: settings)
    self.declutter = MenuBarDeclutterService(settings: settings)
    self.menuBarApps = MenuBarAppsService()
    self.loginItem = LoginItemService()
    self.updater = UpdateService()
    self.installer = AppInstallerService()
  }
}
