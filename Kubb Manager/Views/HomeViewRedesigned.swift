//
//  HomeViewRedesigned.swift
//  Kubb Manager
//
//  Redesigned home dashboard with improved visual hierarchy and new design system
//

import SwiftUI

// MARK: - Redesigned Home View

struct HomeViewRedesigned: View {
    @EnvironmentObject private var sessionManager: SessionManager
    @Binding var selectedTab: Int

    @State private var showingTargetSetting = false
    @StateObject private var statsManager = UnifiedStatisticsManager.shared
    @StateObject private var historyManager = HistoryManager()
    @State private var isPersonalRecordsExpanded = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: Spacing.sectionSpacing) {
                // 1. PRIMARY ACTION - Most Important Element
                primaryActionSection

                // 2. AT-A-GLANCE STATS - Quick Overview
                todayStatsSection

                // 3. PERSONAL RECORDS - Collapsible (if any exist)
                if hasAnyRecords {
                    personalRecordsSection
                }

                // 4. RECENT SESSIONS - Compact List
                recentSessionsSection
            }
            .padding(Spacing.screenPadding)
        }
        .navigationTitle("Practice Overview")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingTargetSetting) {
            TargetSettingView()
        }
        .onAppear {
            Task {
                await statsManager.loadAllSessionsIfNeeded()
            }
        }
    }

    // MARK: - View Sections

    private var primaryActionSection: some View {
        Group {
            if sessionManager.isSessionActive {
                ActiveSessionCard {
                    selectedTab = 1
                }
                .environmentObject(sessionManager)
            } else if sessionManager.hasIncompleteSession() {
                IncompleteSessionBanner()
                    .environmentObject(sessionManager)
            } else {
                QuickStartCard {
                    showingTargetSetting = true
                }
            }
        }
    }

    private var todayStatsSection: some View {
        VStack(spacing: Spacing.md) {
            SectionHeader.simple("Today's Overview")

            HStack(spacing: Spacing.cardSpacing) {
                StatCard.totalBatons(
                    value: todaysBatons,
                    subtitle: "Today"
                )

                StatCard.accuracy(
                    value: sessionManager.accuracy,
                    subtitle: "Current",
                    trend: accuracyTrend
                )

                StatCard.streak(
                    value: statsManager.personalRecords.currentHitStreak,
                    subtitle: "Active"
                )
            }
        }
    }

    private var personalRecordsSection: some View {
        VStack(spacing: Spacing.md) {
            CollapsibleSectionHeader(
                "Personal Records",
                icon: "trophy.fill",
                iconColor: AppTheme.trophy,
                isExpanded: $isPersonalRecordsExpanded
            )

            if isPersonalRecordsExpanded {
                VStack(spacing: Spacing.cardSpacing) {
                    HStack(spacing: Spacing.cardSpacing) {
                        StatCard(
                            title: "Best Accuracy",
                            value: String(format: "%.1f%%", statsManager.personalRecords.bestAccuracyAllTime * 100),
                            icon: "target",
                            color: AppTheme.accuracy,
                            size: .medium
                        )

                        StatCard(
                            title: "Longest Streak",
                            value: "\(statsManager.personalRecords.longestHitStreak)",
                            icon: "flame.fill",
                            color: AppTheme.streak,
                            size: .medium
                        )
                    }

                    HStack(spacing: Spacing.cardSpacing) {
                        StatCard(
                            title: "Perfect Rounds",
                            value: "\(statsManager.personalRecords.perfectRoundsCount)",
                            icon: "sparkles",
                            color: AppTheme.accent,
                            size: .medium
                        )

                        StatCard(
                            title: "Total Sessions",
                            value: "\(historyManager.totalSessions)",
                            icon: "calendar",
                            color: AppTheme.primary,
                            size: .medium
                        )
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isPersonalRecordsExpanded)
    }

    private var recentSessionsSection: some View {
        VStack(spacing: Spacing.md) {
            SectionHeader.withAction(
                "Recent Sessions",
                actionTitle: "View All",
                actionIcon: "chevron.right"
            ) {
                selectedTab = 2 // Navigate to history tab
            }

            if historyManager.sessions.isEmpty {
                EmptySessionsView()
            } else {
                VStack(spacing: Spacing.sm) {
                    ForEach(historyManager.sessions.prefix(5)) { session in
                        RecentSessionRow(session: session)
                    }
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var hasAnyRecords: Bool {
        statsManager.personalRecords.bestAccuracyAllTime > 0 ||
        statsManager.personalRecords.longestHitStreak > 0 ||
        statsManager.personalRecords.perfectRoundsCount > 0
    }

    private var todaysBatons: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return historyManager.sessions
            .filter { Calendar.current.isDate($0.date, inSameDayAs: today) }
            .reduce(0) { $0 + $1.totalBatons }
    }

    private var accuracyTrend: StatCard.TrendIndicator? {
        guard historyManager.sessions.count >= 2 else { return nil }

        let recentSessions = Array(historyManager.sessions.prefix(5))
        let recentAccuracy = recentSessions.reduce(0.0) { $0 + $1.accuracy } / Double(recentSessions.count)

        let allAccuracy = historyManager.sessions.reduce(0.0) { $0 + $1.accuracy } / Double(historyManager.sessions.count)

        let diff = (recentAccuracy - allAccuracy) * 100

        if abs(diff) < 2 {
            return .stable("Stable")
        } else if diff > 0 {
            return .up(String(format: "+%.1f%%", diff))
        } else {
            return .down(String(format: "%.1f%%", diff))
        }
    }
}

// MARK: - Preview
// Note: Shared components (QuickStartCard, ActiveSessionCard, etc.) are now in SessionCards.swift

#Preview {
    NavigationStack {
        HomeViewRedesigned(selectedTab: .constant(0))
            .environmentObject(SessionManager())
    }
}
