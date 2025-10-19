//
//  Typography.swift
//  Kubb Manager
//
//  Centralized typography system for consistent text styling
//

import SwiftUI

/// Typography system providing consistent text styles across the app
struct Typography {

    // MARK: - Display Styles (Large, attention-grabbing)

    /// Extra large display text (for hero sections)
    static func displayXL(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 48, weight: .bold, design: .rounded))
    }

    /// Large display text (for prominent headers)
    static func displayLarge(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 36, weight: .bold, design: .rounded))
    }

    /// Medium display text
    static func displayMedium(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 28, weight: .semibold, design: .rounded))
    }

    // MARK: - Heading Styles

    /// H1 heading (page titles)
    static func h1(_ text: String) -> some View {
        Text(text)
            .font(.title)
            .fontWeight(.bold)
    }

    /// H2 heading (section titles)
    static func h2(_ text: String) -> some View {
        Text(text)
            .font(.title2)
            .fontWeight(.semibold)
    }

    /// H3 heading (subsection titles)
    static func h3(_ text: String) -> some View {
        Text(text)
            .font(.title3)
            .fontWeight(.semibold)
    }

    /// H4 heading (card titles)
    static func h4(_ text: String) -> some View {
        Text(text)
            .font(.headline)
            .fontWeight(.semibold)
    }

    // MARK: - Body Text Styles

    /// Body text (standard reading text)
    static func body(_ text: String) -> some View {
        Text(text)
            .font(.body)
    }

    /// Body emphasized (slightly bolder body text)
    static func bodyEmphasized(_ text: String) -> some View {
        Text(text)
            .font(.body)
            .fontWeight(.medium)
    }

    /// Body large (larger body text for readability)
    static func bodyLarge(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 18))
    }

    // MARK: - Secondary Text Styles

    /// Subheadline (supporting text)
    static func subheadline(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundColor(AppTheme.textSecondary)
    }

    /// Caption (small supporting text)
    static func caption(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundColor(AppTheme.textSecondary)
    }

    /// Caption emphasized
    static func captionEmphasized(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(AppTheme.textSecondary)
    }

    /// Fine print (smallest text)
    static func finePrint(_ text: String) -> some View {
        Text(text)
            .font(.caption2)
            .foregroundColor(AppTheme.textTertiary)
    }

    // MARK: - Numeric Display Styles (for statistics)

    /// Large numeric display (for hero stats)
    static func numericHero(_ value: String) -> some View {
        Text(value)
            .font(.system(size: 48, weight: .bold, design: .rounded))
            .monospacedDigit()
    }

    /// Large numeric display
    static func numericLarge(_ value: String) -> some View {
        Text(value)
            .font(.system(size: 36, weight: .bold, design: .rounded))
            .monospacedDigit()
    }

    /// Medium numeric display
    static func numericMedium(_ value: String) -> some View {
        Text(value)
            .font(.system(size: 24, weight: .semibold, design: .rounded))
            .monospacedDigit()
    }

    /// Standard numeric display
    static func numeric(_ value: String) -> some View {
        Text(value)
            .font(.system(size: 18, weight: .medium, design: .rounded))
            .monospacedDigit()
    }

    /// Small numeric display
    static func numericSmall(_ value: String) -> some View {
        Text(value)
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .monospacedDigit()
    }

    // MARK: - Button Text Styles

    /// Primary button text
    static func buttonPrimary(_ text: String) -> some View {
        Text(text)
            .font(.headline)
            .fontWeight(.semibold)
    }

    /// Secondary button text
    static func buttonSecondary(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .fontWeight(.medium)
    }

    // MARK: - Label Styles

    /// Small label (for form fields)
    static func label(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(AppTheme.textSecondary)
    }

    /// Label emphasized
    static func labelEmphasized(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .fontWeight(.semibold)
    }
}

// MARK: - Text Style View Modifiers

struct HeadingStyle: ViewModifier {
    let level: Int

    func body(content: Content) -> some View {
        switch level {
        case 1:
            content
                .font(.title)
                .fontWeight(.bold)
        case 2:
            content
                .font(.title2)
                .fontWeight(.semibold)
        case 3:
            content
                .font(.title3)
                .fontWeight(.semibold)
        default:
            content
                .font(.headline)
                .fontWeight(.semibold)
        }
    }
}

extension View {
    /// Applies a heading style at the specified level
    func headingStyle(level: Int = 1) -> some View {
        modifier(HeadingStyle(level: level))
    }
}
