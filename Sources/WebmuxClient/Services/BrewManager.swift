import Foundation

enum BrewManager {

  static let tapName = "alphatechlab/tap"
  static let formulaName = "webmux"
  static let whisperDir: String = {
    let prefix = brewPrefix()
    return "\(prefix)/opt/webmux/libexec/whisper"
  }()

  // MARK: - Checks

  static func brewPrefix() -> String {
    #if arch(arm64)
    "/opt/homebrew"
    #else
    "/usr/local"
    #endif
  }

  static func isBrewInstalled() -> Bool {
    FileManager.default.fileExists(atPath: "\(brewPrefix())/bin/brew")
  }

  static func isNodeInstalled() -> Bool {
    Shell.login("which node").exitCode == 0
  }

  static func nodeVersion() -> String? {
    let r = Shell.login("node --version")
    guard r.exitCode == 0 else { return nil }
    return r.output.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  static func isRustInstalled() -> Bool {
    Shell.login("which rustc").exitCode == 0
  }

  static func rustVersion() -> String? {
    let r = Shell.login("rustc --version")
    guard r.exitCode == 0 else { return nil }
    return r.output.trimmingCharacters(in: .whitespacesAndNewlines)
      .replacingOccurrences(of: "rustc ", with: "")
  }

  static func isPythonInstalled() -> Bool {
    Shell.login("which python3").exitCode == 0
  }

  static func isWebmuxInstalled() -> Bool {
    let r = Shell.run("\(brewPrefix())/bin/brew list \(formulaName) 2>/dev/null")
    return r.exitCode == 0
  }

  static func isWhisperInstalled() -> Bool {
    FileManager.default.fileExists(atPath: "\(whisperDir)/venv/bin/python")
  }

  static func isTapped() -> Bool {
    let r = Shell.run("\(brewPrefix())/bin/brew tap 2>/dev/null")
    return r.output.contains(tapName)
  }

  static func installedVersion() -> String? {
    let r = Shell.run("\(brewPrefix())/bin/brew info \(formulaName) --json=v2 2>/dev/null")
    guard r.exitCode == 0 else { return nil }
    if let range = r.output.range(of: "\"stable\":\"") {
      let start = range.upperBound
      if let end = r.output[start...].firstIndex(of: "\"") {
        return String(r.output[start..<end])
      }
    }
    return nil
  }

  // MARK: - Actions

  static func installBrew() async -> Shell.Result {
    await Shell.runAsync(
      "/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"",
      login: true
    )
  }

  static func tapAndInstall(onOutput: @escaping @Sendable (String) -> Void) async -> Int32 {
    let brew = "\(brewPrefix())/bin/brew"
    let code = await Shell.stream(
      "\(brew) tap \(tapName) && \(brew) install \(formulaName)",
      onLine: onOutput
    )
    return code
  }

  static func upgrade(onOutput: @escaping @Sendable (String) -> Void) async -> Int32 {
    let brew = "\(brewPrefix())/bin/brew"
    return await Shell.stream("\(brew) upgrade \(formulaName)", onLine: onOutput)
  }

  static func checkOutdated() async -> Bool {
    let r = await Shell.runAsync("\(brewPrefix())/bin/brew outdated \(formulaName)")
    return r.exitCode == 0 && !r.output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  static func installWhisper(onOutput: @escaping @Sendable (String) -> Void) async -> Int32 {
    await Shell.stream("cd '\(whisperDir)' && bash install.sh", login: true, onLine: onOutput)
  }

  // MARK: - Paths

  static func webmuxBinary() -> String { "\(brewPrefix())/bin/webmux" }
  static func sidecarBinary() -> String { "\(brewPrefix())/bin/alacritty-sidecar" }
  static func libexecDir() -> String { "\(brewPrefix())/opt/webmux/libexec" }
  static func configPath() -> String { "\(libexecDir())/config.cjs" }
}
