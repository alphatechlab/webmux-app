import SwiftUI
import AppKit

private func terminateIfAlreadyRunning() {
  let dominated = NSRunningApplication.runningApplications(withBundleIdentifier: Bundle.main.bundleIdentifier ?? "")
    .filter { $0 != NSRunningApplication.current }
  if !dominated.isEmpty {
    NSApp.terminate(nil)
  }
}

class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ notification: Notification) {
    terminateIfAlreadyRunning()
  }
}

@main
struct WebmuxClientApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  @State private var state = AppState()

  var body: some Scene {
    Window("Webmux Setup", id: "setup") {
      SetupView(state: state)
    }
    .windowResizability(.contentSize)
    .windowStyle(.titleBar)

    MenuBarExtra {
      MenuBarView(state: state)
    } label: {
      ZStack(alignment: .topTrailing) {
        Image(systemName: state.allRunning ? "terminal.fill" : "terminal")
        if state.isOutdated {
          Circle()
            .fill(.yellow)
            .frame(width: 6, height: 6)
            .offset(x: 2, y: -2)
        }
      }
    }
    .menuBarExtraStyle(.window)
  }
}
