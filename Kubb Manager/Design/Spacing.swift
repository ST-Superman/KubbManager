//
//  Spacing.swift
//  Kubb Manager
//
//  Centralized spacing system for consistent layout
//

import SwiftUI

/// Spacing system providing consistent padding, margins, and gaps
struct Spacing {

    // MARK: - Base Spacing Scale (8pt grid system)

    /// Extra small spacing (4pt)
    static let xs: CGFloat = 4

    /// Small spacing (8pt)
    static let sm: CGFloat = 8

    /// Medium spacing (12pt)
    static let md: CGFloat = 12

    /// Large spacing (16pt)
    static let lg: CGFloat = 16

    /// Extra large spacing (20pt)
    static let xl: CGFloat = 20

    /// 2X large spacing (24pt)
    static let xxl: CGFloat = 24

    /// 3X large spacing (32pt)
    static let xxxl: CGFloat = 32

    /// 4X large spacing (40pt)
    static let xxxxl: CGFloat = 40

    /// 5X large spacing (48pt)
    static let xxxxxl: CGFloat = 48

    // MARK: - Semantic Spacing

    /// Standard padding for card content
    static let cardPadding: CGFloat = lg

    /// Standard padding for screen edges
    static let screenPadding: CGFloat = lg

    /// Spacing between sections
    static let sectionSpacing: CGFloat = xxl

    /// Spacing between cards in a list
    static let cardSpacing: CGFloat = md

    /// Spacing between elements in a card
    static let elementSpacing: CGFloat = sm

    /// Spacing between related items
    static let itemSpacing: CGFloat = xs

    // MARK: - Button Spacing

    /// Horizontal padding inside buttons
    static let buttonPaddingHorizontal: CGFloat = xl

    /// Vertical padding inside buttons
    static let buttonPaddingVertical: CGFloat = md

    /// Spacing between buttons in a group
    static let buttonGroupSpacing: CGFloat = md

    // MARK: - Icon Sizing

    /// Small icon size
    static let iconSizeSmall: CGFloat = 16

    /// Medium icon size
    static let iconSizeMedium: CGFloat = 24

    /// Large icon size
    static let iconSizeLarge: CGFloat = 32

    /// Extra large icon size
    static let iconSizeXL: CGFloat = 48

    /// Hero icon size
    static let iconSizeHero: CGFloat = 64
}

// MARK: - Spacing View Modifiers

extension View {
    /// Applies standard card padding
    func cardPadding() -> some View {
        self.padding(Spacing.cardPadding)
    }

    /// Applies standard screen edge padding
    func screenPadding() -> some View {
        self.padding(Spacing.screenPadding)
    }

    /// Applies standard card styling
    func cardStyle() -> some View {
        self
            .padding(Spacing.cardPadding)
            .background(AppTheme.cardBackground)
            .cornerRadius(AppTheme.cornerRadiusMedium)
    }

    /// Applies prominent card styling with shadow
    func prominentCardStyle() -> some View {
        self
            .padding(Spacing.cardPadding)
            .background(AppTheme.cardBackground)
            .cornerRadius(AppTheme.cornerRadiusLarge)
            .shadow(color: AppTheme.shadowMedium, radius: 8, x: 0, y: 4)
    }
}

// MARK: - Layout Helpers

struct VStackSpaced<Content: View>: View {
    let spacing: CGFloat
    let content: Content

    init(spacing: CGFloat = Spacing.md, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        VStack(spacing: spacing) {
            content
        }
    }
}

struct HStackSpaced<Content: View>: View {
    let spacing: CGFloat
    let content: Content

    init(spacing: CGFloat = Spacing.md, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        HStack(spacing: spacing) {
            content
        }
    }
}
