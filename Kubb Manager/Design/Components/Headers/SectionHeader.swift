//
//  SectionHeader.swift
//  Kubb Manager
//
//  Unified section header component for consistent section titles
//

import SwiftUI

/// A unified section header component for consistent section titles throughout the app
/// Replaces: TrainingHeaderView, GameLogsHeaderView, StatsHeaderView, and custom headers
struct SectionHeader: View {
    let title: String
    let subtitle: String?
    let icon: String?
    let iconColor: Color?
    let action: HeaderAction?

    /// Optional action for interactive headers
    struct HeaderAction {
        let title: String
        let icon: String?
        let action: () -> Void
    }

    init(
        _ title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        iconColor: Color? = nil,
        action: HeaderAction? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.iconColor = iconColor
        self.action = action
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                // Icon (if provided)
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(iconColor ?? AppTheme.primary)
                }

                // Title
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.textPrimary)

                Spacer()

                // Action button (if provided)
                if let action = action {
                    Button(action: action.action) {
                        HStack(spacing: 4) {
                            if let actionIcon = action.icon {
                                Image(systemName: actionIcon)
                                    .font(.subheadline)
                            }
                            Text(action.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(AppTheme.primary)
                    }
                }
            }

            // Subtitle (if provided)
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Convenience Initializers

extension SectionHeader {
    /// Create a simple section header with just a title
    static func simple(_ title: String) -> SectionHeader {
        SectionHeader(title)
    }

    /// Create a section header with title and subtitle
    static func withSubtitle(_ title: String, subtitle: String) -> SectionHeader {
        SectionHeader(title, subtitle: subtitle)
    }

    /// Create a section header with icon
    static func withIcon(
        _ title: String,
        icon: String,
        color: Color = AppTheme.primary,
        subtitle: String? = nil
    ) -> SectionHeader {
        SectionHeader(title, subtitle: subtitle, icon: icon, iconColor: color)
    }

    /// Create an interactive section header with action
    static func withAction(
        _ title: String,
        subtitle: String? = nil,
        actionTitle: String,
        actionIcon: String? = nil,
        action: @escaping () -> Void
    ) -> SectionHeader {
        SectionHeader(
            title,
            subtitle: subtitle,
            action: HeaderAction(title: actionTitle, icon: actionIcon, action: action)
        )
    }
}

// MARK: - Collapsible Section Header

struct CollapsibleSectionHeader: View {
    let title: String
    let icon: String?
    let iconColor: Color?
    @Binding var isExpanded: Bool

    init(
        _ title: String,
        icon: String? = nil,
        iconColor: Color? = nil,
        isExpanded: Binding<Bool>
    ) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self._isExpanded = isExpanded
    }

    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
        }) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.headline)
                        .foregroundColor(iconColor ?? AppTheme.primary)
                }

                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
            }
            .padding(Spacing.md)
            .background(AppTheme.cardBackground)
            .cornerRadius(AppTheme.cornerRadiusMedium)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Card Section Header (for use inside cards)

struct CardSectionHeader: View {
    let title: String
    let icon: String?
    let iconColor: Color?
    let action: SectionHeader.HeaderAction?

    init(
        _ title: String,
        icon: String? = nil,
        iconColor: Color? = nil,
        action: SectionHeader.HeaderAction? = nil
    ) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.action = action
    }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundColor(iconColor ?? AppTheme.primary)
            }

            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.textSecondary)

            Spacer()

            if let action = action {
                Button(action: action.action) {
                    HStack(spacing: 2) {
                        if let actionIcon = action.icon {
                            Image(systemName: actionIcon)
                                .font(.caption)
                        }
                        Text(action.title)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(AppTheme.primary)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Section Headers") {
    ScrollView {
        VStack(spacing: 30) {
            Group {
                Text("Basic Headers").font(.caption).foregroundColor(.secondary)

                SectionHeader.simple("Simple Header")

                SectionHeader.withSubtitle(
                    "Header with Subtitle",
                    subtitle: "This is a descriptive subtitle explaining the section"
                )

                SectionHeader.withIcon(
                    "Header with Icon",
                    icon: "chart.bar.fill",
                    color: .blue
                )
            }

            Divider()

            Group {
                Text("Interactive Headers").font(.caption).foregroundColor(.secondary)

                SectionHeader.withAction(
                    "Personal Records",
                    subtitle: "Your best performances",
                    actionTitle: "View All",
                    actionIcon: "chevron.right"
                ) { }

                CollapsibleSectionHeader(
                    "Collapsible Section",
                    icon: "chart.line.uptrend.xyaxis",
                    iconColor: .blue,
                    isExpanded: .constant(false)
                )

                CollapsibleSectionHeader(
                    "Expanded Section",
                    icon: "flame.fill",
                    iconColor: .orange,
                    isExpanded: .constant(true)
                )
            }

            Divider()

            Group {
                Text("Card Headers").font(.caption).foregroundColor(.secondary)

                VStack(spacing: 12) {
                    CardSectionHeader(
                        "Stats Overview",
                        icon: "chart.bar",
                        iconColor: .blue
                    )

                    Text("Content goes here...")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
                .background(AppTheme.cardBackground)
                .cornerRadius(AppTheme.cornerRadiusMedium)
            }
        }
        .padding()
    }
}
