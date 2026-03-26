import SwiftUI

struct StepInstallView: View {
  @Bindable var state: AppState
  @State private var copied = false

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("INSTALL")
        .font(KG.monoBig)
        .foregroundStyle(KG.cyan)

      Text("Installing webmux via Homebrew. Compiling sidecar from source...")
        .font(KG.monoSmall)
        .foregroundStyle(KG.green.opacity(0.6))
        .fixedSize(horizontal: false, vertical: true)

      if state.hasPython {
        Toggle("Also install Whisper (voice input)", isOn: $state.installWhisperOption)
          .toggleStyle(NeonToggleStyle())
          .font(KG.monoSmall)
          .foregroundStyle(KG.cyan.opacity(0.7))
      }

      // Terminal log
      ZStack(alignment: .topTrailing) {
        logArea
        if !state.installLog.isEmpty {
          logActions.padding(6)
        }
      }
      .frame(maxHeight: .infinity)

      // Status
      statusBar
    }
    .padding(16)
  }

  @ViewBuilder
  private var logArea: some View {
    if !state.installLog.isEmpty {
      ScrollViewReader { proxy in
        ScrollView {
          Text(state.installLog)
            .font(.system(size: 10, design: .monospaced))
            .foregroundStyle(KG.green)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
            .padding(.top, 20)
          Color.clear.frame(height: 1).id("bottom")
        }
        .background(
          RoundedRectangle(cornerRadius: 4)
            .fill(Color.black)
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(KG.green.opacity(0.3), lineWidth: 1))
        )
        .onChange(of: state.installLog) {
          withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
        }
      }
    } else {
      VStack(spacing: 8) {
        Text(">_")
          .font(.system(size: 32, weight: .bold, design: .monospaced))
          .foregroundStyle(KG.cyan.opacity(0.3))
        Text("Ready to install")
          .font(KG.monoSmall)
          .foregroundStyle(KG.cyan.opacity(0.3))
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(
        RoundedRectangle(cornerRadius: 4)
          .fill(Color.black)
          .overlay(RoundedRectangle(cornerRadius: 4).stroke(KG.cyan.opacity(0.15), lineWidth: 1))
      )
    }
  }

  private var logActions: some View {
    HStack(spacing: 4) {
      Button {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(state.installLog, forType: .string)
        copied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
      } label: {
        Text(copied ? "OK" : "CP")
          .font(.system(size: 9, weight: .bold, design: .monospaced))
      }
      .buttonStyle(NeonButton(color: KG.green))
      .help("Copy logs")

      Button {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "webmux-install.log"
        panel.allowedContentTypes = [.plainText]
        if panel.runModal() == .OK, let url = panel.url {
          try? state.installLog.write(to: url, atomically: true, encoding: .utf8)
        }
      } label: {
        Text("SAVE")
          .font(.system(size: 9, weight: .bold, design: .monospaced))
      }
      .buttonStyle(NeonButton(color: KG.green))
      .help("Save logs to file")
    }
  }

  private var statusBar: some View {
    HStack(spacing: 6) {
      if state.isInstalling {
        ProgressView()
          .controlSize(.small)
          .tint(KG.cyan)
        Text("INSTALLING...")
          .font(KG.monoSmall)
          .foregroundStyle(KG.cyan)
      } else if state.installFailed {
        Text("[FAIL]")
          .font(KG.mono)
          .foregroundStyle(KG.pink)
        Text("Installation failed.")
          .font(KG.monoSmall)
          .foregroundStyle(KG.pink.opacity(0.7))
        Spacer()
        Button("RETRY") { Task { await state.runInstall() } }
          .buttonStyle(NeonButton(color: KG.pink))
      } else if state.hasWebmux {
        Text("[DONE]")
          .font(KG.mono)
          .foregroundStyle(KG.green)
        Text("webmux installed successfully.")
          .font(KG.monoSmall)
          .foregroundStyle(KG.green.opacity(0.7))
      }
      Spacer()
    }
  }
}
