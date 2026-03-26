import SwiftUI

enum KG {
  // Neon palette
  static let cyan = Color(red: 0, green: 1, blue: 1)
  static let green = Color(red: 0, green: 1, blue: 0)
  static let magenta = Color(red: 1, green: 0, blue: 1)
  static let pink = Color(red: 1, green: 0.2, blue: 0.6)
  static let purple = Color(red: 0.6, green: 0.2, blue: 1)
  static let yellow = Color(red: 1, green: 1, blue: 0)
  static let bg = Color(red: 0.02, green: 0.02, blue: 0.06)
  static let bgCard = Color(red: 0.06, green: 0.06, blue: 0.12)
  static let border = Color(red: 0, green: 0.8, blue: 0.8).opacity(0.4)

  static let mono = Font.system(size: 12, design: .monospaced)
  static let monoSmall = Font.system(size: 10, design: .monospaced)
  static let monoBig = Font.system(size: 14, weight: .bold, design: .monospaced)
  static let monoTitle = Font.system(size: 18, weight: .heavy, design: .monospaced)
}

struct NeonBorder: ViewModifier {
  var color: Color = KG.border

  func body(content: Content) -> some View {
    content
      .overlay(RoundedRectangle(cornerRadius: 4).stroke(color, lineWidth: 1))
  }
}

struct NeonButton: ButtonStyle {
  var color: Color = KG.cyan

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(KG.mono)
      .foregroundStyle(configuration.isPressed ? color.opacity(0.6) : color)
      .padding(.horizontal, 12)
      .padding(.vertical, 6)
      .background(color.opacity(configuration.isPressed ? 0.15 : 0.08))
      .overlay(RoundedRectangle(cornerRadius: 4).stroke(color.opacity(0.6), lineWidth: 1))
      .cornerRadius(4)
  }
}

struct NeonAccentButton: ButtonStyle {
  var color: Color = KG.magenta

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(KG.mono)
      .foregroundStyle(.black)
      .padding(.horizontal, 14)
      .padding(.vertical, 6)
      .background(configuration.isPressed ? color.opacity(0.7) : color)
      .cornerRadius(4)
      .shadow(color: color.opacity(0.5), radius: 6)
  }
}

struct NeonToggleStyle: ToggleStyle {
  var color: Color = KG.cyan

  func makeBody(configuration: Configuration) -> some View {
    HStack(spacing: 6) {
      Text(configuration.isOn ? "[x]" : "[ ]")
        .font(.system(size: 12, weight: .bold, design: .monospaced))
        .foregroundStyle(configuration.isOn ? color : color.opacity(0.3))
        .onTapGesture { configuration.isOn.toggle() }
      configuration.label
    }
  }
}

extension View {
  func neonBorder(_ color: Color = KG.border) -> some View {
    modifier(NeonBorder(color: color))
  }
}
