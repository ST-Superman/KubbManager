//
//  AppTheme.swift
//  Kubb Manager
//
//  Centralized design system for consistent colors, spacing, and styling
//

import SwiftUI

/// Central theme configuration for the Kubb Manager app
/// Provides consistent colors, spacing, and styling across all views
struct AppTheme {

    // MARK: - Brand Colors

    /// Primary brand color used for main actions and highlights
    static let primary = Color.blue

    /// Success color for positive actions and achievements
    static let success = Color.green

    /// Warning color for caution states
    static let warning = Color.orange

    /// Error/destructive color for dangerous actions
    static let error = Color.red

    /// Accent color for special highlights
    static let accent = Color.purple

    // MARK: - Surface Colors

    /// Background color for cards and elevated surfaces
    static let cardBackground = Color(.systemGray6)

    /// Main surface background color
    static let surface = Color(.systemBackground)

    /// Secondary surface background
    static let secondarySurface = Color(.systemGray5)

    // MARK: - Semantic Colors

    /// Color for accuracy-related metrics
    static let accuracy = Color.green

    /// Color for target/goal indicators
    static let target = Color.blue

    /// Color for streak indicators
    static let streak = Color.orange

    /// Color for trophy/achievement indicators
    static let trophy = Color.yellow

    /// Color for clutch/pressure performance
    static let clutch = Color.red

    /// Color for consistency metrics
    static let consistency = Color.purple

    // MARK: - Text Colors

    /// Primary text color
    static let textPrimary = Color.primary

    /// Secondary text color
    static let textSecondary = Color.secondary

    /// Tertiary text color
    static let textTertiary = Color(.tertiaryLabel)

    // MARK: - Corner Radius

    /// Small corner radius for compact elements
    static let cornerRadiusSmall: CGFloat = 8

    /// Medium corner radius for standard cards
    static let cornerRadiusMedium: CGFloat = 12

    /// Large corner radius for prominent elements
    static let cornerRadiusLarge: CGFloat = 16

    /// Extra large corner radius for hero elements
    static let cornerRadiusXL: CGFloat = 20

    // MARK: - Shadows

    /// Light shadow for subtle elevation
    static let shadowLight = Color.black.opacity(0.05)

    /// Medium shadow for standard elevation
    static let shadowMedium = Color.black.opacity(0.1)

    /// Strong shadow for high elevation
    static let shadowStrong = Color.black.opacity(0.15)

    // MARK: - Training Mode Colors

    /// Color for Standard 8-Meter Practice
    static let eightMeterTraining = Color.blue

    /// Color for Inkast & Blast
    static let inkastBlast = Color.orange

    /// Color for Full Game Sim
    static let fullGameSim = Color.purple

    /// Color for Baseball Kubb
    static let baseballKubb = Color.green

    /// Color for Traditional Kubb
    static let traditionalKubb = Color.red

    // MARK: - Game Phase Colors (for Inkast & Blast)

    /// Color for Early Game phase (1-3 kubbs)
    static let phaseEarly = Color.green

    /// Color for Mid Game phase (4-7 kubbs)
    static let phaseMid = Color.orange

    /// Color for End Game phase (8-10 kubbs)
    static let phaseEnd = Color.red

    // MARK: - Status Colors

    /// Color for active/in-progress states
    static let statusActive = Color.green

    /// Color for incomplete/paused states
    static let statusIncomplete = Color.orange

    /// Color for completed states
    static let statusCompleted = Color.blue

    // MARK: - Gradient Definitions

    /// Success gradient for achievements
    static let successGradient = LinearGradient(
        colors: [Color.green, Color.green.opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Warning gradient for caution states
    static let warningGradient = LinearGradient(
        colors: [Color.orange, Color.yellow],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Trophy gradient for records and achievements
    static let trophyGradient = LinearGradient(
        colors: [Color.yellow, Color.orange],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Primary gradient for hero elements
    static let primaryGradient = LinearGradient(
        colors: [Color.blue, Color.blue.opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Color Extensions

extension Color {
    /// Creates a color with adjusted opacity
    func withOpacity(_ opacity: Double) -> Color {
        return self.opacity(opacity)
    }
}
