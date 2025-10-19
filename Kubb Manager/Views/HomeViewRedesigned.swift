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
        ScrollView {
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

// MARK: - Quick Start Card

struct QuickStartCard: View {
    let onStartSession: () -> Void

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.primary)

            VStack(spacing: Spacing.sm) {
                Text("Ready to Practice?")
                    .font(.title3)
                    .fontWeight(.bold)

                Text("Set your target and start tracking")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            ActionButton.primary("Start New Session", icon: "play.fill") {
                onStartSession()
            }
        }
        .prominentCardStyle()
    }
}

// MARK: - Active Session Card

struct ActiveSessionCard: View {
    @EnvironmentObject private var sessionManager: SessionManager
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Header
            HStack {
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(AppTheme.statusActive)

                Text("Practice in Progress")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()
            }

            // Progress Bar
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Text("Progress")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                    Spacer()
                    Text("\(sessionManager.totalBatons) / \(sessionManager.target)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                ProgressView(value: sessionManager.progressPercentage)
                    .progressViewStyle(LinearProgressViewStyle(tint: AppTheme.primary))
                    .frame(height: 8)
            }

            // Quick Stats
            HStack(spacing: Spacing.md) {
                VStack(spacing: Spacing.xs) {
                    Text(String(format: "%.1f%%", sessionManager.accuracy * 100))
                        .font(.title2)
                        .fontWeight(.bold)
                        .monospacedDigit()
                    Text("Accuracy")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 40)

                VStack(spacing: Spacing.xs) {
                    Text("\(sessionManager.totalBatons)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .monospacedDigit()
                    Text("Batons")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }

            // Continue Button
            ActionButton.success("Continue Practice", icon: "arrow.right") {
                onContinue()
            }
        }
        .prominentCardStyle()
    }
}

// MARK: - Incomplete Session Banner

struct IncompleteSessionBanner: View {
    @EnvironmentObject private var sessionManager: SessionManager
    @State private var showingDeleteAlert = false

    var body: some View {
        VStack(spacing: Spacing.md) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(AppTheme.warning)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Incomplete Session")
                        .font(.headline)

                    if let session = sessionManager.currentSession {
                        Text("Started \(session.date.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }

                Spacer()
            }

            if let session = sessionManager.currentSession {
                HStack(spacing: Spacing.md) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Progress")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                        Text("\(session.totalBatons)/\(session.target)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Accuracy")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                        Text("\(session.accuracy, specifier: "%.1f")%")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
            }

            HStack(spacing: Spacing.md) {
                ActionButton("Resume", icon: "play.circle.fill", variant: .success, size: .medium) {
                    if sessionManager.hasPausedSession() {
                        Task {
                            await sessionManager.resumeSession()
                        }
                    } else {
                        sessionManager.resumeIncompleteSession()
                    }
                }

                ActionButton("Delete", icon: "trash", variant: .destructive, size: .medium) {
                    showingDeleteAlert = true
                }
            }
        }
        .cardStyle()
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                .stroke(AppTheme.warning.opacity(0.3), lineWidth: 2)
        )
        .alert("Delete Incomplete Session", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await sessionManager.deleteIncompleteSession()
                }
            }
        } message: {
            Text("Are you sure you want to delete this incomplete session? This action cannot be undone.")
        }
    }
}

// MARK: - Today Stats Row (removed - integrated into main view)

// MARK: - Personal Records Section (removed - integrated into main view)

// MARK: - Recent Session Row

struct RecentSessionRow: View {
    let session: Session

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Date indicator
            VStack(spacing: 2) {
                Text(dayOfMonth)
                    .font(.title3)
                    .fontWeight(.bold)
                Text(monthAbbr)
                    .font(.caption2)
                    .foregroundColor(AppTheme.textSecondary)
            }
            .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(session.totalBatons) batons")
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: Spacing.sm) {
                    Label(
                        String(format: "%.1f%%", session.accuracy * 100),
                        systemImage: "target"
                    )
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)

                    if session.isTargetReached {
                        Label("Goal", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(AppTheme.success)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(AppTheme.textTertiary)
        }
        .padding(Spacing.md)
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadiusMedium)
    }

    private var dayOfMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: session.date)
    }

    private var monthAbbr: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: session.date)
    }
}

// MARK: - Empty Sessions View

struct EmptySessionsView: View {
    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 40))
                .foregroundColor(AppTheme.textTertiary)

            Text("No Sessions Yet")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(AppTheme.textSecondary)

            Text("Start your first practice session to see your history here")
                .font(.caption)
                .foregroundColor(AppTheme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.xl)
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadiusMedium)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        HomeViewRedesigned(selectedTab: .constant(0))
            .environmentObject(SessionManager())
    }
}
