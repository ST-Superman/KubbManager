//
//  LandingPageViewRedesigned.swift
//  Kubb Manager
//
//  Redesigned landing page using the new design system
//  Features improved visual hierarchy, modern card-based layout, and better CTAs
//

import SwiftUI

// MARK: - Redesigned Landing Page

struct LandingPageViewRedesigned: View {
    @Binding var showingMainApp: Bool
    @Binding var selectedTab: Int
    @State private var showingOptions = false
    @StateObject private var settingsManager = SettingsManager.shared
    @StateObject private var statsManager = UnifiedStatisticsManager.shared

    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: Spacing.sectionSpacing) {
                    // Hero Section
                    heroSection

                    // Quick Stats Overview
                    quickStatsSection

                    // Primary Actions
                    primaryActionsSection

                    // Debug Section (if enabled)
                    if settingsManager.showDebugTools {
                        debugSection
                    }
                }
                .padding(Spacing.screenPadding)
            }
            .navigationTitle("Kubb Manager")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(trailing: Button("Options") {
                showingOptions = true
            })
        }
        .sheet(isPresented: $showingOptions) {
            OptionsView()
                .environmentObject(settingsManager)
        }
        .onAppear {
            Task {
                await statsManager.loadAllSessionsIfNeeded()
            }
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: Spacing.lg) {
            // App Icon
            Image("kubb1024")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .shadow(color: AppTheme.shadow, radius: 8, y: 4)

            // Welcome Message
            VStack(spacing: Spacing.sm) {
                Text("Welcome Back!")
                    .apply(.headlineBold)
                    .foregroundColor(AppTheme.primaryText)

                Text("Track your training, analyze your progress, and improve your kubb game")
                    .apply(.bodyRegular)
                    .foregroundColor(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, Spacing.lg)
    }

    // MARK: - Quick Stats Section

    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader.simple("Your Progress")

            HStack(spacing: Spacing.md) {
                // Total Sessions
                StatCard(
                    title: "Sessions",
                    value: "\(statsManager.totalSessions)",
                    icon: "target",
                    color: AppTheme.primary,
                    size: .small
                )

                // Best Accuracy
                StatCard(
                    title: "Best Accuracy",
                    value: String(format: "%.0f%%", statsManager.bestAccuracy * 100),
                    icon: "scope",
                    color: AppTheme.success,
                    size: .small
                )

                // Current Streak
                StatCard(
                    title: "Streak",
                    value: "\(statsManager.currentStreak)",
                    icon: "flame.fill",
                    color: AppTheme.warning,
                    size: .small
                )
            }
        }
    }

    // MARK: - Primary Actions Section

    private var primaryActionsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader.simple("Get Started")

            VStack(spacing: Spacing.md) {
                // Training Mode
                ActionCard(
                    title: "Training",
                    description: "Practice your kubb skills with focused training modes",
                    icon: "figure.strengthtraining.traditional",
                    color: AppTheme.primary,
                    isPrimary: true
                ) {
                    selectedTab = 1
                    showingMainApp = true
                }

                // Game Logs
                ActionCard(
                    title: "Game Logs",
                    description: "Track and review your competitive matches",
                    icon: "play.circle",
                    color: AppTheme.success,
                    isPrimary: false
                ) {
                    selectedTab = 2
                    showingMainApp = true
                }

                // Statistics
                ActionCard(
                    title: "Statistics",
                    description: "Analyze your performance and progress over time",
                    icon: "chart.line.uptrend.xyaxis",
                    color: AppTheme.info,
                    isPrimary: false
                ) {
                    selectedTab = 3
                    showingMainApp = true
                }
            }
        }
    }

    // MARK: - Debug Section

    private var debugSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader.simple("Debug Tools")

            DebugSectionView()
                .environmentObject(CloudKitManager.shared)
        }
    }
}

// MARK: - Action Card Component

struct ActionCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let isPrimary: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 56, height: 56)

                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(color)
                }

                // Content
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(title)
                        .apply(.headlineRegular)
                        .foregroundColor(AppTheme.primaryText)

                    Text(description)
                        .apply(.captionRegular)
                        .foregroundColor(AppTheme.secondaryText)
                        .lineLimit(2)
                }

                Spacer()

                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.tertiaryText)
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .fill(isPrimary ? color.opacity(0.08) : AppTheme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(isPrimary ? color.opacity(0.3) : AppTheme.border, lineWidth: isPrimary ? 2 : 1)
            )
            .shadow(color: AppTheme.shadow, radius: isPrimary ? 8 : 4, y: isPrimary ? 4 : 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    LandingPageViewRedesigned(
        showingMainApp: .constant(false),
        selectedTab: .constant(0)
    )
}
