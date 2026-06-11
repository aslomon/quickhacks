import XCTest

@testable import QuickHacks

@MainActor
final class SettingsStoreTests: XCTestCase {
  private var defaults: UserDefaults!

  override func setUp() {
    super.setUp()
    defaults = UserDefaults(suiteName: "qh.tests")
    defaults.removePersistentDomain(forName: "qh.tests")
  }

  func testDefaultsOnFirstLaunch() {
    let store = SettingsStore(defaults: defaults)
    XCTAssertTrue(store.declutterEnabled)
    XCTAssertEqual(store.autoCollapseSeconds, 30)
    XCTAssertTrue(store.blockedDevices.isEmpty)
  }

  func testToggleBlockedAddsAndRemoves() {
    let store = SettingsStore(defaults: defaults)
    store.toggleBlocked(address: "aa-bb-cc", name: "AirPods")
    XCTAssertTrue(store.isBlocked(address: "aa-bb-cc"))
    store.toggleBlocked(address: "aa-bb-cc", name: "AirPods")
    XCTAssertFalse(store.isBlocked(address: "aa-bb-cc"))
  }

  func testBlockedDevicesPersistAcrossInstances() {
    let store = SettingsStore(defaults: defaults)
    store.toggleBlocked(address: "11-22-33", name: "Keyboard")
    let reloaded = SettingsStore(defaults: defaults)
    XCTAssertEqual(reloaded.blockedDevices, [BlockedDevice(address: "11-22-33", name: "Keyboard")])
  }

  func testSettingsPersistAcrossInstances() {
    let store = SettingsStore(defaults: defaults)
    store.declutterEnabled = false
    store.autoCollapseSeconds = 60
    let reloaded = SettingsStore(defaults: defaults)
    XCTAssertFalse(reloaded.declutterEnabled)
    XCTAssertEqual(reloaded.autoCollapseSeconds, 60)
  }
}

@MainActor
final class KeepAwakeDurationTests: XCTestCase {
  func testIntervals() {
    XCTAssertEqual(KeepAwakeDuration.fifteenMinutes.interval, 900)
    XCTAssertEqual(KeepAwakeDuration.oneHour.interval, 3600)
    XCTAssertEqual(KeepAwakeDuration.fourHours.interval, 14400)
    XCTAssertNil(KeepAwakeDuration.indefinitely.interval)
  }

  func testKeepAwakeStartStop() {
    let service = KeepAwakeService()
    service.start(.indefinitely)
    XCTAssertTrue(service.isActive)
    XCTAssertNil(service.expiresAt)
    service.stop()
    XCTAssertFalse(service.isActive)
  }

  func testKeepAwakeExpiryDateSet() {
    let service = KeepAwakeService()
    service.start(.fifteenMinutes)
    XCTAssertTrue(service.isActive)
    XCTAssertNotNil(service.expiresAt)
    service.stop()
    XCTAssertNil(service.expiresAt)
  }
}
