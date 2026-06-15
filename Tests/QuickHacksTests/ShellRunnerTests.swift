import XCTest

@testable import QuickHacks

final class ShellRunnerTests: XCTestCase {
  func testRunReturnsStandardOutput() async {
    let result = await ShellRunner.run("/bin/echo", ["QuickHacks"])

    guard case .success(let shellResult) = result else {
      return XCTFail("Expected command to succeed")
    }

    XCTAssertEqual(shellResult.standardOutput.trimmingCharacters(in: .whitespacesAndNewlines), "QuickHacks")
    XCTAssertEqual(shellResult.exitCode, 0)
  }

  func testRunReturnsNonZeroExit() async {
    let result = await ShellRunner.run("/bin/sh", ["-c", "echo nope >&2; exit 7"])

    guard case .failure(.nonZeroExit(let shellResult)) = result else {
      return XCTFail("Expected non-zero exit failure")
    }

    XCTAssertEqual(shellResult.exitCode, 7)
    XCTAssertEqual(shellResult.standardError.trimmingCharacters(in: .whitespacesAndNewlines), "nope")
  }

  func testRunTimesOut() async {
    let result = await ShellRunner.run(
      "/bin/sh",
      ["-c", "sleep 2"],
      timeoutSeconds: 1
    )

    guard case .failure(.timedOut(let executable)) = result else {
      return XCTFail("Expected timeout failure")
    }

    XCTAssertEqual(executable, "/bin/sh")
  }
}
