import SwiftUI

struct SetupView: View {
  @Bindable var state: AppState
  @Environment(\.dismissWindow) private var dismissWindow

  var body: some View {
    VStack(spacing: 0) {
      header
      Divider()
      stepContent
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      Divider()
      footer
    }
    .frame(width: 520, height: 440)
  }

  // MARK: - Header

  private var header: some View {
    VStack(spacing: 8) {
      Image(systemName: "terminal.fill")
        .font(.system(size: 32))
        .foregroundStyle(.tint)
      Text("Webmux Setup")
        .font(.title2.bold())
      StepIndicator(current: state.setupStep)
    }
    .padding(.vertical, 16)
    .frame(maxWidth: .infinity)
    .background(.bar)
  }

  // MARK: - Steps

  @ViewBuilder
  private var stepContent: some View {
    switch state.setupStep {
    case .check:
      StepCheckView(state: state)
    case .install:
      StepInstallView(state: state)
    case .configure:
      StepConfigView(state: state)
    case .done:
      StepDoneView(state: state)
    }
  }

  // MARK: - Footer

  private var footer: some View {
    HStack {
      if state.setupStep != .check {
        Button("Back") {
          withAnimation {
            let raw = state.setupStep.rawValue - 1
            if let prev = AppState.SetupStep(rawValue: raw) {
              state.setupStep = prev
            }
          }
        }
        .disabled(state.isInstalling)
      }

      Spacer()

      switch state.setupStep {
      case .check:
        Button("Continue") {
          withAnimation {
            if state.hasWebmux {
              state.setupStep = .configure
            } else {
              state.setupStep = .install
            }
          }
        }
        .buttonStyle(.borderedProminent)
        .disabled(!state.hasHomebrew && !state.hasNode)

      case .install:
        if !state.hasWebmux {
          Button("Install") {
            Task { await state.runInstall() }
          }
          .buttonStyle(.borderedProminent)
          .disabled(state.isInstalling)
        } else {
          Button("Continue") {
            withAnimation { state.setupStep = .configure }
          }
          .buttonStyle(.borderedProminent)
        }

      case .configure:
        Button("Finish Setup") {
          withAnimation { state.setupStep = .done }
          Task { await state.finishSetup() }
        }
        .buttonStyle(.borderedProminent)
        .disabled(state.githubDir.isEmpty)

      case .done:
        Button("Close") {
          dismissWindow(id: "setup")
        }
        .buttonStyle(.borderedProminent)
        .disabled(state.mode != .running)
      }
    }
    .padding(16)
    .background(.bar)
  }
}

// MARK: - Step Indicator

struct StepIndicator: View {
  let current: AppState.SetupStep

  var body: some View {
    HStack(spacing: 4) {
      ForEach(AppState.SetupStep.allCases, id: \.rawValue) { step in
        HStack(spacing: 4) {
          Circle()
            .fill(step.rawValue <= current.rawValue ? Color.accentColor : Color.secondary.opacity(0.3))
            .frame(width: 8, height: 8)
          Text(step.title)
            .font(.caption)
            .foregroundStyle(step == current ? .primary : .secondary)
        }
        if step != AppState.SetupStep.allCases.last {
          Rectangle()
            .fill(step.rawValue < current.rawValue ? Color.accentColor : Color.secondary.opacity(0.3))
            .frame(width: 24, height: 1)
        }
      }
    }
  }
}
