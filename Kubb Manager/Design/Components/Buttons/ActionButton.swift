//
//  ActionButton.swift
//  Kubb Manager
//
//  Unified button component replacing all custom button styles
//

import SwiftUI

/// Unified button style for consistent buttons throughout the app
/// Replaces: PrimaryButtonStyle, ResumeButtonStyle, DeleteButtonStyle, TutorialButtonStyle, etc.
struct ActionButton: View {
    let title: String
    let icon: String?
    let variant: ButtonVariant
    let size: ButtonSize
    let action: () -> Void

    /// Button style variants
    enum ButtonVariant {
        case primary        // Blue, prominent action
        case secondary      // Gray outline, secondary action
        case success        // Green, positive action
        case destructive    // Red, dangerous action
        case warning        // Orange, caution action
        case ghost          // Transparent, minimal action

        var backgroundColor: Color {
            switch self {
            case .primary: return AppTheme.primary
            case .secondary: return Color.clear
            case .success: return AppTheme.success
            case .destructive: return AppTheme.error
            case .warning: return AppTheme.warning
            case .ghost: return Color.clear
            }
        }

        var foregroundColor: Color {
            switch self {
            case .primary, .success, .destructive, .warning:
                return .white
            case .secondary, .ghost:
                return AppTheme.textPrimary
            }
        }

        var borderColor: Color? {
            switch self {
            case .secondary: return AppTheme.textSecondary.opacity(0.3)
            case .ghost: return nil
            default: return nil
            }
        }
    }

    /// Button size variants
    enum ButtonSize {
        case small
        case medium
        case large

        var fontSize: Font {
            switch self {
            case .small: return .subheadline
            case .medium: return .headline
            case .large: return .title3
            }
        }

        var horizontalPadding: CGFloat {
            switch self {
            case .small: return Spacing.md
            case .medium: return Spacing.lg
            case .large: return Spacing.xl
            }
        }

        var verticalPadding: CGFloat {
            switch self {
            case .small: return Spacing.sm
            case .medium: return Spacing.md
            case .large: return Spacing.lg
            }
        }
    }

    init(
        _ title: String,
        icon: String? = nil,
        variant: ButtonVariant = .primary,
        size: ButtonSize = .medium,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.variant = variant
        self.size = size
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(size.fontSize)
                }
                Text(title)
                    .font(size.fontSize)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, size.horizontalPadding)
            .padding(.vertical, size.verticalPadding)
            .foregroundColor(variant.foregroundColor)
            .background(variant.backgroundColor)
            .cornerRadius(AppTheme.cornerRadiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                    .stroke(variant.borderColor ?? Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Scale Button Style (for press animation)

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Convenience Initializers

extension ActionButton {
    /// Create a primary button (most common action)
    static func primary(
        _ title: String,
        icon: String? = nil,
        size: ButtonSize = .medium,
        action: @escaping () -> Void
    ) -> ActionButton {
        ActionButton(title, icon: icon, variant: .primary, size: size, action: action)
    }

    /// Create a secondary button (less prominent action)
    static func secondary(
        _ title: String,
        icon: String? = nil,
        size: ButtonSize = .medium,
        action: @escaping () -> Void
    ) -> ActionButton {
        ActionButton(title, icon: icon, variant: .secondary, size: size, action: action)
    }

    /// Create a destructive button (dangerous action)
    static func destructive(
        _ title: String,
        icon: String? = nil,
        size: ButtonSize = .medium,
        action: @escaping () -> Void
    ) -> ActionButton {
        ActionButton(title, icon: icon, variant: .destructive, size: size, action: action)
    }

    /// Create a success button (positive action)
    static func success(
        _ title: String,
        icon: String? = nil,
        size: ButtonSize = .medium,
        action: @escaping () -> Void
    ) -> ActionButton {
        ActionButton(title, icon: icon, variant: .success, size: size, action: action)
    }
}

// MARK: - ButtonStyle Wrapper (for use with existing Button views)

struct AppButtonStyle: ButtonStyle {
    let variant: ActionButton.ButtonVariant
    let size: ActionButton.ButtonSize

    init(variant: ActionButton.ButtonVariant = .primary, size: ActionButton.ButtonSize = .medium) {
        self.variant = variant
        self.size = size
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(size.fontSize)
            .fontWeight(.semibold)
            .foregroundColor(variant.foregroundColor)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, size.horizontalPadding)
            .padding(.vertical, size.verticalPadding)
            .background(variant.backgroundColor)
            .cornerRadius(AppTheme.cornerRadiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                    .stroke(variant.borderColor ?? Color.clear, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("Action Buttons") {
    VStack(spacing: 20) {
        Group {
            Text("Button Variants").font(.headline)

            ActionButton.primary("Start Practice", icon: "play.fill") { }

            ActionButton.secondary("View History", icon: "clock.arrow.circlepath") { }

            ActionButton.success("Resume Session", icon: "play.circle.fill") { }

            ActionButton.destructive("Delete Session", icon: "trash") { }

            ActionButton("Warning Action", variant: .warning) { }

            ActionButton("Ghost Button", variant: .ghost) { }
        }

        Divider()

        Group {
            Text("Button Sizes").font(.headline)

            ActionButton("Small Button", size: .small) { }

            ActionButton("Medium Button", size: .medium) { }

            ActionButton("Large Button", size: .large) { }
        }

        Divider()

        Group {
            Text("Icon + Text").font(.headline)

            HStack(spacing: 12) {
                ActionButton("Start", icon: "play.fill", size: .small) { }
                ActionButton("Pause", icon: "pause.fill", variant: .warning, size: .small) { }
            }
        }
    }
    .padding()
}
