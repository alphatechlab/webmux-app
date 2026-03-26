import SwiftUI

@main
struct WebmuxClientApp: App {
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
      Image(systemName: state.allRunning ? "terminal.fill" : "terminal")
    }
    .menuBarExtraStyle(.window)
  }
}
