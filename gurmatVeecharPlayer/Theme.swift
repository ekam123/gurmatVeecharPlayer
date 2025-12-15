import SwiftUI

struct AppTheme {
    // Color Palette - Blue and Orange
    static let primaryBlue = Color(red: 0.2, green: 0.4, blue: 0.8)
    static let secondaryBlue = Color(red: 0.3, green: 0.5, blue: 0.9)
    static let lightBlue = Color(red: 0.4, green: 0.6, blue: 1.0)

    static let primaryOrange = Color(red: 1.0, green: 0.5, blue: 0.2)
    static let secondaryOrange = Color(red: 1.0, green: 0.6, blue: 0.3)
    static let lightOrange = Color(red: 1.0, green: 0.7, blue: 0.4)

    // Gradient backgrounds
    static let backgroundGradient = LinearGradient(
        gradient: Gradient(colors: [
            primaryBlue.opacity(0.3),
            secondaryBlue.opacity(0.2),
            primaryOrange.opacity(0.1)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardGradient = LinearGradient(
        gradient: Gradient(colors: [
            primaryBlue,
            secondaryOrange
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Glass morphism effect
    struct GlassBackground: View {
        var body: some View {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.1))
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.25),
                                    Color.white.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1.5)
                )
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        }
    }

    struct GlassCard: ViewModifier {
        func body(content: Content) -> some View {
            content
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.15))
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.2),
                                            Color.white.opacity(0.05)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                )
        }
    }
}

extension View {
    func glassCard() -> some View {
        modifier(AppTheme.GlassCard())
    }
}
