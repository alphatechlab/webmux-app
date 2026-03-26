import Foundation
import SwiftUI
import Observation

@Observable
@MainActor
final class AppState {

  // MARK: - Setup state

  enum AppMode { case setup, running }
  enum SetupStep: Int, CaseIterable {
    case check = 0, install, configure, done
    var title: String {
      switch self {
      case .check: "Check"
      case .install: "Install"
      case .configure: "Configure"
      case .done: "Done"
      }
    }
  }

  var mode: AppMode = .setup
  var setupStep: SetupStep = .check

  var hasHomebrew = false
  var hasNode = false
  var hasRust = false
  var hasPython = false
  var hasWebmux = false
  var hasWhisper = false
  var hasServices = false
  var nodeVersion = ""
  var rustVersion = ""

  var installLog = ""
  var isInstalling = false
  var installFailed = false

  var githubDir = ""
  var installWhisperOption = true

  // MARK: - Runtime state

  var webmuxRunning = false
  var whisperRunning = false
  var isOutdated = false
  var isWorking = false
  var workMessage = ""
  var lastCheckMessage = ""
  var isChecking = false

  var allRunning: Bool { webmuxRunning && whisperRunning }
  var anyRunning: Bool { webmuxRunning || whisperRunning }

  private var pollTimer: Timer?

  // MARK: - Init

  func bootstrap() async {
    await checkDependencies()

    let ready = hasWebmux && hasServices
    mode = ready ? .running : .setup

    if mode == .running {
      await ServiceManager.startAll()
      try? await Task.sleep(for: .seconds(2))
      refreshServices()
      startPolling()
    }

    NotificationCenter.default.addObserver(
      forName: NSApplication.willTerminateNotification,
      object: nil, queue: .main
    ) { [weak self] _ in
      guard let self else { return }
      MainActor.assumeIsolated {
        self.pollTimer?.invalidate()
        ServiceManager.stopAllSync()
      }
    }
  }

  // MARK: - Dependency checks

  func checkDependencies() async {
    hasHomebrew = BrewManager.isBrewInstalled()
    hasNode = BrewManager.isNodeInstalled()
    hasPython = BrewManager.isPythonInstalled()
    hasRust = BrewManager.isRustInstalled()
    hasWebmux = BrewManager.isWebmuxInstalled()
    hasWhisper = BrewManager.isWhisperInstalled()
    hasServices = ServiceManager.allPlistsExist()

    if hasNode { nodeVersion = BrewManager.nodeVersion() ?? "" }
    if hasRust { rustVersion = BrewManager.rustVersion() ?? "" }

    let home = FileManager.default.homeDirectoryForCurrentUser.path
    if githubDir.isEmpty {
      let defaultDir = "\(home)/GitHub"
      if FileManager.default.fileExists(atPath: defaultDir) {
        githubDir = defaultDir
      }
    }
  }

  // MARK: - Install flow

  func runInstall() async {
    isInstalling = true
    installFailed = false
    installLog = ""

    if !hasHomebrew {
      appendLog("Installing Homebrew...\n")
      let r = await BrewManager.installBrew()
      if r.exitCode != 0 {
        appendLog("Homebrew installation failed.\n\(r.output)\n")
        installFailed = true
        isInstalling = false
        return
      }
      hasHomebrew = true
    }

    appendLog("Installing webmux via Homebrew...\n")
    appendLog("$ brew tap \(BrewManager.tapName) && brew install \(BrewManager.formulaName)\n\n")

    let code = await BrewManager.tapAndInstall { [weak self] line in
      Task { @MainActor [weak self] in
        self?.appendLog(line)
      }
    }

    if code != 0 {
      appendLog("\nInstallation failed (exit \(code)).\n")
      installFailed = true
      isInstalling = false
      return
    }

    hasWebmux = true
    appendLog("\nWebmux installed successfully!\n")

    if installWhisperOption && hasPython {
      appendLog("\nInstalling Whisper...\n")
      let wCode = await BrewManager.installWhisper { [weak self] line in
        Task { @MainActor [weak self] in
          self?.appendLog(line)
        }
      }
      if wCode == 0 {
        hasWhisper = true
        appendLog("Whisper installed!\n")
      } else {
        appendLog("Whisper installation failed (non-critical).\n")
      }
    }

    isInstalling = false
  }

