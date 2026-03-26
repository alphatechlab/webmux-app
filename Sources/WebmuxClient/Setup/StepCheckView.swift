import SwiftUI

struct StepCheckView: View {
  @Bindable var state: AppState

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Checking your system")
        .font(.headline)

      Text("Webmux needs a few tools to run. Let's see what's already installed.")
        .font(.callout)
        .foregroundStyle(.secondary)

      VStack(spacing: 8) {
        DepRow(
          name: "Homebrew",
          detail: "Package manager",
          installed: state.hasHomebrew,
          required: true
        )
        DepRow(
          name: "Node.js",
          detail: state.nodeVersion.isEmpty ? "JavaScript runtime" : state.nodeVersion,
          installed: state.hasNode,
          required: true
        )
        DepRow(
          name: "Rust",
          detail: state.rustVersion.isEmpty ? "For sidecar build" : state.rustVersion,
          installed: state.hasRust,
          required: true
        )
        DepRow(
          name: "Python 3",
          detail: "For Whisper (optional)",
          installed: state.hasPython,
          required: false
        )

        Divider().padding(.vertical, 4)

        DepRow(
          name: "webmux",
          detail: state.hasWebmux ? "Installed via Homebrew" : "Not installed",
          installed: state.hasWebmux,
          required: true
        )
        DepRow(
          name: "Whisper",
          detail: "Voice input (optional)",
          installed: state.hasWhisper,
          required: false
        )
      }
      .padding(12)
      .background(RoundedRectangle(cornerRadius: 8).fill(.quaternary))

      if !state.hasHomebrew || !state.hasNode || !state.hasRust {
        HStack(spacing: 6) {
          Image(systemName: "exclamationmark.triangle.fill")
            .foregroundStyle(.orange)
          Text("Missing required dependencies. Install them first, then recheck.")
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Button("Recheck") {
          Task { await state.checkDependencies() }
        }
        .controlSize(.small)
      }

      Spacer()
    }
    .padding(20)
  }
}

struct DepRow: View {
  let name: String
  let detail: String
  let installed: Bool
  let required: Bool

  var body: some View {
    HStack {
      Image(systemName: installed ? "checkmark.circle.fill" : "circle")
        .foregroundStyle(installed ? .green : required ? .red.opacity(0.6) : .secondary)
        .font(.system(size: 14))

      VStack(alignment: .leading, spacing: 0) {
        HStack(spacing: 4) {
          Text(name)
            .font(.system(size: 13, weight: .medium))
          if !required {
            Text("optional")
              .font(.system(size: 10))
              .foregroundStyle(.secondary)
              .padding(.horizontal, 4)
              .padding(.vertical, 1)
              .background(Capsule().fill(.quaternary))
          }
        }
        Text(detail)
          .font(.system(size: 11))
          .foregroundStyle(.tertiary)
      }

      Spacer()
    }
  }
}
