//
//  StatCard.swift
//  Kubb Manager
//
//  Unified card component for displaying statistics throughout the app
//

import SwiftUI

/// A unified card component for displaying statistics
/// Replaces: RecordHighlightCard, QuickStatItem, PhaseCard, and custom stat cards
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let subtitle: String?
    let trend: TrendIndicator?
    let size: CardSize

    /// Card size variants
    enum CardSize {
        case small      // Compact, for grids
        case medium     // Standard size
        case large      // Prominent display
    }

    /// Trend indicator for showing change over time
    enum TrendIndicator {
        case up(String)         // Improving (value)
        case down(String)       // Declining (value)
        case stable(String)     // No change (value)

        var icon: String {
            switch self {
            case .up: return "arrow.up"
            case .down: return "arrow.down"
            case .stable: return "arrow.forward"
            }
        }

        var color: Color {
            switch self {
            case .up: return AppTheme.success
            case .down: return AppTheme.error
            case .stable: return AppTheme.textSecondary
            }
        }

        var value: String {
            switch self {
            case .up(let val), .down(let val), .stable(let val):
                return val
            }
        }
    }

    init(
        title: String,
        value: String,
        icon: String,
        color: Color,
        subtitle: String? = nil,
        trend: TrendIndicator? = nil,
        size: CardSize = .medium
    ) {
        self.title = title
        self.value = value
        self.icon = icon
        self.color = color
        self.subtitle = subtitle
        self.trend = trend
        self.size = size
    }

    var body: some View {
        VStack(spacing: cardSpacing) {
            // Icon
            Image(systemName: icon)
                .font(iconFont)
                .foregroundColor(color)

            // Value
            Text(value)
                .font(valueFont)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.textPrimary)
                .monospacedDigit()

            // Title
            Text(title)
                .font(titleFont)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            // Subtitle (optional)
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(AppTheme.textTertiary)
                    .multilineTextAlignment(.center)
            }

            // Trend indicator (optional)
            if let trend = trend {
                HStack(spacing: 4) {
                    Image(systemName: trend.icon)
                        .font(.caption2)
                    Text(trend.value)
                        .font(.caption2)
                }
                .foregroundColor(trend.color)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(cardPadding)
        .background(AppTheme.surface)
        .cornerRadius(AppTheme.cornerRadiusMedium)
        .shadow(color: AppTheme.shadowLight, radius: 2, x: 0, y: 1)
    }

    // MARK: - Size-based Properties

    private var iconFont: Font {
        switch size {
        case .small: return .title3
        case .medium: return .title2
        case .large: return .largeTitle
        }
    }

    private var valueFont: Font {
        switch size {
        case .small: return .title3
        case .medium: return .title2
        case .large: return .largeTitle
        }
    }

    private var titleFont: Font {
        switch size {
        case .small: return .caption
        case .medium: return .caption
        case .large: return .subheadline
        }
    }

    private var cardSpacing: CGFloat {
        switch size {
        case .small: return Spacing.xs
        case .medium: return Spacing.sm
        case .large: return Spacing.md
        }
    }

    private var cardPadding: CGFloat {
        switch size {
        case .small: return Spacing.sm
        case .medium: return Spacing.md
        case .large: return Spacing.lg
        }
    }
}

// MARK: - Convenience Initializers

extension StatCard {
    /// Create a simple stat card without subtitle or trend
    static func simple(
        title: String,
        value: String,
        icon: String,
        color: Color,
        size: CardSize = .medium
    ) -> StatCard {
        StatCard(
            title: title,
            value: value,
            icon: icon,
            color: color,
            size: size
        )
    }

    /// Create a stat card with trend indicator
    static func withTrend(
        title: String,
        value: String,
        icon: String,
        color: Color,
        trend: TrendIndicator,
        size: CardSize = .medium
    ) -> StatCard {
        StatCard(
            title: title,
            value: value,
            icon: icon,
            color: color,
            trend: trend,
            size: size
        )
    }
}

// MARK: - Specialized Stat Cards

extension StatCard {
    /// Create an accuracy stat card
    static func accuracy(
        value: Double,
        subtitle: String? = nil,
        trend: TrendIndicator? = nil
    ) -> StatCard {
        StatCard(
            title: "Accuracy",
            value: String(format: "%.1f%%", value * 100),
            icon: "target",
            color: AppTheme.accuracy,
            subtitle: subtitle,
            trend: trend
        )
    }

    /// Create a streak stat card
    static func streak(
        value: Int,
        subtitle: String? = nil
    ) -> StatCard {
        StatCard(
            title: "Streak",
            value: "\(value)",
            icon: "flame.fill",
            color: AppTheme.streak,
            subtitle: subtitle
        )
    }

    /// Create a perfect rounds stat card
    static func perfectRounds(
        value: Int
    ) -> StatCard {
        StatCard(
            title: "Perfect Rounds",
            value: "\(value)",
            icon: "sparkles",
            color: AppTheme.accent,
            subtitle: nil
        )
    }

    /// Create a total batons stat card
    static func totalBatons(
        value: Int,
        subtitle: String? = nil
    ) -> StatCard {
        StatCard(
            title: "Total Batons",
            value: "\(value)",
            icon: "figure.walk",
            color: AppTheme.primary,
            subtitle: subtitle
        )
    }

    /// Create a handicap stat card
    static func handicap(
        value: Double,
        subtitle: String? = nil
    ) -> StatCard {
        let color: Color = value < 0 ? AppTheme.success : value > 0 ? AppTheme.warning : AppTheme.textSecondary
        return StatCard(
            title: "Handicap",
            value: String(format: "%+.1f", value),
            icon: "chart.line.uptrend.xyaxis",
            color: color,
            subtitle: subtitle
        )
    }

    /// Create a sessions count stat card
    static func sessionsCount(
        value: Int,
        sessionType: String
    ) -> StatCard {
        StatCard(
            title: sessionType,
            value: "\(value)",
            icon: "calendar",
            color: AppTheme.primary,
            subtitle: value == 1 ? "session" : "sessions"
        )
    }
}

// MARK: - Preview

#Preview("Stat Card Sizes") {
    VStack(spacing: 20) {
        HStack(spacing: 12) {
            StatCard.accuracy(value: 0.825, size: .small)
            StatCard.streak(value: 12, size: .small)
            StatCard.perfectRounds(value: 5)
        }

        HStack(spacing: 12) {
            StatCard.accuracy(
                value: 0.825,
                trend: .up("+3.2%")
            )
            StatCard.totalBatons(
                value: 2540,
                subtitle: "All Time"
            )
        }

        StatCard.handicap(
            value: -2.5,
            subtitle: "Recent Sessions"
        )
    }
    .padding()
}
