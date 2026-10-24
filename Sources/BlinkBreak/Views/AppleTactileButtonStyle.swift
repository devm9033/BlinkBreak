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
                    return Color.red.opacity(isPressed ? 0.32 : 0.18)
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
                return isLight ? Color.red : Color(red: 1.0, green: 0.65, blue: 0.65)
            } else {
                return isLight ? Color.primary : Color.white
            }
        }()

        let borderColor: Color = {
            if isDestructive {
                return isLight ? Color.red.opacity(0.25) : Color.red.opacity(0.35)
            } else {
                return isLight ? Color.black.opacity(0.10) : Color.white.opacity(0.20)
            }
        }()

        configuration.label
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundColor(textColor)
            .padding(.horizontal, 18)
            .padding(.vertical, 9)
            .background(
                Capsule()
                    .fill(backgroundFill)
                    .overlay(
                        // Top specular hairline highlight
                        Capsule()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        isLight ? Color.white.opacity(0.60) : Color.white.opacity(0.30),
                                        borderColor
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .opacity(isPressed ? 0.85 : 1.0)
            .animation(.easeOut(duration: 0.12), value: isPressed)
    }
}