  private func appendLog(_ text: String) {
    installLog += text
  }

  // MARK: - Configure & finish

  func finishSetup() async {
    let configPath = BrewManager.configPath()
    if !FileManager.default.fileExists(atPath: configPath) {
      let config = """
        module.exports = {
          githubDir: '\(githubDir)',
          whisper: {
            primary: { url: 'http://localhost:8000/transcribe', label: 'Local' },
            secondary: { url: '', label: '' },
          },
          terminal: {
            fontSize: 20,
            fontFamily: 'Menlo, monospace',
            scrollback: 10000,
            cursorBlink: false,
            theme: { background: '#15191F', foreground: '#e0e0e0', cursor: '#e0e0e0', selectionBackground: '#0f346080' },
          },
          projects: {},
        };
        """
      try? config.write(toFile: configPath, atomically: true, encoding: .utf8)
    }

    let whisperDir = installWhisperOption && hasWhisper ? BrewManager.whisperDir : nil
    await ServiceManager.createPlists(
      webmuxBinary: BrewManager.webmuxBinary(),
      whisperDir: whisperDir
    )
    hasServices = true

    await ServiceManager.startAll()
    try? await Task.sleep(for: .seconds(2))
    refreshServices()

    mode = .running
    startPolling()
  }

  // MARK: - Runtime

  func refreshServices() {
    webmuxRunning = ServiceManager.isRunning(.webmux)
    whisperRunning = ServiceManager.isRunning(.whisper)
  }

  private func startPolling() {
    pollTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
      Task { @MainActor [weak self] in
        self?.refreshServices()
      }
    }
  }

  func startService(_ service: ServiceLabel) async {
    setRunning(service, true)
    await ServiceManager.start(service)
    try? await Task.sleep(for: .seconds(1))
    refreshServices()
  }

  func stopService(_ service: ServiceLabel) async {
    setRunning(service, false)
    await ServiceManager.stop(service)
    try? await Task.sleep(for: .seconds(1))
    refreshServices()
  }

  func restartService(_ service: ServiceLabel) async {
    await ServiceManager.restart(service)
    try? await Task.sleep(for: .seconds(2))
    refreshServices()
  }

  func startAll() async {
    await ServiceManager.startAll()
    try? await Task.sleep(for: .seconds(2))
    refreshServices()
  }

  func stopAll() async {
    await ServiceManager.stopAll()
    try? await Task.sleep(for: .seconds(1))
    refreshServices()
  }

  func isRunning(_ service: ServiceLabel) -> Bool {
    switch service {
    case .webmux: webmuxRunning
    case .whisper: whisperRunning
    }
  }

  private func setRunning(_ service: ServiceLabel, _ value: Bool) {
    switch service {
    case .webmux: webmuxRunning = value
    case .whisper: whisperRunning = value
    }
  }

  // MARK: - Updates

  func checkForUpdates() async {
    isChecking = true
    lastCheckMessage = ""
    let outdated = await BrewManager.checkOutdated()
    isOutdated = outdated
    lastCheckMessage = outdated ? "" : "Up to date"
    isChecking = false
  }

  func runUpdate() async {
    isWorking = true
    workMessage = "Stopping services..."
    await ServiceManager.stopAll()

    workMessage = "Upgrading webmux..."
    let code = await BrewManager.upgrade { [weak self] line in
      Task { @MainActor [weak self] in
        self?.workMessage = String(line.prefix(80))
      }
    }

    if code != 0 {
      workMessage = "Upgrade failed"
      try? await Task.sleep(for: .seconds(3))
    } else {
      workMessage = "Restarting..."
      await ServiceManager.startAll()
      isOutdated = false
      workMessage = "Updated!"
      try? await Task.sleep(for: .seconds(1))
    }

    isWorking = false
    try? await Task.sleep(for: .seconds(1))
    refreshServices()
  }

  // MARK: - Actions

  func openInBrowser() {
    if let url = URL(string: "https://localhost:3030") {
      NSWorkspace.shared.open(url)
    }
  }

  func openLog(_ path: String) {
    NSWorkspace.shared.open(URL(fileURLWithPath: path))
  }
}
