import Foundation

enum ServiceLabel: String, CaseIterable, Sendable {
  case webmux = "com.user.webmux"
  case whisper = "com.user.webmux-whisper"

  var displayName: String {
    switch self {
    case .webmux: "Webmux Server"
    case .whisper: "Whisper Server"
    }
  }

  var port: String {
    switch self {
    case .webmux: "3030"
    case .whisper: "8000"
    }
  }

  var plistFilename: String { "\(rawValue).plist" }

  var logPaths: [String] {
    switch self {
    case .webmux: ["/tmp/webmux.log", "/tmp/webmux.err"]
    case .whisper: ["/tmp/webmux-whisper.log"]
    }
  }
}

enum ServiceManager {

  private static let uid = "\(getuid())"
  private static let plistDir = FileManager.default.homeDirectoryForCurrentUser.path
    + "/Library/LaunchAgents"

  // MARK: - Status

  static func isRunning(_ service: ServiceLabel) -> Bool {
    let result = Shell.run("launchctl print gui/\(uid)/\(service.rawValue) 2>/dev/null")
    guard result.exitCode == 0 else { return false }
    for line in result.output.components(separatedBy: "\n") {
      let trimmed = line.trimmingCharacters(in: .whitespaces)
      if trimmed.hasPrefix("pid = ") {
        let pidStr = trimmed.replacingOccurrences(of: "pid = ", with: "")
        return (Int(pidStr) ?? 0) > 0
      }
    }
    return false
  }

  static func plistExists(_ service: ServiceLabel) -> Bool {
    FileManager.default.fileExists(atPath: "\(plistDir)/\(service.plistFilename)")
  }

  static func allPlistsExist() -> Bool {
    ServiceLabel.allCases.allSatisfy { plistExists($0) }
  }

  // MARK: - Control

  static func start(_ service: ServiceLabel) async {
    let plistPath = "\(plistDir)/\(service.plistFilename)"
    let target = "gui/\(uid)"
    let result = await Shell.runAsync("launchctl bootstrap \(target) '\(plistPath)' 2>&1")
    if result.exitCode != 0 {
      _ = await Shell.runAsync("launchctl kickstart \(target)/\(service.rawValue) 2>&1")
    }
  }

  static func stop(_ service: ServiceLabel) async {
    _ = await Shell.runAsync("launchctl bootout gui/\(uid)/\(service.rawValue) 2>&1")
  }

  static func restart(_ service: ServiceLabel) async {
    _ = await Shell.runAsync("launchctl kickstart -k gui/\(uid)/\(service.rawValue) 2>&1")
  }

  static func startAll() async {
    for s in ServiceLabel.allCases { await start(s) }
  }

  static func stopAll() async {
    for s in ServiceLabel.allCases { await stop(s) }
  }

  static func stopAllSync() {
    for s in ServiceLabel.allCases {
      _ = Shell.run("launchctl bootout gui/\(uid)/\(s.rawValue) 2>&1")
    }
  }

  // MARK: - Plist creation

  static func createPlists(webmuxBinary: String, whisperDir: String?) async {
    let home = FileManager.default.homeDirectoryForCurrentUser.path

    let webmuxPlist = """
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" \
      "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
          <key>Label</key>
          <string>\(ServiceLabel.webmux.rawValue)</string>
          <key>ProgramArguments</key>
          <array>
              <string>\(webmuxBinary)</string>
          </array>
          <key>EnvironmentVariables</key>
          <dict>
              <key>NODE_ENV</key>
              <string>production</string>
              <key>HOME</key>
              <string>\(home)</string>
              <key>PATH</key>
              <string>/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
          </dict>
          <key>KeepAlive</key>
          <true/>
          <key>StandardOutPath</key>
          <string>/tmp/webmux.log</string>
          <key>StandardErrorPath</key>
          <string>/tmp/webmux.err</string>
      </dict>
      </plist>
      """

    let webmuxPath = "\(plistDir)/\(ServiceLabel.webmux.plistFilename)"
    try? webmuxPlist.write(toFile: webmuxPath, atomically: true, encoding: .utf8)

    if let wDir = whisperDir {
      let whisperPlist = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" \
        "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>\(ServiceLabel.whisper.rawValue)</string>
            <key>ProgramArguments</key>
            <array>
                <string>\(wDir)/venv/bin/python</string>
                <string>\(wDir)/server.py</string>
            </array>
            <key>WorkingDirectory</key>
            <string>\(wDir)</string>
            <key>EnvironmentVariables</key>
            <dict>
                <key>PATH</key>
                <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string>
            </dict>
            <key>KeepAlive</key>
            <true/>
            <key>StandardOutPath</key>
            <string>/tmp/webmux-whisper.log</string>
            <key>StandardErrorPath</key>
            <string>/tmp/webmux-whisper.log</string>
        </dict>
        </plist>
        """

      let whisperPath = "\(plistDir)/\(ServiceLabel.whisper.plistFilename)"
      try? whisperPlist.write(toFile: whisperPath, atomically: true, encoding: .utf8)
    }
  }
}
