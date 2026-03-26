import SwiftUI

struct StepInstallView: View {
  @Bindable var state: AppState

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Install webmux")
        .font(.headline)

      Text("This will install webmux using Homebrew. The sidecar (Rust) will be compiled during installation — this may take a few minutes.")
        .font(.callout)
        .foregroundStyle(.secondary)

      if state.hasPython {
        Toggle("Also install Whisper (voice input)", isOn: $state.installWhisperOption)
          .font(.callout)
      }

      if !state.installLog.isEmpty {
        ScrollViewReader { proxy in
          ScrollView {
            Text(state.installLog)
              .font(.system(size: 11, design: .monospaced))
              .foregroundStyle(.primary)
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(8)
              .id("log")
          }
          .background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.8)))
          .frame(maxHeight: .infinity)
          .onChange(of: state.installLog) {
            withAnimation { proxy.scrollTo("log", anchor: .bottom) }
          }
        }
      } else {
        Spacer()

        VStack(spacing: 8) {
          Image(systemName: "shippingbox")
            .font(.system(size: 40))
            .foregroundStyle(.secondary)
          Text("Ready to install")
            .font(.callout)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      }

      if state.isInstalling {
        HStack {
          ProgressView()
            .controlSize(.small)
          Text("Installing...")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }

      if state.installFailed {
        HStack(spacing: 6) {
          Image(systemName: "xmark.circle.fill")
            .foregroundStyle(.red)
          Text("Installation failed. Check the log above.")
            .font(.caption)
            .foregroundStyle(.secondary)
          Spacer()
          Button("Retry") { Task { await state.runInstall() } }
            .controlSize(.small)
        }
      }
    }
    .padding(20)
  }
}
