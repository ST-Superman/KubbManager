//
//  HistoryViewRedesigned.swift
//  Kubb Manager
//
//  Redesigned History view with modern UI and design system
//

import SwiftUI

// MARK: - Main History View

struct HistoryViewRedesigned: View {
    @StateObject private var unifiedHistoryManager = UnifiedHistoryManager()
    @StateObject private var sessionManager = SessionManager()
    @State private var selectedTab: HistoryTab = .all
    @State private var selectedSession: UnifiedSession?
    @State private var showingSessionDetail = false
    @State private var showingExportOptions = false
    @State private var showingDeleteAlert = false
    @State private var sessionToDelete: UnifiedSession?
    @Environment(\.dismiss) private var dismiss

    enum HistoryTab: String, CaseIterable, Identifiable {
        case all = "All"
        case eightMeter = "8-Meter"
        case inkastBlast = "Inkast & Blast"
        case fullGameSim = "Full Game Sim"
        case baseballKubb = "Baseball Kubb"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .all: return "clock.arrow.circlepath"
            case .eightMeter: return "target"
            case .inkastBlast: return "figure.throw"
            case .fullGameSim: return "crown.fill"
            case .baseballKubb: return "baseball.fill"
            }
        }

        var color: Color {
            switch self {
            case .all: return AppTheme.primary
            case .eightMeter: return AppTheme.eightMeterTraining
            case .inkastBlast: return AppTheme.inkastBlast
            case .fullGameSim: return AppTheme.fullGameSim
            case .baseballKubb: return AppTheme.baseballKubb
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Picker - Scrollable horizontal tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.sm) {
                        ForEach(HistoryTab.allCases) { tab in
                            HistoryTabButton(
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
                if unifiedHistoryManager.isLoading && unifiedHistoryManager.sessions.isEmpty {
                    HistoryLoadingView()
                } else if filteredSessions.isEmpty && !sessionManager.hasIncompleteSession() {
                    HistoryEmptyView(selectedTab: selectedTab)
                } else {
                    ScrollView {
                        VStack(spacing: Spacing.sectionSpacing) {
                            // Incomplete Session Section
                            if sessionManager.hasIncompleteSession() {
                                IncompleteSessionCard()
                                    .environmentObject(sessionManager)
                            }

                            // Statistics Header
                            if selectedTab == .all {
                                HistoryStatisticsCard()
                                    .environmentObject(unifiedHistoryManager)
                            }

                            // Sessions List
                            if !filteredSessions.isEmpty {
                                SessionsListCard(
                                    sessions: filteredSessions,
                                    selectedSession: $selectedSession,
                                    showingSessionDetail: $showingSessionDetail,
                                    sessionToDelete: $sessionToDelete,
                                    showingDeleteAlert: $showingDeleteAlert
                                )
                            }
                        }
                        .padding(Spacing.screenPadding)
                    }
                }
            }
            .navigationTitle("Session History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            Task {
                                await AppInitializationManager.shared.refreshAllData()
                            }
                        }) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }

                        Button(action: {
                            Task {
                                await CloudKitManager.shared.performComprehensiveDeduplication()
                                await AppInitializationManager.shared.refreshAllData()
                            }
                        }) {
                            Label("Clean Duplicates", systemImage: "trash")
                        }

                        Button(action: {
                            showingExportOptions = true
                        }) {
                            Label("Export Data", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .refreshable {
                await AppInitializationManager.shared.refreshAllData()
            }
        }
        .sheet(isPresented: $showingSessionDetail) {
            if let session = selectedSession {
                UnifiedSessionDetailView(session: session)
            }
        }
        .actionSheet(isPresented: $showingExportOptions) {
            ActionSheet(
                title: Text("Export Data"),
                message: Text("Choose export format"),
                buttons: [
                    .default(Text("Export as JSON")) {
                        exportData(format: .json)
                    },
                    .default(Text("Export as CSV")) {
                        exportData(format: .csv)
                    },
                    .cancel()
                ]
            )
        }
        .alert("Delete Session", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let session = sessionToDelete {
                    Task {
                        await unifiedHistoryManager.deleteSession(session)
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this session? This action cannot be undone.")
        }
    }

    // MARK: - Filtered Sessions

    private var filteredSessions: [UnifiedSession] {
        switch selectedTab {
        case .all:
            return unifiedHistoryManager.sessions
        case .eightMeter:
            return unifiedHistoryManager.sessions.filter { $0.sessionType == .practice }
        case .inkastBlast:
            return unifiedHistoryManager.sessions.filter { $0.sessionType == .inkastBlast }
        case .fullGameSim:
            return unifiedHistoryManager.sessions.filter { $0.sessionType == .fullGameSim }
        case .baseballKubb:
            return unifiedHistoryManager.sessions.filter { $0.sessionType == .baseballKubb }
        }
    }

    // MARK: - Export Helper

    private func exportData(format: ExportFormat) {
        let content = "Unified export coming soon..."

        let activityVC = UIActivityViewController(
            activityItems: [content],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }

    enum ExportFormat {
        case json, csv
    }
}

// MARK: - Tab Button

struct HistoryTabButton: View {
    let tab: HistoryViewRedesigned.HistoryTab
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

// MARK: - Loading View

struct HistoryLoadingView: View {
    var body: some View {
        VStack(spacing: Spacing.lg) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Loading session history...")
                .font(.body)
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Empty View

struct HistoryEmptyView: View {
    let selectedTab: HistoryViewRedesigned.HistoryTab

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: selectedTab.icon)
                .font(.system(size: 60))
                .foregroundColor(AppTheme.textTertiary)

            VStack(spacing: Spacing.sm) {
                Text(emptyTitle)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.textPrimary)

                Text(emptyMessage)
                    .font(.body)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyTitle: String {
        switch selectedTab {
        case .all:
            return "No Sessions Yet"
        case .eightMeter:
            return "No 8-Meter Sessions"
        case .inkastBlast:
            return "No Inkast & Blast Sessions"
        case .fullGameSim:
            return "No Full Game Sim Sessions"
        case .baseballKubb:
            return "No Baseball Kubb Sessions"
        }
    }

    private var emptyMessage: String {
        switch selectedTab {
        case .all:
            return "Complete training sessions to see your history here"
        case .eightMeter:
            return "Complete 8-Meter Practice sessions to see them here"
        case .inkastBlast:
            return "Complete Inkast & Blast sessions to see them here"
        case .fullGameSim:
            return "Complete Full Game Sim sessions to see them here"
        case .baseballKubb:
            return "Complete Baseball Kubb games to see them here"
        }
    }
}

// MARK: - Incomplete Session Card

struct IncompleteSessionCard: View {
    @EnvironmentObject private var sessionManager: SessionManager
    @State private var showingDeleteAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            HStack(spacing: Spacing.sm) {
                Image(systemName: sessionManager.currentSession?.isPaused == true ? "pause.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.title3)
                    .foregroundColor(AppTheme.warning)

                Text(sessionManager.currentSession?.isPaused == true ? "Paused Session" : "Incomplete Session")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.textPrimary)

                Spacer()
            }

            if let session = sessionManager.currentSession {
                VStack(spacing: Spacing.md) {
                    // Session Info
                    HStack(spacing: Spacing.md) {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Started")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                            Text(session.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(AppTheme.textPrimary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: Spacing.xs) {
                            Text("Target")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                            Text("\(session.target) kubbs")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(AppTheme.textPrimary)
                        }
                    }

                    HStack(spacing: Spacing.md) {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Progress")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                            Text("\(session.totalBatons) / \(session.target)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(AppTheme.primary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: Spacing.xs) {
                            Text("Accuracy")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                            Text(String(format: "%.1f%%", session.accuracy * 100))
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(AppTheme.success)
                        }
                    }

                    Divider()

                    // Action Buttons
                    HStack(spacing: Spacing.md) {
                        Button(action: {
                            if sessionManager.hasPausedSession() {
                                Task {
                                    await sessionManager.resumeSession()
                                }
                            } else {
                                sessionManager.resumeIncompleteSession()
                            }
                        }) {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "play.fill")
                                Text("Resume")
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.sm)
                            .background(AppTheme.success)
                            .cornerRadius(AppTheme.cornerRadiusMedium)
                        }

                        Button(action: {
                            showingDeleteAlert = true
                        }) {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "trash.fill")
                                Text("Delete")
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.sm)
                            .background(AppTheme.error)
                            .cornerRadius(AppTheme.cornerRadiusMedium)
                        }
                    }
                }
            }
        }
        .padding(Spacing.md)
        .background(AppTheme.warning.opacity(0.1))
        .cornerRadius(AppTheme.cornerRadiusMedium)
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

