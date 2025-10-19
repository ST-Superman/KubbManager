//
//  BaseballKubbViewRedesigned.swift
//  Kubb Manager
//
//  Redesigned Baseball Kubb using NavigationStack pattern and design system
//

import SwiftUI

// MARK: - Main View

struct BaseballKubbViewRedesigned: View {
    @StateObject private var sessionManager = BaseballKubbSessionManager()
    @State private var showingTutorial = false
    @State private var navigateToGame = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            BaseballKubbOverviewRoot(
                sessionManager: sessionManager,
                navigateToGame: $navigateToGame
            )
            .navigationTitle("Baseball Kubb")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(
                leading: Button("Done") {
                    dismiss()
                },
                trailing: Button {
                    showingTutorial = true
                } label: {
                    Image(systemName: "questionmark.circle")
                }
            )
            .navigationDestination(isPresented: $navigateToGame) {
                BaseballKubbActiveGameView(sessionManager: sessionManager)
            }
            .sheet(isPresented: $showingTutorial) {
                BaseballKubbTutorialView()
            }
        }
    }
}

// MARK: - Overview Root

struct BaseballKubbOverviewRoot: View {
    @ObservedObject var sessionManager: BaseballKubbSessionManager
    @Binding var navigateToGame: Bool
    @State private var awayTeam = ""
    @State private var homeTeam = ""
    @State private var selectedUserTeam: UserTeam = .away
    @State private var showingAbandonConfirmation = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: Spacing.sectionSpacing) {
                // Check if there's an active or incomplete session
                if sessionManager.currentSession != nil || sessionManager.incompleteSession != nil {
                    // Navigate to active game
                    Text("")
                        .onAppear {
                            navigateToGame = true
                        }
                } else {
                    // Show start view
                    heroSection
                    incompleteGameSection
                    teamSetupSection
                    if !awayTeam.isEmpty && !homeTeam.isEmpty && awayTeam != homeTeam {
                        teamSelectionSection
                    }
                    startButtonSection
                }
            }
            .padding(Spacing.screenPadding)
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: Spacing.lg) {
            // Icon
            Image("baseball_kubb")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
                .shadow(color: AppTheme.shadowMedium, radius: 8, y: 4)

            // Title & Description
            VStack(spacing: Spacing.sm) {
                Text("Baseball Kubb")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.textPrimary)

                Text("Baseball-style Kubb training with innings and scoring. Track field kubbs, baseline kubbs, and king hits.")
                    .font(.body)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadiusLarge)
        .shadow(color: AppTheme.shadowMedium, radius: 8, y: 4)
    }

    // MARK: - Incomplete Game Section

    @ViewBuilder
    private var incompleteGameSection: some View {
        if let incompleteSession = sessionManager.incompleteSession {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionHeader.simple("Game in Progress")

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack {
                        Text("\(incompleteSession.awayTeam) vs \(incompleteSession.homeTeam)")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                    }

                    Text("Inning \(incompleteSession.currentInning) - \(incompleteSession.isTop ? "Top" : "Bottom")")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)

                    Text("Score: \(incompleteSession.awayScore) - \(incompleteSession.homeScore)")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)

                    Text("Last played: \(incompleteSession.modifiedAt, style: .relative) ago")
                        .font(.caption)
                        .foregroundColor(AppTheme.textTertiary)
                }
                .padding(Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.warning.opacity(0.1))
                .cornerRadius(AppTheme.cornerRadiusMedium)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                        .stroke(AppTheme.warning.opacity(0.3), lineWidth: 2)
                )

                HStack(spacing: Spacing.md) {
                    Button("Resume Game") {
                        sessionManager.resumeIncompleteGame()
                        navigateToGame = true
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(AppTheme.success)
                    .cornerRadius(AppTheme.cornerRadiusMedium)

                    Button("Abandon") {
                        showingAbandonConfirmation = true
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(AppTheme.error)
                    .cornerRadius(AppTheme.cornerRadiusMedium)
                }
            }
            .sheet(isPresented: $showingAbandonConfirmation) {
                if let session = sessionManager.incompleteSession {
                    BaseballKubbAbandonConfirmationView(
                        session: session,
                        sessionManager: sessionManager,
                        showingAbandonConfirmation: $showingAbandonConfirmation
                    )
                }
            }

            // Divider
            Divider()
                .padding(.vertical, Spacing.md)
        }
    }

    // MARK: - Team Setup Section

    private var teamSetupSection: some View {
        VStack(spacing: Spacing.lg) {
            // Away Team
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Away Team")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.textPrimary)

                TextField("Enter away team name", text: $awayTeam)
                    .font(.body)
                    .padding(Spacing.md)
                    .background(AppTheme.surface)
                    .cornerRadius(AppTheme.cornerRadiusMedium)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            }

            // VS Divider
            Text("VS")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.textSecondary)

            // Home Team
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Home Team")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.textPrimary)

                TextField("Enter home team name", text: $homeTeam)
                    .font(.body)
                    .padding(Spacing.md)
                    .background(AppTheme.surface)
                    .cornerRadius(AppTheme.cornerRadiusMedium)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .onSubmit {
                        if canStartGame {
                            startGame()
                        }
                    }
            }
        }
    }

    // MARK: - Team Selection Section

    private var teamSelectionSection: some View {
        UserTeamSelectionView(
            selectedTeam: $selectedUserTeam,
            awayTeam: awayTeam,
            homeTeam: homeTeam
        )
    }

    // MARK: - Start Button Section

    private var startButtonSection: some View {
        Button(action: {
            startGame()
        }) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "play.fill")
                    .font(.title2)
                Text("Start New Game")
                    .font(.title3)
                    .fontWeight(.bold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.lg)
            .background(canStartGame ? AppTheme.baseballKubb : Color.gray)
            .cornerRadius(AppTheme.cornerRadiusLarge)
            .shadow(color: canStartGame ? AppTheme.shadowMedium : Color.clear, radius: 8, y: 4)
        }
        .disabled(!canStartGame)
    }

    // MARK: - Helpers

    private var canStartGame: Bool {
        !awayTeam.isEmpty && !homeTeam.isEmpty && awayTeam != homeTeam
    }

    private func startGame() {
        sessionManager.startNewGame(awayTeam: awayTeam, homeTeam: homeTeam, userTeam: selectedUserTeam)
        navigateToGame = true
    }
}

