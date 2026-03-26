import Foundation

enum Shell {

  struct Result: Sendable {
    let exitCode: Int32
    let output: String
  }

  static func run(_ command: String) -> Result {
    let process = Process()
    let pipe = Pipe()
    process.executableURL = URL(fileURLWithPath: "/bin/zsh")
    process.arguments = ["-c", command]
    process.standardOutput = pipe
    process.standardError = pipe
    do {
      try process.run()
      process.waitUntilExit()
    } catch {
      return Result(exitCode: -1, output: error.localizedDescription)
    }
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8) ?? ""
    return Result(exitCode: process.terminationStatus, output: output)
  }

  static func login(_ command: String) -> Result {
    let process = Process()
    let pipe = Pipe()
    process.executableURL = URL(fileURLWithPath: "/bin/zsh")
    process.arguments = ["-l", "-c", command]
    process.standardOutput = pipe
    process.standardError = pipe
    do {
      try process.run()
      process.waitUntilExit()
    } catch {
      return Result(exitCode: -1, output: error.localizedDescription)
    }
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8) ?? ""
    return Result(exitCode: process.terminationStatus, output: output)
  }

  static func runAsync(_ command: String, login useLogin: Bool = false) async -> Result {
    await withCheckedContinuation { continuation in
      DispatchQueue.global(qos: .userInitiated).async {
        let result = useLogin ? Self.login(command) : Self.run(command)
        continuation.resume(returning: result)
      }
    }
  }

  static func stream(
    _ command: String,
    login useLogin: Bool = false,
    onLine: @escaping @Sendable (String) -> Void
  ) async -> Int32 {
    await withCheckedContinuation { continuation in
      DispatchQueue.global(qos: .userInitiated).async {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = useLogin ? ["-l", "-c", command] : ["-c", command]
        process.standardOutput = pipe
        process.standardError = pipe

        pipe.fileHandleForReading.readabilityHandler = { handle in
          let data = handle.availableData
          guard !data.isEmpty else { return }
          if let line = String(data: data, encoding: .utf8) {
            onLine(line)
          }
        }

        do {
          try process.run()
          process.waitUntilExit()
        } catch {
          onLine("Error: \(error.localizedDescription)")
          continuation.resume(returning: Int32(-1))
          return
        }

        pipe.fileHandleForReading.readabilityHandler = nil
        continuation.resume(returning: process.terminationStatus)
      }
    }
  }
}