// MARK: - Statistics Card

struct HistoryStatisticsCard: View {
    @EnvironmentObject private var historyManager: UnifiedHistoryManager

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Header
            SectionHeader.simple("Overall Statistics")

            // Stats Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Spacing.md) {
                HistoryStatItem(
                    title: "Total Sessions",
                    value: "\(historyManager.totalSessions)",
                    icon: "calendar",
                    color: AppTheme.primary
                )

                HistoryStatItem(
                    title: "8M Training",
                    value: "\(historyManager.totalPracticeSessions)",
                    icon: "target",
                    color: AppTheme.eightMeterTraining
                )

                HistoryStatItem(
                    title: "Inkast & Blast",
                    value: "\(historyManager.totalInkastBlastSessions)",
                    icon: "figure.throw",
                    color: AppTheme.inkastBlast
                )

                HistoryStatItem(
                    title: "Full Game Sim",
                    value: "\(historyManager.totalFullGameSimSessions)",
                    icon: "crown.fill",
                    color: AppTheme.fullGameSim
                )

                HistoryStatItem(
                    title: "Baseball Kubb",
                    value: "\(historyManager.totalBaseballKubbSessions)",
                    icon: "baseball.fill",
                    color: AppTheme.baseballKubb
                )

                HistoryStatItem(
                    title: "Overall Accuracy",
                    value: String(format: "%.1f%%", historyManager.overallAccuracy * 100),
                    icon: "scope",
                    color: AppTheme.success
                )
            }
        }
        .padding(Spacing.md)
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadiusMedium)
        .shadow(color: AppTheme.shadowMedium, radius: 4, y: 2)
    }
}

