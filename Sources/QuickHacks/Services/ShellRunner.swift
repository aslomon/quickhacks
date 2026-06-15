import Foundation

/// Result of a shell invocation.
struct ShellResult {
  let exitCode: Int32
  let standardOutput: String
  let standardError: String

  var succeeded: Bool { exitCode == 0 }
}

enum ShellError: Error, LocalizedError {
  case launchFailed(String)
  case nonZeroExit(ShellResult)
  case timedOut(String)

  var errorDescription: String? {
    switch self {
    case .launchFailed(let message):
      return "Could not run command: \(message)"
    case .nonZeroExit(let result):
      let detail = result.standardError.trimmingCharacters(in: .whitespacesAndNewlines)
      return detail.isEmpty ? "Command failed (exit \(result.exitCode))" : detail
    case .timedOut(let executable):
      return "Command timed out: \(executable)"
    }
  }
}

/// Runs external tools off the main thread. The only place `Process` is used,
/// so a sandboxed App Store build can swap implementations per feature.
enum ShellRunner {
  static func run(
    _ executable: String,
    _ arguments: [String],
    timeoutSeconds: Int = 20
  ) async -> Result<ShellResult, ShellError> {
    await Task.detached(priority: .userInitiated) {
      runSync(executable, arguments, timeoutSeconds: timeoutSeconds)
    }.value
  }

  private static func runSync(
    _ executable: String,
    _ arguments: [String],
    timeoutSeconds: Int
  ) -> Result<ShellResult, ShellError> {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: executable)
    process.arguments = arguments
    let stdout = Pipe()
    let stderr = Pipe()
    process.standardOutput = stdout
    process.standardError = stderr
    let semaphore = DispatchSemaphore(value: 0)
    process.terminationHandler = { _ in semaphore.signal() }

    do {
      try process.run()
    } catch {
      return .failure(.launchFailed(error.localizedDescription))
    }
    guard waitForExit(semaphore, timeoutSeconds: timeoutSeconds) else {
      process.terminate()
      process.waitUntilExit()
      return .failure(.timedOut(executable))
    }

    let result = ShellResult(
      exitCode: process.terminationStatus,
      standardOutput: readToString(stdout),
      standardError: readToString(stderr)
    )
    return result.succeeded ? .success(result) : .failure(.nonZeroExit(result))
  }

  private static func readToString(_ pipe: Pipe) -> String {
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    return String(data: data, encoding: .utf8) ?? ""
  }

  private static func waitForExit(
    _ semaphore: DispatchSemaphore,
    timeoutSeconds: Int
  ) -> Bool {
    let timeout = DispatchTime.now() + .seconds(timeoutSeconds)
    return semaphore.wait(timeout: timeout) == .success
  }
}
