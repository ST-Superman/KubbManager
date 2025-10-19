//
//  SessionCards.swift
//  Kubb Manager
//
//  Shared session-related card components used across multiple views
//

import SwiftUI

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

// MARK: - Recent Session Row

struct RecentSessionRow: View {
    let session: PracticeSession

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

#Preview("Quick Start Card") {
    QuickStartCard {
        print("Start tapped")
    }
    .padding()
}

#Preview("Active Session Card") {
    ActiveSessionCard {
        print("Continue tapped")
    }
    .environmentObject(SessionManager())
    .padding()
}

#Preview("Incomplete Session Banner") {
    IncompleteSessionBanner()
        .environmentObject(SessionManager())
        .padding()
}

#Preview("Recent Session Row") {
    let session = PracticeSession(target: 50)
    return RecentSessionRow(session: session)
        .padding()
}

#Preview("Empty Sessions") {
    EmptySessionsView()
        .padding()
}