// MARK: - Stat Item

struct HistoryStatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.sm)
        .background(AppTheme.surface)
        .cornerRadius(AppTheme.cornerRadiusMedium)
    }
}

// MARK: - Sessions List Card

struct SessionsListCard: View {
    let sessions: [UnifiedSession]
    @Binding var selectedSession: UnifiedSession?
    @Binding var showingSessionDetail: Bool
    @Binding var sessionToDelete: UnifiedSession?
    @Binding var showingDeleteAlert: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            HStack {
                SectionHeader.simple("Sessions")
                Spacer()
                Text("\(sessions.count)")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
            }

            // Sessions
            VStack(spacing: Spacing.sm) {
                ForEach(sessions, id: \.id) { session in
                    HistorySessionRow(session: session)
                        .onTapGesture {
                            selectedSession = session
                            showingSessionDetail = true
                        }
                        .contextMenu {
                            Button(action: {
                                selectedSession = session
                                showingSessionDetail = true
                            }) {
                                Label("View Details", systemImage: "eye")
                            }

                            Button(role: .destructive, action: {
                                sessionToDelete = session
                                showingDeleteAlert = true
                            }) {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
        }
    }
}

// MARK: - Session Row

struct HistorySessionRow: View {
    let session: UnifiedSession

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Session Type Icon
            ZStack {
                Circle()
                    .fill(session.sessionType.color.opacity(0.15))
                    .frame(width: 50, height: 50)

                Image(systemName: session.sessionType.icon)
                    .font(.system(size: 22))
                    .foregroundColor(session.sessionType.color)
            }

            // Session Info
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(session.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.textPrimary)

                Text(session.subtitle)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)

                HStack(spacing: Spacing.xs) {
                    Text(session.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(AppTheme.textTertiary)

                    if let duration = session.duration {
                        Text("• \(formatDuration(duration))")
                            .font(.caption)
                            .foregroundColor(AppTheme.textTertiary)
                    }
                }
            }

            Spacer()

            // Session Stats
            VStack(alignment: .trailing, spacing: Spacing.xs) {
                Text(session.primaryStat)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(session.sessionType.color)

                Text(session.secondaryStat)
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)

                if let accuracy = session.accuracy {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "scope")
                            .font(.caption2)

                        Text(String(format: "%.1f%%", accuracy * 100))
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(accuracyColor(accuracy))
                }
            }
        }
        .padding(Spacing.md)
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadiusMedium)
        .shadow(color: AppTheme.shadowLight, radius: 2, y: 1)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration.truncatingRemainder(dividingBy: 3600)) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    private func accuracyColor(_ accuracy: Double) -> Color {
        if accuracy >= 0.7 {
            return AppTheme.success
        } else if accuracy >= 0.5 {
            return AppTheme.warning
        } else {
            return AppTheme.error
        }
    }
}

// MARK: - Preview

#Preview {
    HistoryViewRedesigned()
}
