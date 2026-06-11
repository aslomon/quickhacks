import Foundation
import Observation

/// Numeric version comparison ("1.2.10" > "1.2.9"), kept pure for testing.
enum Semver {
  static func isNewer(_ candidate: String, than current: String) -> Bool {
    let a = components(candidate)
    let b = components(current)
    for index in 0..<max(a.count, b.count) {
      let left = index < a.count ? a[index] : 0
      let right = index < b.count ? b[index] : 0
      if left != right { return left > right }
    }
    return false
  }

  static func components(_ version: String) -> [Int] {
    version
      .trimmingCharacters(in: CharacterSet(charactersIn: "vV "))
      .split(separator: ".")
      .map { Int($0.prefix(while: \.isNumber)) ?? 0 }
  }
}

/// Checks GitHub Releases of a configurable repository for newer versions.
@Observable
@MainActor
final class UpdateService {
  enum State: Equatable {
    case idle
    case checking
    case upToDate
    case updateAvailable(version: String, url: URL)
    case failed(String)
    case notConfigured
  }

  private(set) var state: State = .idle

  private static let repositoryKey = "qh.v1.updateRepository"

  /// GitHub repository in "owner/name" form, e.g. "jasonrinnert/quickhacks".
  var repository: String {
    get { UserDefaults.standard.string(forKey: Self.repositoryKey) ?? "" }
    set { UserDefaults.standard.set(newValue, forKey: Self.repositoryKey) }
  }

  var currentVersion: String {
    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
  }

  func checkForUpdates() async {
    let repo = repository.trimmingCharacters(in: .whitespaces)
    guard !repo.isEmpty, repo.contains("/") else {
      state = .notConfigured
      return
    }
    guard let url = URL(string: "https://api.github.com/repos/\(repo)/releases/latest") else {
      state = .failed("Invalid repository")
      return
    }
    state = .checking
    do {
      let (data, _) = try await URLSession.shared.data(from: url)
      try handleResponse(data)
    } catch {
      state = .failed(error.localizedDescription)
    }
  }

  private func handleResponse(_ data: Data) throws {
    struct Release: Decodable {
      let tagName: String
      let htmlUrl: String
    }
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    let release = try decoder.decode(Release.self, from: data)
    if Semver.isNewer(release.tagName, than: currentVersion),
      let url = URL(string: release.htmlUrl)
    {
      state = .updateAvailable(version: release.tagName, url: url)
    } else {
      state = .upToDate
    }
  }
}