// MARK: - Active Game View

struct BaseballKubbActiveGameView: View {
    @ObservedObject var sessionManager: BaseballKubbSessionManager
    @State private var showingHitModal = false
    @State private var showingHalfSummary = false
    @State private var showingMenu = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if sessionManager.currentSession?.gameOver == true {
                // Game Over
                gameOverView
            } else if showingHalfSummary {
                // Half Summary
                BaseballKubbHalfSummaryView(
                    sessionManager: sessionManager,
                    showingHalfSummary: $showingHalfSummary
                )
            } else {
                // Active Game
                activeGameView
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(
            leading: Button("Back") {
                dismiss()
            },
            trailing: Button("Menu") {
                showingMenu = true
            }
        )
        .sheet(isPresented: $showingHitModal) {
            BaseballKubbHitModalView(
                sessionManager: sessionManager,
                showingHitModal: $showingHitModal,
                showingHalfSummary: $showingHalfSummary
            )
        }
        .sheet(isPresented: $showingMenu) {
            BaseballKubbMenuView(
                sessionManager: sessionManager,
                showingMenu: $showingMenu
            )
        }
    }

    // MARK: - Navigation Title

    private var navigationTitle: String {
        if let session = sessionManager.currentSession, !session.gameOver {
            return "Inning \(session.currentInning) - \(session.isTop ? "Top" : "Bottom")"
        }
        return "Baseball Kubb"
    }

    // MARK: - Active Game View

    private var activeGameView: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: Spacing.sectionSpacing) {
                // Scoreboard
                BaseballKubbScoreboardView(sessionManager: sessionManager)

                // Game State
                BaseballKubbGameStateView(sessionManager: sessionManager)

                // Throw Controls
                BaseballKubbThrowControlsView(
                    sessionManager: sessionManager,
                    showingHitModal: $showingHitModal,
                    showingHalfSummary: $showingHalfSummary
                )

                // Watch Control Panel
                WatchSessionControlPanel(
                    sessionType: "Baseball Kubb",
                    onStartWatchInput: {
                        sessionManager.requestWatchBatonInput()
                    },
                    onSendSessionState: {
                        sessionManager.sendSessionStateToWatch()
                    }
                )
            }
            .padding(Spacing.screenPadding)
        }
        .onAppear {
            sessionManager.setupWatchConnectivity()
            sessionManager.sendSessionStateToWatch()
        }
    }

    // MARK: - Game Over View

    private var gameOverView: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: Spacing.sectionSpacing) {
                // Winner Header
                VStack(spacing: Spacing.md) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 60))
                        .foregroundColor(AppTheme.trophy)

                    Text("Game Over!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.textPrimary)

                    if let session = sessionManager.currentSession {
                        Text("Winner: \(session.winner == "away" ? session.awayTeam : session.homeTeam)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.success)
                    }
                }
                .padding(Spacing.xl)
                .frame(maxWidth: .infinity)
                .background(AppTheme.cardBackground)
                .cornerRadius(AppTheme.cornerRadiusLarge)
                .shadow(color: AppTheme.shadowMedium, radius: 8, y: 4)

                // Final Score
                if let session = sessionManager.currentSession {
                    VStack(spacing: Spacing.md) {
                        SectionHeader.simple("Final Score")

                        VStack(spacing: Spacing.sm) {
                            HStack {
                                Text(session.awayTeam)
                                    .font(.body)
                                Spacer()
                                Text("\(session.awayScore)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("(👑 \(session.awayKings))")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textSecondary)
                            }

                            Divider()

                            HStack {
                                Text(session.homeTeam)
                                    .font(.body)
                                Spacer()
                                Text("\(session.homeScore)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("(👑 \(session.homeKings))")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                        }
                        .padding(Spacing.md)
                        .background(AppTheme.surface)
                        .cornerRadius(AppTheme.cornerRadiusMedium)
                    }
                }

                // New Game Button
                Button("New Game") {
                    sessionManager.resetSession()
                    dismiss()
                }
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.lg)
                .background(AppTheme.primary)
                .cornerRadius(AppTheme.cornerRadiusLarge)
                .shadow(color: AppTheme.shadowMedium, radius: 8, y: 4)
            }
            .padding(Spacing.screenPadding)
        }
    }
}

// MARK: - Preview

#Preview {
    BaseballKubbViewRedesigned()
}
