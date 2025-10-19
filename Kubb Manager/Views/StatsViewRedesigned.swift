//
//  StatsViewRedesigned.swift
//  Kubb Manager
//
//  Redesigned Statistics view with modern UI and design system
//

import SwiftUI
import Charts

// MARK: - Main Stats View

struct StatsViewRedesigned: View {
    @StateObject private var unifiedStatsManager = UnifiedStatisticsManager.shared
    @State private var selectedTab: StatsTab = .trainingOverview

    enum StatsTab: String, CaseIterable, Identifiable {
        case trainingOverview = "Overview"
        case practice = "8-Meter"
        case inkastBlast = "Inkast & Blast"
        case fullGameSim = "Full Game Sim"
        case baseballKubb = "Baseball Kubb"
        case gameLogs = "Game Logs"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .trainingOverview: return "chart.bar.fill"
            case .practice: return "target"
            case .inkastBlast: return "figure.throw"
            case .fullGameSim: return "crown.fill"
            case .baseballKubb: return "baseball.fill"
            case .gameLogs: return "doc.text.fill"
            }
        }

        var color: Color {
            switch self {
            case .trainingOverview: return AppTheme.primary
            case .practice: return AppTheme.eightMeter
            case .inkastBlast: return AppTheme.inkastBlast
            case .fullGameSim: return AppTheme.fullGameSim
            case .baseballKubb: return AppTheme.baseballKubb
            case .gameLogs: return AppTheme.textSecondary
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Picker - Scrollable horizontal tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.sm) {
                        ForEach(StatsTab.allCases) { tab in
                            TabButton(
                                tab: tab,
                                isSelected: selectedTab == tab,
                                action: { selectedTab = tab }
                            )
                        }
                    }
                    .padding(.horizontal, Spacing.screenPadding)
                    .padding(.vertical, Spacing.md)
                }
                .background(AppTheme.surface)

                Divider()

                // Content
                if unifiedStatsManager.isLoading && unifiedStatsManager.practiceSessions.isEmpty {
                    LoadingStateView()
                } else {
                    ScrollView {
                        VStack(spacing: Spacing.sectionSpacing) {
                            contentForSelectedTab
                        }
                        .padding(Spacing.screenPadding)
                    }
                }
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                Task {
                    await unifiedStatsManager.loadAllSessions()
                }
            }
            .refreshable {
                await unifiedStatsManager.refreshAllSessions()
            }
        }
    }

    @ViewBuilder
    private var contentForSelectedTab: some View {
        switch selectedTab {
        case .trainingOverview:
            TrainingOverviewSection()
                .environmentObject(unifiedStatsManager)
        case .practice:
            PracticeStatsSection()
                .environmentObject(unifiedStatsManager)
        case .inkastBlast:
            InkastBlastStatsSection()
                .environmentObject(unifiedStatsManager)
        case .fullGameSim:
            FullGameSimStatsSection()
                .environmentObject(unifiedStatsManager)
        case .baseballKubb:
            BaseballKubbStatsSection()
                .environmentObject(unifiedStatsManager)
        case .gameLogs:
            GameLogsStatsSection()
                .environmentObject(unifiedStatsManager)
        }
    }
}

// MARK: - Tab Button

struct TabButton: View {
    let tab: StatsViewRedesigned.StatsTab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: tab.icon)
                    .font(.caption)
                Text(tab.rawValue)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundColor(isSelected ? .white : tab.color)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(isSelected ? tab.color : tab.color.opacity(0.1))
            .cornerRadius(AppTheme.cornerRadiusMedium)
        }
    }
}

// MARK: - Loading State

struct LoadingStateView: View {
    var body: some View {
        VStack(spacing: Spacing.lg) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Loading statistics...")
                .font(.body)
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Training Overview Section

struct TrainingOverviewSection: View {
    @EnvironmentObject private var statsManager: UnifiedStatisticsManager

    var body: some View {
        VStack(spacing: Spacing.sectionSpacing) {
            // Header
            SectionHeader.simple("Training Statistics")

            // 8-Meter Practice Card
            if statsManager.practiceSessions.count > 0 {
                TrainingModeCard(
                    title: "8-Meter Practice",
                    icon: "target",
                    color: AppTheme.eightMeter,
                    stats: [
                        ("Sessions", "\(statsManager.practiceSessions.count)"),
                        ("Accuracy", String(format: "%.1f%%", statsManager.practiceStats.overallAccuracy * 100)),
                        ("Batons", "\(statsManager.practiceStats.totalBatonsThrown)")
                    ]
                )
            }

            // Inkast & Blast Card
            if statsManager.inkastBlastSessions.count > 0 {
                TrainingModeCard(
                    title: "Inkast & Blast",
                    icon: "figure.throw",
                    color: AppTheme.inkastBlast,
                    stats: [
                        ("Sessions", "\(statsManager.inkastBlastSessions.count)"),
                        ("Rounds", "\(statsManager.inkastBlastStats.totalRounds)"),
                        ("Handicap", String(format: "%.1f", statsManager.inkastBlastStats.overallHandicap))
                    ]
                )
            }

            // Full Game Sim Card
            if statsManager.fullGameSimSessions.count > 0 {
                TrainingModeCard(
                    title: "Full Game Sim",
                    icon: "crown.fill",
                    color: AppTheme.fullGameSim,
                    stats: [
                        ("Games", "\(statsManager.fullGameSimSessions.count)"),
                        ("Rounds", "\(statsManager.fullGameSimStats.totalRounds)"),
                        ("Accuracy", String(format: "%.1f%%", statsManager.fullGameSimStats.overallAccuracy * 100))
                    ]
                )
            }

            // Baseball Kubb Card
            if statsManager.baseballKubbSessions.count > 0 {
                TrainingModeCard(
                    title: "Baseball Kubb",
                    icon: "baseball.fill",
                    color: AppTheme.baseballKubb,
                    stats: [
                        ("Games", "\(statsManager.baseballKubbSessions.count)"),
                        ("Innings", "\(statsManager.baseballKubbStats.totalInnings)"),
                        ("Avg Score", String(format: "%.1f", statsManager.baseballKubbStats.averageScore))
                    ]
                )
            }

            // Empty state
            if statsManager.practiceSessions.isEmpty &&
               statsManager.inkastBlastSessions.isEmpty &&
               statsManager.fullGameSimSessions.isEmpty &&
               statsManager.baseballKubbSessions.isEmpty {
                EmptyStatsView()
            }
        }
    }
}

// MARK: - Training Mode Card

struct TrainingModeCard: View {
    let title: String
    let icon: String
    let color: Color
    let stats: [(String, String)]

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Header
            HStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 50, height: 50)

                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(color)
                }

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.textPrimary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(AppTheme.textTertiary)
            }

            Divider()

            // Stats
            HStack(spacing: Spacing.lg) {
                ForEach(stats, id: \.0) { stat in
                    VStack(spacing: Spacing.xs) {
                        Text(stat.1)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(color)

                        Text(stat.0)
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(Spacing.md)
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadiusMedium)
        .shadow(color: AppTheme.shadowMedium, radius: 4, y: 2)
    }
}

// MARK: - Empty Stats View

struct EmptyStatsView: View {
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.textTertiary)

            VStack(spacing: Spacing.sm) {
                Text("No Statistics Yet")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.textPrimary)

                Text("Complete training sessions to see your stats here")
                    .font(.body)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadiusLarge)
    }
}

// MARK: - Preview

#Preview {
    StatsViewRedesigned()
}
