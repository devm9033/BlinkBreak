import SwiftUI

public struct AppleTactileButtonStyle: ButtonStyle {
    public var isDestructive: Bool = false
    @Environment(\.colorScheme) var colorScheme

    public init(isDestructive: Bool = false) {
        self.isDestructive = isDestructive
    }

    private var isLight: Bool {
        colorScheme == .light
    }

    public func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed

        let backgroundFill: Color = {
            if isDestructive {
                if isLight {
                    return Color.red.opacity(isPressed ? 0.22 : 0.12)
                } else {
                    return Color.red.opacity(isPressed ? 0.45 : 0.30)
                }
            } else {
                if isLight {
                    return Color.black.opacity(isPressed ? 0.12 : 0.06)
                } else {
                    return Color.white.opacity(isPressed ? 0.22 : 0.12)
                }
            }
        }()

        let textColor: Color = {
            if isDestructive {
                return isLight ? Color.red : Color.white
            } else {
                return isLight ? Color.primary : Color.white
            }
        }()

        let borderColor: Color = {
            if isLight {
                return Color.black.opacity(isPressed ? 0.15 : 0.08)
            } else {
                return Color.white.opacity(isPressed ? 0.25 : 0.12)
            }
        }()

        configuration.label
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundColor(textColor)
            .padding(.horizontal, 18)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(backgroundFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .opacity(isPressed ? 0.88 : 1.0)
            .animation(.easeOut(duration: 0.12), value: isPressed)
    }
}
