import XCTest

@testable import QuickHacks

final class SemverTests: XCTestCase {
  func testNewerVersions() {
    XCTAssertTrue(Semver.isNewer("1.0.1", than: "1.0.0"))
    XCTAssertTrue(Semver.isNewer("2.0", than: "1.9.9"))
    XCTAssertTrue(Semver.isNewer("1.2.10", than: "1.2.9"))
    XCTAssertTrue(Semver.isNewer("v1.1.0", than: "1.0.0"), "tag prefixes are stripped")
  }

  func testNotNewerVersions() {
    XCTAssertFalse(Semver.isNewer("1.0.0", than: "1.0.0"))
    XCTAssertFalse(Semver.isNewer("1.0.0", than: "1.0.1"))
    XCTAssertFalse(Semver.isNewer("0.9", than: "1.0"))
  }

  func testComponentsParsing() {
    XCTAssertEqual(Semver.components("v1.2.3"), [1, 2, 3])
    XCTAssertEqual(Semver.components("1.0.0-beta"), [1, 0, 0])
  }
}
