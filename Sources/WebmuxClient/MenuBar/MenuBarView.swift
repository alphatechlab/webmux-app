import SwiftUI

struct MenuBarView: View {
  @Bindable var state: AppState
  @Environment(\.openWindow) private var openWindow

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      header
      Divider().padding(.vertical, 8)
      servicesSection
      Divider().padding(.vertical, 8)
      projectSection
      if state.isWorking {
        progressSection
      }
      Divider().padding(.vertical, 8)
      actionsSection
    }
    .padding(12)
    .frame(width: 280)
  }

  // MARK: - Header

  private var header: some View {
    HStack {
      Image(systemName: "terminal.fill")
        .foregroundStyle(.secondary)
      Text("Webmux")
        .font(.headline)
      Spacer()
      statusBadge
    }
  }

  private var statusBadge: some View {
    Text(state.allRunning ? "All running" : state.anyRunning ? "Partial" : "Stopped")
      .font(.caption2)
      .padding(.horizontal, 6)
      .padding(.vertical, 2)
      .background(
        Capsule().fill(
          state.allRunning ? Color.green.opacity(0.15) :
          state.anyRunning ? Color.orange.opacity(0.15) :
          Color.red.opacity(0.15)
        )
      )
      .foregroundStyle(
        state.allRunning ? .green :
        state.anyRunning ? .orange :
        .red
      )
  }

  // MARK: - Services

  private var servicesSection: some View {
    VStack(spacing: 6) {
      ServiceRow(
        service: .webmux,
        running: state.webmuxRunning,
        onToggle: { await toggleService(.webmux) },
        onRestart: { await state.restartService(.webmux) }
      )
      ServiceRow(
        service: .whisper,
        running: state.whisperRunning,
        onToggle: { await toggleService(.whisper) },
        onRestart: { await state.restartService(.whisper) }
      )

      HStack(spacing: 8) {
        Button("Start All") { Task { await state.startAll() } }
          .disabled(state.allRunning)
        Button("Stop All") { Task { await state.stopAll() } }
          .disabled(!state.anyRunning)
        Spacer()
      }
      .controlSize(.small)
      .buttonStyle(.bordered)
      .padding(.top, 4)
    }
  }

  private func toggleService(_ service: ServiceLabel) async {
    if state.isRunning(service) {
      await state.stopService(service)
    } else {
      await state.startService(service)
    }
  }

  // MARK: - Project

  private var projectSection: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack(spacing: 4) {
        Image(systemName: "checkmark.circle.fill")
          .foregroundStyle(.green)
          .font(.caption)
        Text("Installed")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      if state.isOutdated {
        HStack {
          Image(systemName: "arrow.up.circle.fill")
            .foregroundStyle(.blue)
            .font(.caption)
          Text("Update available")
            .font(.caption)
            .foregroundStyle(.secondary)
          Spacer()
          Button("Update") { Task { await state.runUpdate() } }
            .controlSize(.small)
            .buttonStyle(.borderedProminent)
            .disabled(state.isWorking)
        }
      } else {
        HStack(spacing: 6) {
          if state.isChecking {
            ProgressView()
              .controlSize(.small)
            Text("Checking...")
              .font(.caption)
              .foregroundStyle(.secondary)
          } else {
            Button("Check for updates") { Task { await state.checkForUpdates() } }
              .controlSize(.mini)
              .disabled(state.isWorking)
            if !state.lastCheckMessage.isEmpty {
              Text(state.lastCheckMessage)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          }
        }
      }
    }
  }

  // MARK: - Progress

  private var progressSection: some View {
    HStack(spacing: 6) {
      ProgressView()
        .controlSize(.small)
      Text(state.workMessage)
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(3)
      Spacer()
    }
    .padding(.top, 6)
  }

  // MARK: - Actions

  private var actionsSection: some View {
    HStack(spacing: 8) {
      Button { state.openInBrowser() } label: {
        Label("Browser", systemImage: "globe")
      }
      .controlSize(.small)

      Menu {
        ForEach(ServiceLabel.allCases, id: \.self) { service in
          Section(service.displayName) {
            ForEach(service.logPaths, id: \.self) { path in
              Button((path as NSString).lastPathComponent) {
                state.openLog(path)
              }
            }
          }
        }
      } label: {
        Label("Logs", systemImage: "doc.text")
      }
      .controlSize(.small)

      Spacer()

      Button {
        openWindow(id: "setup")
      } label: {
        Image(systemName: "gear")
      }
      .controlSize(.small)
      .help("Setup")

      Button {
        NSApp.terminate(nil)
      } label: {
        Label("Quit", systemImage: "power")
      }
      .controlSize(.small)
    }
    .buttonStyle(.bordered)
  }
}

// MARK: - ServiceRow

struct ServiceRow: View {
  let service: ServiceLabel
  let running: Bool
  let onToggle: () async -> Void
  let onRestart: () async -> Void

  var body: some View {
    HStack(spacing: 8) {
      Circle()
        .fill(running ? Color.green : Color.red.opacity(0.5))
        .frame(width: 8, height: 8)

      VStack(alignment: .leading, spacing: 0) {
        Text(service.displayName)
          .font(.system(size: 12, weight: .medium))
        Text("Port \(service.port)")
          .font(.system(size: 10))
          .foregroundStyle(.tertiary)
      }

      Spacer()

      Button { Task { await onRestart() } } label: {
        Image(systemName: "arrow.clockwise")
          .font(.system(size: 10))
      }
      .buttonStyle(.borderless)
      .disabled(!running)
      .help("Restart")

      Toggle("", isOn: Binding(
        get: { running },
        set: { _ in Task { await onToggle() } }
      ))
      .toggleStyle(.switch)
      .controlSize(.mini)
      .labelsHidden()
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 6)
    .background(RoundedRectangle(cornerRadius: 6).fill(.quaternary))
  }
}
