import SwiftUI

struct StepDoneView: View {
  @Bindable var state: AppState

  var body: some View {
    VStack(spacing: 16) {
      Spacer()

      if state.mode == .running {
        Image(systemName: "checkmark.circle.fill")
          .font(.system(size: 48))
          .foregroundStyle(.green)

        Text("You're all set!")
          .font(.title2.bold())

        Text("Webmux is running. You'll find the icon in your menu bar.")
          .font(.callout)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)

        HStack(spacing: 12) {
          Image(systemName: "terminal.fill")
            .foregroundStyle(.secondary)
          VStack(alignment: .leading) {
            Text("Menu bar")
              .font(.system(size: 12, weight: .medium))
            Text("Control services, check updates, view logs")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 8).fill(.quaternary))

        Button("Open in Browser") {
          state.openInBrowser()
        }
        .controlSize(.large)
        .buttonStyle(.borderedProminent)
      } else {
        ProgressView()
        Text("Setting things up...")
          .font(.callout)
          .foregroundStyle(.secondary)

        if state.hasServices {
          Text("Starting services...")
            .font(.caption)
            .foregroundStyle(.tertiary)
        } else {
          Text("Creating services...")
            .font(.caption)
            .foregroundStyle(.tertiary)
        }
      }

      Spacer()
    }
    .frame(maxWidth: .infinity)
    .padding(20)
  }
}
