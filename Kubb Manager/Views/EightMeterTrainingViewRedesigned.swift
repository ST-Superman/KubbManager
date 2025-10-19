//
//  EightMeterTrainingViewRedesigned.swift
//  Kubb Manager
//
//  Redesigned with NavigationStack instead of nested TabView for clearer navigation
//

import SwiftUI

// MARK: - Main Training View (Redesigned)

struct EightMeterTrainingViewRedesigned: View {
    @EnvironmentObject private var sessionManager: SessionManager
    @State private var showingRecoveryAlert = false
    @State private var showingTutorial = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            // Root view is the overview (HomeView)
            EightMeterOverviewRoot()
                .navigationTitle("8-Meter Practice")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Done") {
                            dismiss()
                        }
                    }

                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingTutorial = true
                        } label: {
                            Image(systemName: "questionmark.circle")
                        }
                    }
                }
                .sheet(isPresented: $showingTutorial) {
                    EightMeterTutorialView()
                }
                .alert("Incomplete Practice Session", isPresented: $showingRecoveryAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("Resume", role: .none) {
                        if sessionManager.hasPausedSession() {
                            Task {
                                await sessionManager.resumeSession()
                            }
                        } else {
                            sessionManager.resumeIncompleteSession()
                        }
                    }
                    Button("Delete", role: .destructive) {
                        Task {
                            await sessionManager.deleteIncompleteSession()
                        }
                    }
                } message: {
                    if let session = sessionManager.currentSession {
                        let sessionType = session.isPaused ? "paused" : "incomplete"
                        Text("You have a \(sessionType) practice session from \(session.date.formatted(date: .abbreviated, time: .shortened)). What would you like to do?")
                    } else {
                        Text("You have an incomplete practice session. What would you like to do?")
                    }
                }
                .onAppear {
                    checkForIncompleteSession()
                }
        }
    }

    private func checkForIncompleteSession() {
        if sessionManager.shouldShowRecoveryAlert() {
            showingRecoveryAlert = true
        }
    }
}

// MARK: - Overview Root (Navigation Starting Point)

struct EightMeterOverviewRoot: View {
    @EnvironmentObject private var sessionManager: SessionManager
    @State private var navigateToPractice = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: Spacing.sectionSpacing) {
                // Show appropriate card based on session state
                if sessionManager.isSessionActive {
                    ActiveSessionCard {
                        navigateToPractice = true
                    }
                    .environmentObject(sessionManager)
                } else if sessionManager.hasIncompleteSession() {
                    IncompleteSessionBanner()
                        .environmentObject(sessionManager)
                } else {
                    QuickStartCard {
                        navigateToPractice = true
                    }
                }

                // Today's stats overview
                TodayStatsOverview()
                    .environmentObject(sessionManager)

                // Personal records (if any)
                PersonalRecordsCompact()

                // Recent sessions
                RecentSessionsCompact()
            }
            .padding(Spacing.screenPadding)
        }
        .navigationDestination(isPresented: $navigateToPractice) {
            PracticeNavigationDestination()
                .environmentObject(sessionManager)
        }
        .onChange(of: sessionManager.isSessionActive) { _, isActive in
            if isActive {
                navigateToPractice = true
            }
        }
    }
}

// MARK: - Practice Navigation Destination

struct PracticeNavigationDestination: View {
    @EnvironmentObject private var sessionManager: SessionManager

    var body: some View {
        Group {
            if sessionManager.isSessionActive {
                PracticeView()
                    .navigationTitle("Practice")
                    .navigationBarTitleDisplayMode(.inline)
            } else if sessionManager.hasIncompleteSession() {
                IncompleteSessionPracticeView()
                    .navigationTitle("Practice")
                    .navigationBarTitleDisplayMode(.inline)
            } else {
                TargetSettingView()
                    .navigationTitle("Set Target")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

// MARK: - Today Stats Overview

struct TodayStatsOverview: View {
    @EnvironmentObject private var sessionManager: SessionManager
    @StateObject private var historyManager = HistoryManager()

    var body: some View {
        VStack(spacing: Spacing.md) {
            SectionHeader.simple("Today's Overview")

            HStack(spacing: Spacing.cardSpacing) {
                StatCard(
                    title: "Today's Batons",
                    value: "\(todaysBatons)",
                    icon: "figure.walk",
                    color: AppTheme.primary,
                    size: .medium
                )

                StatCard(
                    title: "Current Accuracy",
                    value: String(format: "%.1f%%", sessionManager.accuracy * 100),
                    icon: "target",
                    color: AppTheme.accuracy,
                    size: .medium
                )

                StatCard(
                    title: "Sessions Today",
                    value: "\(todaysSessions)",
                    icon: "calendar",
                    color: AppTheme.primary,
                    size: .medium
                )
            }
        }
    }

    private var todaysBatons: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return historyManager.sessions
            .filter { Calendar.current.isDate($0.date, inSameDayAs: today) }
            .reduce(0) { $0 + $1.totalBatons }
    }

    private var todaysSessions: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return historyManager.sessions
            .filter { Calendar.current.isDate($0.date, inSameDayAs: today) }
            .count
    }
}

// MARK: - Personal Records Compact

struct PersonalRecordsCompact: View {
    @StateObject private var statsManager = UnifiedStatisticsManager.shared
    @State private var navigateToStats = false

    var body: some View {
        if hasAnyRecords {
            VStack(spacing: Spacing.md) {
                Button(action: { navigateToStats = true }) {
                    HStack {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(AppTheme.trophy)
                        Text("Personal Records")
                            .font(.headline)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .padding(Spacing.md)
                    .background(AppTheme.cardBackground)
                    .cornerRadius(AppTheme.cornerRadiusMedium)
                }
                .buttonStyle(PlainButtonStyle())

                HStack(spacing: Spacing.cardSpacing) {
                    StatCard(
                        title: "Best Accuracy",
                        value: String(format: "%.1f%%", statsManager.personalRecords.bestAccuracyAllTime * 100),
                        icon: "target",
                        color: AppTheme.accuracy,
                        size: .small
                    )

                    StatCard(
                        title: "Longest Streak",
                        value: "\(statsManager.personalRecords.longestHitStreak)",
                        icon: "flame.fill",
                        color: AppTheme.streak,
                        size: .small
                    )

                    StatCard(
                        title: "Perfect Rounds",
                        value: "\(statsManager.personalRecords.perfectRoundsCount)",
                        icon: "sparkles",
                        color: AppTheme.accent,
                        size: .small
                    )
                }
            }
        }
    }

    private var hasAnyRecords: Bool {
        statsManager.personalRecords.bestAccuracyAllTime > 0 ||
        statsManager.personalRecords.longestHitStreak > 0 ||
        statsManager.personalRecords.perfectRoundsCount > 0
    }
}

// MARK: - Recent Sessions Compact

struct RecentSessionsCompact: View {
    @StateObject private var historyManager = HistoryManager()

    var body: some View {
        VStack(spacing: Spacing.md) {
            SectionHeader.withAction(
                "Recent Sessions",
                actionTitle: "View All",
                actionIcon: "chevron.right"
            ) {
                // Navigate to history tab
                // This would need to be passed down from parent to switch tabs
            }

            if historyManager.sessions.isEmpty {
                EmptySessionsView()
            } else {
                VStack(spacing: Spacing.sm) {
                    ForEach(historyManager.sessions.prefix(3)) { session in
                        RecentSessionRow(session: session)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    EightMeterTrainingViewRedesigned()
        .environmentObject(SessionManager())
}
