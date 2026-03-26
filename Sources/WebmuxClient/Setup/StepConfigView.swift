import SwiftUI

struct StepConfigView: View {
  @Bindable var state: AppState

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("CONFIGURE")
        .font(KG.monoBig)
        .foregroundStyle(KG.cyan)

      Text("Set up your webmux preferences.")
        .font(KG.monoSmall)
        .foregroundStyle(KG.green.opacity(0.6))

      // Projects dir
      VStack(alignment: .leading, spacing: 6) {
        Text("PROJECTS DIRECTORY")
          .font(KG.monoSmall)
          .foregroundStyle(KG.cyan.opacity(0.7))
        Text("Each subdirectory = a terminal session")
          .font(.system(size: 9, design: .monospaced))
          .foregroundStyle(KG.cyan.opacity(0.3))

        HStack {
          TextField("~/GitHub", text: $state.githubDir)
            .font(KG.mono)
            .foregroundStyle(KG.green)
            .textFieldStyle(.plain)
            .padding(6)
            .background(Color.black)
            .neonBorder(KG.cyan.opacity(0.4))

          Button("BROWSE") {
            let panel = NSOpenPanel()
            panel.canChooseDirectories = true
            panel.canChooseFiles = false
            panel.allowsMultipleSelection = false
            panel.directoryURL = URL(fileURLWithPath: state.githubDir.isEmpty
              ? FileManager.default.homeDirectoryForCurrentUser.path
              : state.githubDir)
            if panel.runModal() == .OK, let url = panel.url {
              state.githubDir = url.path
            }
          }
          .buttonStyle(NeonButton())
        }
      }
      .padding(10)
      .background(KG.bgCard)
      .neonBorder()

      // Summary
      VStack(alignment: .leading, spacing: 6) {
        Text("SUMMARY")
          .font(KG.monoSmall)
          .foregroundStyle(KG.cyan.opacity(0.7))

        HStack(spacing: 0) {
          VStack(alignment: .leading, spacing: 4) {
            Text("Server")
            Text("Projects")
            Text("Whisper")
          }
          .font(KG.monoSmall)
          .foregroundStyle(KG.cyan.opacity(0.4))
          .frame(width: 80, alignment: .leading)

          VStack(alignment: .leading, spacing: 4) {
            Text("https://localhost:3030")
            Text(state.githubDir.isEmpty ? "---" : state.githubDir)
            Text(state.hasWhisper ? "ON  (port 8000)" : "OFF")
          }
          .font(KG.monoSmall)
          .foregroundStyle(KG.green)
        }
      }
      .padding(10)
      .background(KG.bgCard)
      .neonBorder()

      Spacer()
    }
    .padding(16)
  }
}
