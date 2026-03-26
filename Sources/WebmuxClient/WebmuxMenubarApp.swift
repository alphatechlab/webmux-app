import SwiftUI

@main
struct WebmuxClientApp: App {
  @State private var state = AppState()
  @Environment(\.openWindow) private var openWindow

  var body: some Scene {
    Window("Webmux Setup", id: "setup") {
      SetupView(state: state)
    }
    .windowResizability(.contentSize)
    .windowStyle(.titleBar)

    MenuBarExtra {
      MenuBarView(state: state)
        .task {
          await state.bootstrap()
          if state.mode == .setup {
            openWindow(id: "setup")
          }
        }
    } label: {
      Image(systemName: state.allRunning ? "terminal.fill" : "terminal")
    }
    .menuBarExtraStyle(.window)
  }
}
