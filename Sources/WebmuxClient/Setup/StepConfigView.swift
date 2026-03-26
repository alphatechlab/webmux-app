import SwiftUI

struct StepConfigView: View {
  @Bindable var state: AppState

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Configure")
        .font(.headline)

      Text("Set up your webmux preferences.")
        .font(.callout)
        .foregroundStyle(.secondary)

      VStack(alignment: .leading, spacing: 8) {
        Text("Projects directory")
          .font(.system(size: 13, weight: .medium))
        Text("Each subdirectory becomes a terminal session in webmux.")
          .font(.caption)
          .foregroundStyle(.secondary)

        HStack {
          TextField("~/GitHub", text: $state.githubDir)
            .textFieldStyle(.roundedBorder)

          Button("Browse...") {
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
        }
      }
      .padding(12)
      .background(RoundedRectangle(cornerRadius: 8).fill(.quaternary))

      VStack(alignment: .leading, spacing: 8) {
        Text("Summary")
          .font(.system(size: 13, weight: .medium))

        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 6) {
          GridRow {
            Text("Server")
              .foregroundStyle(.secondary)
            Text("https://localhost:3030")
          }
          GridRow {
            Text("Projects")
              .foregroundStyle(.secondary)
            Text(state.githubDir.isEmpty ? "Not set" : state.githubDir)
          }
          GridRow {
            Text("Whisper")
              .foregroundStyle(.secondary)
            Text(state.hasWhisper ? "Enabled (port 8000)" : "Disabled")
          }
        }
        .font(.system(size: 12))
      }
      .padding(12)
      .background(RoundedRectangle(cornerRadius: 8).fill(.quaternary))

      Spacer()
    }
    .padding(20)
  }
}
