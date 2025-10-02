//
//  BaseballKubbView.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 9/23/25.
//

import SwiftUI

struct BaseballKubbView: View {
    @StateObject private var sessionManager = BaseballKubbSessionManager()
    @Environment(\.dismiss) private var dismiss
    @State private var showingResults = false
    @State private var showingHitModal = false
    @State private var showingHalfSummary = false
    @State private var showingMenu = false
    @State private var showingTutorial = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                BaseballKubbHeaderView()
                
                // Main Content
                if sessionManager.currentSession == nil {
                    BaseballKubbStartView(sessionManager: sessionManager, showingHalfSummary: $showingHalfSummary)
                } else if sessionManager.currentSession?.gameOver == true {
                    BaseballKubbGameEndView(sessionManager: sessionManager)
                } else if showingHalfSummary {
                    BaseballKubbHalfSummaryView(sessionManager: sessionManager, showingHalfSummary: $showingHalfSummary)
                } else {
                    BaseballKubbGameView(sessionManager: sessionManager, showingHitModal: $showingHitModal, showingHalfSummary: $showingHalfSummary)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back to Main Menu") {
                        dismiss()
                    }
                }
                
                if sessionManager.currentSession != nil && sessionManager.currentSession?.gameOver != true {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Menu") {
                            showingMenu = true
                        }
                    }
                } else {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Tutorial") {
                            showingTutorial = true
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingHitModal) {
            BaseballKubbHitModalView(sessionManager: sessionManager, showingHitModal: $showingHitModal, showingHalfSummary: $showingHalfSummary)
        }
        .sheet(isPresented: $showingMenu) {
            BaseballKubbMenuView(sessionManager: sessionManager, showingMenu: $showingMenu)
        }
        .fullScreenCover(isPresented: $showingTutorial) {
            BaseballKubbTutorialView()
        }
    }
}

struct BaseballKubbHeaderView: View {
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image("baseball_kubb")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Baseball Kubb")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(Date().formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
}

struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemBackground))
        )
    }
}

struct BaseballKubbStartView: View {
    @ObservedObject var sessionManager: BaseballKubbSessionManager
    @Binding var showingHalfSummary: Bool
    @State private var awayTeam = ""
    @State private var homeTeam = ""
    @State private var selectedUserTeam: UserTeam = .away
    @State private var showingAbandonConfirmation = false
    @State private var showingTutorial = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    Image("baseball_kubb")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                    
                    Text("Baseball Kubb")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Baseball-style Kubb training with innings and scoring. Track field kubbs, baseline kubbs, and king hits.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("Learn the Rules") {
                        showingTutorial = true
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .padding(.top, 8)
                }
            
            VStack(spacing: 24) {
                // Show incomplete game option if available
                if let incompleteSession = sessionManager.incompleteSession {
                    VStack(spacing: 16) {
                        Text("Game in Progress")
                            .font(.headline)
                            .foregroundColor(.orange)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("\(incompleteSession.awayTeam) vs \(incompleteSession.homeTeam)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text("Inning \(incompleteSession.currentInning) - \(incompleteSession.isTop ? "Top" : "Bottom")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("Score: \(incompleteSession.awayScore) - \(incompleteSession.homeScore)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("Last played: \(incompleteSession.modifiedAt, style: .relative) ago")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        HStack(spacing: 12) {
                            Button("Resume Game") {
                                sessionManager.resumeIncompleteGame()
                                // If the half-inning is over, show the summary
                                if sessionManager.currentSession?.isHalfInningOver == true {
                                    showingHalfSummary = true
                                }
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            
                            Button("Abandon Game") {
                                showingAbandonConfirmation = true
                            }
                            .buttonStyle(PrimaryButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider()
                        .padding(.horizontal)
                }
                
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Away Team")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        TextField("Enter away team name", text: $awayTeam)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onSubmit {
                                // Focus home team field
                            }
                    }
                    
                    Text("VS")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Home Team")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        TextField("Enter home team name", text: $homeTeam)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onSubmit {
                                if !awayTeam.isEmpty && !homeTeam.isEmpty && awayTeam != homeTeam {
                                    startGame()
                                }
                            }
                    }
                }
                
                // Team Selection - always show when teams are entered
                if !awayTeam.isEmpty && !homeTeam.isEmpty && awayTeam != homeTeam {
                    UserTeamSelectionView(
                        selectedTeam: $selectedUserTeam,
                        awayTeam: awayTeam,
                        homeTeam: homeTeam
                    )
                }
                
                Button(action: {
                    print("🎮 Starting game with teams: \(awayTeam) vs \(homeTeam), User team: \(selectedUserTeam)")
                    startGame()
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start New Game")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canStartGame ? Color.blue : Color.gray)
                    .cornerRadius(12)
                }
                .disabled(!canStartGame)
            }
            .padding(.horizontal)
            
            // Add some bottom padding for better scrolling experience
            Color.clear.frame(height: 50)
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
        .fullScreenCover(isPresented: $showingTutorial) {
            BaseballKubbTutorialView()
        }
    }
    
    private var canStartGame: Bool {
        !awayTeam.isEmpty && !homeTeam.isEmpty && awayTeam != homeTeam
    }
    
    private func startGame() {
        sessionManager.startNewGame(awayTeam: awayTeam, homeTeam: homeTeam, userTeam: selectedUserTeam)
    }
}

struct BaseballKubbGameView: View {
    @ObservedObject var sessionManager: BaseballKubbSessionManager
    @Binding var showingHitModal: Bool
    @Binding var showingHalfSummary: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Scoreboard
                BaseballKubbScoreboardView(sessionManager: sessionManager)
                
                // Game State
                BaseballKubbGameStateView(sessionManager: sessionManager)
                
                // Throw Controls
                BaseballKubbThrowControlsView(sessionManager: sessionManager, showingHitModal: $showingHitModal, showingHalfSummary: $showingHalfSummary)
            }
            .padding()
        }
    }
}

struct BaseballKubbScoreboardView: View {
    @ObservedObject var sessionManager: BaseballKubbSessionManager
    
    var body: some View {
        VStack(spacing: 16) {
            // Inning Display
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("INNING")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        Text("\(sessionManager.currentSession?.currentInning ?? 1)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text(sessionManager.currentSession?.isTop == true ? "TOP" : "BOTTOM")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Game Controls
                HStack(spacing: 8) {
                    Button("Undo") {
                        sessionManager.undoLastThrow()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .disabled(sessionManager.currentSession?.throwHistory.isEmpty ?? true)
                    
                    Button("Reset Half") {
                        sessionManager.resetHalfInning()
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
            }
            
            // Team Scores
            HStack(spacing: 16) {
                // Away Team
                VStack(spacing: 4) {
                    Text(sessionManager.currentSession?.awayTeam ?? "Away")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("\(sessionManager.currentSession?.awayScore ?? 0)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 4) {
                        Text("👑")
                        Text("\(sessionManager.currentSession?.awayKings ?? 0)")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                
                Text("-")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                // Home Team
                VStack(spacing: 4) {
                    Text(sessionManager.currentSession?.homeTeam ?? "Home")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("\(sessionManager.currentSession?.homeScore ?? 0)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 4) {
                        Text("👑")
                        Text("\(sessionManager.currentSession?.homeKings ?? 0)")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

struct BaseballKubbGameStateView: View {
    @ObservedObject var sessionManager: BaseballKubbSessionManager
    
    var body: some View {
        VStack(spacing: 16) {
            // Field Info
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("FIELD KUBBS")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    Text("\(sessionManager.currentSession?.fieldKubbs ?? 0)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("BASELINE")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    Text("\(sessionManager.currentSession?.currentBaselineKubbs ?? 5)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            }
            
            // Throw Info
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("BATONS")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Text("\(sessionManager.currentSession?.batonCount ?? 0)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("/\(sessionManager.currentSession?.batonLimit == 999 ? "∞" : "\(sessionManager.currentSession?.batonLimit ?? 6)")")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("MISSES")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Text("\(sessionManager.currentSession?.missCount ?? 0)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("/3")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

struct BaseballKubbThrowControlsView: View {
    @ObservedObject var sessionManager: BaseballKubbSessionManager
    @Binding var showingHitModal: Bool
    @Binding var showingHalfSummary: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Baton \(sessionManager.currentSession?.currentBaton ?? 1)")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 16) {
                Button(action: {
                    sessionManager.recordMiss()
                    checkHalfInningEnd()
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.red)
                        
                        Text("MISS")
                            .font(.headline)
                            .foregroundColor(.red)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
                }
                .disabled(sessionManager.currentSession?.isHalfInningOver ?? false)
                
                Button(action: {
                    showingHitModal = true
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.green)
                        
                        Text("HIT")
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                }
                .disabled(sessionManager.currentSession?.isHalfInningOver ?? false)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
    
    private func checkHalfInningEnd() {
        if sessionManager.currentSession?.isHalfInningOver == true {
            sessionManager.endHalfInning()
            showingHalfSummary = true
        }
    }
}

struct BaseballKubbHitModalView: View {
    @ObservedObject var sessionManager: BaseballKubbSessionManager
    @Binding var showingHitModal: Bool
    @Binding var showingHalfSummary: Bool
    @StateObject private var skinManager = SkinManager.shared
    @State private var fieldKubbsHit = 0
    @State private var baselineKubbsHit = 0
    @State private var kingHit = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                Text("What was knocked down?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                // Visual Kubb Layout
                BaseballKubbVisualHitView(
                    sessionManager: sessionManager,
                    skinManager: skinManager,
                    fieldKubbsHit: $fieldKubbsHit,
                    baselineKubbsHit: $baselineKubbsHit,
                    kingHit: $kingHit
                )
                
                Spacer()
                
                // Action Buttons
                HStack(spacing: 16) {
                    Button("Cancel") {
                        showingHitModal = false
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    
                    Button("Confirm") {
                        confirmHit()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding(.bottom)
            }
            .padding()
            .navigationTitle("Hit Details")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func confirmHit() {
        // Validation
        if fieldKubbsHit > (sessionManager.currentSession?.fieldKubbs ?? 0) {
            errorMessage = "Cannot hit more than \(sessionManager.currentSession?.fieldKubbs ?? 0) field kubbs"
            showingError = true
            return
        }
        
        if baselineKubbsHit > (sessionManager.currentSession?.currentBaselineKubbs ?? 0) {
            errorMessage = "Cannot hit more than \(sessionManager.currentSession?.currentBaselineKubbs ?? 0) baseline kubbs"
            showingError = true
            return
        }
        
        if fieldKubbsHit == 0 && baselineKubbsHit == 0 && !kingHit {
            errorMessage = "Must hit at least one kubb"
            showingError = true
            return
        }
        
        // Updated validation: Allow baseline kubbs ONLY if field kubbs will be cleared this throw
        let fieldKubbsRemaining = (sessionManager.currentSession?.fieldKubbs ?? 0) - fieldKubbsHit
        if fieldKubbsRemaining > 0 && baselineKubbsHit > 0 {
            errorMessage = "Must clear all field kubbs before hitting baseline kubbs"
            showingError = true
            return
        }
        
        if kingHit && (fieldKubbsRemaining > 0 || (sessionManager.currentSession?.currentBaselineKubbs ?? 0) - baselineKubbsHit > 0) {
            errorMessage = "Must clear all kubbs before hitting the king"
            showingError = true
            return
        }
        
        // Process the hit
        sessionManager.recordHit(fieldKubbsHit: fieldKubbsHit, baselineKubbsHit: baselineKubbsHit, kingHit: kingHit)
        sessionManager.checkGameEnd()
        
        // Check if half inning should end after recording the hit
        checkHalfInningEnd()
        
        // Reset modal state
        fieldKubbsHit = 0
        baselineKubbsHit = 0
        kingHit = false
        showingHitModal = false
    }
    
    private func checkHalfInningEnd() {
        if sessionManager.currentSession?.isHalfInningOver == true {
            sessionManager.endHalfInning()
            showingHalfSummary = true
        }
    }
}

struct BaseballKubbScoreboardTable: View {
    let session: BaseballKubbSession
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 0) {
                Text("Team")
                    .font(.caption)
                    .fontWeight(.bold)
                    .frame(width: 60, alignment: .leading)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                
                ForEach(1...9, id: \.self) { inning in
                    Text("\(inning)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
            }
            .background(Color(.systemGray5))
            
            // Away team row
            HStack(spacing: 0) {
                Text("Away")
                    .font(.caption)
                    .fontWeight(.medium)
                    .frame(width: 60, alignment: .leading)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                
                ForEach(1...9, id: \.self) { inning in
                    let halfInningIndex = (inning - 1) * 2 // Top half
                    let data = halfInningIndex < session.scoreboardData.count ? session.scoreboardData[halfInningIndex] : (awayRuns: 0, awayKings: 0, homeRuns: 0, homeKings: 0)
                    let isMostRecent = isMostRecentHalfInning(inning: inning, isTop: true)
                    let hasBeenPlayed = hasHalfInningBeenPlayed(inning: inning, isTop: true)
                    
                    Text(formatScore(runs: data.awayRuns, kings: data.awayKings, hasBeenPlayed: hasBeenPlayed))
                        .font(.caption)
                        .fontWeight(isMostRecent ? .bold : .regular)
                        .foregroundColor(isMostRecent ? .blue : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
            }
            .background(Color(.systemGray6))
            
            // Home team row
            HStack(spacing: 0) {
                Text("Home")
                    .font(.caption)
                    .fontWeight(.medium)
                    .frame(width: 60, alignment: .leading)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                
                ForEach(1...9, id: \.self) { inning in
                    let halfInningIndex = (inning - 1) * 2 + 1 // Bottom half
                    let data = halfInningIndex < session.scoreboardData.count ? session.scoreboardData[halfInningIndex] : (awayRuns: 0, awayKings: 0, homeRuns: 0, homeKings: 0)
                    let isMostRecent = isMostRecentHalfInning(inning: inning, isTop: false)
                    let hasBeenPlayed = hasHalfInningBeenPlayed(inning: inning, isTop: false)
                    
                    Text(formatScore(runs: data.homeRuns, kings: data.homeKings, hasBeenPlayed: hasBeenPlayed))
                        .font(.caption)
                        .fontWeight(isMostRecent ? .bold : .regular)
                        .foregroundColor(isMostRecent ? .blue : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
            }
            .background(Color(.systemBackground))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
        .cornerRadius(8)
    }
    
    private func formatScore(runs: Int, kings: Int, hasBeenPlayed: Bool) -> String {
        if !hasBeenPlayed {
            return ""
        } else if runs == 0 {
            return "0"
        } else if kings > 0 {
            return "\(runs)(K)"
        } else {
            return "\(runs)"
        }
    }
    
    private func hasHalfInningBeenPlayed(inning: Int, isTop: Bool) -> Bool {
        let currentInning = session.currentInning
        let currentIsTop = session.isTop
        
        // If we're past this inning, it has been played
        if currentInning > inning {
            return true
        }
        
        // If we're in the same inning
        if currentInning == inning {
            if isTop && !currentIsTop {
                return true // We're in bottom half, so top half was played
            }
            if !isTop && currentIsTop {
                return false // We're in top half, so bottom half hasn't been played yet
            }
            if isTop && currentIsTop {
                // We're currently in the top half - check if it's completed
                return session.isHalfInningOver
            }
            if !isTop && !currentIsTop {
                // We're currently in the bottom half - check if it's completed
                return session.isHalfInningOver
            }
        }
        
        // If we're in the top of the next inning, the bottom of the previous inning was played
        if currentInning == inning + 1 && currentIsTop && !isTop {
            return true
        }
        
        // If we're before this inning, it hasn't been played
        return false
    }
    
    private func isMostRecentHalfInning(inning: Int, isTop: Bool) -> Bool {
        // Check if this is the most recently completed half-inning
        let currentInning = session.currentInning
        let currentIsTop = session.isTop
        
        // If we're currently in the middle of an inning, check if it's completed
        if currentInning == inning && currentIsTop == isTop {
            // This is the current half-inning - highlight it if it's completed
            return session.isHalfInningOver
        }
        
        // If we're in the bottom of an inning, highlight the top of the same inning
        // BUT only if the bottom half hasn't been completed yet
        if currentInning == inning && !currentIsTop && isTop {
            return !session.isHalfInningOver
        }
        
        // If we're in the top of the next inning, highlight the bottom of the previous inning
        if currentInning == inning + 1 && currentIsTop && !isTop {
            return true
        }
        
        // Special case: if we just completed the bottom of an inning and are now in the top of the next inning,
        // highlight the bottom of the previous inning
        if currentInning == inning + 1 && currentIsTop && inning == currentInning - 1 && !isTop {
            return true
        }
        
        return false
    }
}

struct BaseballKubbHalfSummaryView: View {
    @ObservedObject var sessionManager: BaseballKubbSessionManager
    @Binding var showingHalfSummary: Bool
    
    private var completionTitle: String {
        guard let session = sessionManager.currentSession else { return "Half Inning Complete" }
        
        let inning = session.currentInning
        let isTop = session.isTop
        
        if isTop {
            return "Middle of the \(ordinalInning(inning))"
        } else {
            return "After \(inning) \(inning == 1 ? "Inning" : "Innings")"
        }
    }
    
    private var statsSectionTitle: String {
        guard let session = sessionManager.currentSession else { return "Half Inning Stats" }
        
        let inning = session.currentInning
        let isTop = session.isTop
        
        if isTop {
            return "Top of \(ordinalInning(inning)) Stats"
        } else {
            return "Bottom of \(ordinalInning(inning)) Stats"
        }
    }
    
    private func ordinalInning(_ inning: Int) -> String {
        switch inning {
        case 1: return "1st"
        case 2: return "2nd"
        case 3: return "3rd"
        case 4: return "4th"
        case 5: return "5th"
        case 6: return "6th"
        case 7: return "7th"
        case 8: return "8th"
        case 9: return "9th"
        default: return "\(inning)th"
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text(completionTitle)
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Team info section
                if let session = sessionManager.currentSession {
                    HStack(alignment: .top, spacing: 16) {
                        // Away team info
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Away")
                                .font(.headline)
                                .fontWeight(.bold)
                            
                            Text(session.awayTeam)
                                .font(.subheadline)
                                .multilineTextAlignment(.leading)
                            
                            Text("Total: \(session.awayScore)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("Kings: \(session.awayKings)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Home team info
                        VStack(alignment: .trailing, spacing: 8) {
                            Text("Home")
                                .font(.headline)
                                .fontWeight(.bold)
                            
                            Text(session.homeTeam)
                                .font(.subheadline)
                                .multilineTextAlignment(.trailing)
                            
                            Text("Total: \(session.homeScore)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("Kings: \(session.homeKings)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                // Baseball-style scoreboard
                if let session = sessionManager.currentSession, !session.scoreboardData.isEmpty {
                    BaseballKubbScoreboardTable(session: session)
                }
                
                VStack(spacing: 16) {
                    Text(statsSectionTitle)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack {
                        Text("Runs Scored:")
                        Spacer()
                        Text("\(sessionManager.currentSession?.halfInningRuns ?? 0)")
                            .fontWeight(.bold)
                    }
                    
                    HStack {
                        Text("Kings Hit:")
                        Spacer()
                        Text("\(sessionManager.currentSession?.halfInningKings ?? 0)")
                            .fontWeight(.bold)
                    }
                    
                    HStack {
                        Text("Batons Used:")
                        Spacer()
                        Text("\(sessionManager.currentSession?.batonCount ?? 0)")
                            .fontWeight(.bold)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Button("Next Half") {
                    sessionManager.nextHalf()
                    showingHalfSummary = false
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding()
        }
    }
}

struct BaseballKubbAbandonConfirmationView: View {
    let session: BaseballKubbSession
    @ObservedObject var sessionManager: BaseballKubbSessionManager
    @Binding var showingAbandonConfirmation: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    Text("Are you sure you wish to abandon this game?")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    // Team info section
                    HStack(alignment: .top, spacing: 16) {
                        // Away team info
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Away")
                                .font(.headline)
                                .fontWeight(.bold)
                            
                            Text(session.awayTeam)
                                .font(.subheadline)
                                .multilineTextAlignment(.leading)
                            
                            Text("Total: \(session.awayScore)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("Kings: \(session.awayKings)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Home team info
                        VStack(alignment: .trailing, spacing: 8) {
                            Text("Home")
                                .font(.headline)
                                .fontWeight(.bold)
                            
                            Text(session.homeTeam)
                                .font(.subheadline)
                                .multilineTextAlignment(.trailing)
                            
                            Text("Total: \(session.homeScore)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("Kings: \(session.homeKings)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Baseball-style scoreboard
                    if !session.scoreboardData.isEmpty {
                        BaseballKubbScoreboardTable(session: session)
                    }
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        Button("No, Keep Game in Progress") {
                            showingAbandonConfirmation = false
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        
                        Button("Yes, Mark Game as Abandoned") {
                            sessionManager.abandonGame()
                            showingAbandonConfirmation = false
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                }
                .padding()
            }
            .navigationTitle("Abandon Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        showingAbandonConfirmation = false
                    }
                }
            }
        }
    }
}

struct CircularButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .frame(width: 44, height: 44)
            .background(Color.blue)
            .clipShape(Circle())
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}



struct BaseballKubbGameEndView: View {
    @ObservedObject var sessionManager: BaseballKubbSessionManager
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Game Over!")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            if let session = sessionManager.currentSession {
                VStack(spacing: 16) {
                    Text("Winner: \(session.winner == "away" ? session.awayTeam : session.homeTeam)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    VStack(spacing: 12) {
                        HStack {
                            Text(session.awayTeam)
                            Spacer()
                            Text("\(session.awayScore)")
                                .fontWeight(.bold)
                            Text("(👑 \(session.awayKings))")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text(session.homeTeam)
                            Spacer()
                            Text("\(session.homeScore)")
                                .fontWeight(.bold)
                            Text("(👑 \(session.homeKings))")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
            
            Button("New Game") {
                sessionManager.resetSession()
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding()
    }
}

struct BaseballKubbMenuView: View {
    @ObservedObject var sessionManager: BaseballKubbSessionManager
    @Binding var showingMenu: Bool
    @State private var showingNewGameAlert = false
    @State private var showingTutorial = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Game Menu")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack(spacing: 16) {
                    Button("Continue Game") {
                        showingMenu = false
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    
                    Button("View Rules") {
                        showingTutorial = true
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    
                    Button("New Game") {
                        showingNewGameAlert = true
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
            .padding()
            .navigationTitle("Menu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingMenu = false
                    }
                }
            }
            .alert("New Game", isPresented: $showingNewGameAlert) {
                Button("Cancel", role: .cancel) { }
                Button("New Game", role: .destructive) {
                    sessionManager.resetSession()
                    showingMenu = false
                }
            } message: {
                Text("Are you sure you want to start a new game? All current progress will be lost.")
            }
        }
        .fullScreenCover(isPresented: $showingTutorial) {
            BaseballKubbTutorialView()
        }
    }
}

// MARK: - Visual Hit Recording View

struct BaseballKubbVisualHitView: View {
    @ObservedObject var sessionManager: BaseballKubbSessionManager
    @ObservedObject var skinManager: SkinManager
    @Binding var fieldKubbsHit: Int
    @Binding var baselineKubbsHit: Int
    @Binding var kingHit: Bool
    
    @State private var fieldKubbsHitSet: Set<Int> = []
    @State private var baselineKubbsHitSet: Set<Int> = []
    
    private var fieldKubbsRemaining: Int {
        (sessionManager.currentSession?.fieldKubbs ?? 0) - fieldKubbsHitSet.count
    }
    
    private var baselineKubbsRemaining: Int {
        (sessionManager.currentSession?.currentBaselineKubbs ?? 0) - baselineKubbsHitSet.count
    }
    
    private var canHitBaseline: Bool {
        fieldKubbsRemaining == 0
    }
    
    private var canHitKing: Bool {
        fieldKubbsRemaining == 0 && baselineKubbsRemaining == 0
    }
    
    private func toggleFieldKubbHit(at index: Int) {
        if fieldKubbsHitSet.contains(index) {
            fieldKubbsHitSet.remove(index)
        } else {
            fieldKubbsHitSet.insert(index)
        }
        fieldKubbsHit = fieldKubbsHitSet.count
    }
    
    private func toggleBaselineKubbHit(at index: Int) {
        if baselineKubbsHitSet.contains(index) {
            baselineKubbsHitSet.remove(index)
        } else {
            baselineKubbsHitSet.insert(index)
        }
        baselineKubbsHit = baselineKubbsHitSet.count
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Baseline Kubbs at top
                if baselineKubbsRemaining > 0 {
                    VStack(spacing: 8) {
                        Text("Baseline Kubbs")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 12) {
                            ForEach(0..<(sessionManager.currentSession?.currentBaselineKubbs ?? 0), id: \.self) { index in
                                KubbVisualView(
                                    skin: skinManager.selectedKubbSkin,
                                    isHit: baselineKubbsHitSet.contains(index),
                                    isEnabled: canHitBaseline,
                                    size: 50
                                )
                                .onTapGesture {
                                    if canHitBaseline {
                                        toggleBaselineKubbHit(at: index)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.top, 20)
                }
                
                Spacer()
                
                // Field Kubbs in center
                if fieldKubbsRemaining > 0 {
                    VStack(spacing: 8) {
                        Text("Field Kubbs")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 12) {
                            ForEach(0..<(sessionManager.currentSession?.fieldKubbs ?? 0), id: \.self) { index in
                                KubbVisualView(
                                    skin: skinManager.selectedKubbSkin,
                                    isHit: fieldKubbsHitSet.contains(index),
                                    isEnabled: true,
                                    size: 60
                                )
                                .onTapGesture {
                                    toggleFieldKubbHit(at: index)
                                }
                            }
                        }
                    }
                }
                
                Spacer()
                
                // King Kubb at bottom (only if all others are cleared)
                if canHitKing {
                    VStack(spacing: 8) {
                        Text("King Kubb")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        KingVisualView(
                            skin: skinManager.selectedKingSkin,
                            isHit: kingHit,
                            isEnabled: true,
                            size: 80
                        )
                        .onTapGesture {
                            kingHit.toggle()
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .frame(height: 400)
        .onAppear {
            // Reset hit sets when the view appears
            fieldKubbsHitSet.removeAll()
            baselineKubbsHitSet.removeAll()
            fieldKubbsHit = 0
            baselineKubbsHit = 0
            kingHit = false
        }
    }
}

// MARK: - Kubb Visual Components

struct KubbVisualView: View {
    let skin: KubbSkin
    let isHit: Bool
    let isEnabled: Bool
    let size: CGFloat
    @State private var selectedImageName: String?
    
    var body: some View {
        ZStack {
            // Kubb visual
            if let kubbImageName = selectedImageName {
                // Image-based kubb
                Image(kubbImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size * 0.6, height: size)
                    .scaleEffect(skin.kubbImageScale)
                    .opacity(isHit ? 0.3 : 1.0)
                    .rotationEffect(.degrees(isHit ? 90 : 0))
                    .animation(.easeInOut(duration: 0.3), value: isHit)
            } else {
                // Color-based kubb
                RoundedRectangle(cornerRadius: 6)
                    .fill(skin.kubbColor.color)
                    .frame(width: size * 0.4, height: size)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(skin.kubbAccentColor?.color ?? Color.white, lineWidth: 2)
                    )
                    .opacity(isHit ? 0.3 : 1.0)
                    .rotationEffect(.degrees(isHit ? 90 : 0))
                    .animation(.easeInOut(duration: 0.3), value: isHit)
            }
            
            // Hit indicator
            if isHit {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                    .background(Color.white)
                    .clipShape(Circle())
            }
        }
        .opacity(isEnabled ? 1.0 : 0.5)
        .scaleEffect(isEnabled ? 1.0 : 0.9)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
        .onAppear {
            selectImage()
        }
    }
    
    private func selectImage() {
        // Use SkinManager for consistent multi-skin selection across all views
        let skinManager = SkinManager.shared
        selectedImageName = skinManager.getRandomKubbImageName(for: 0) // Default to index 0 for KubbVisualView
    }
}

struct KingVisualView: View {
    let skin: KubbSkin
    let isHit: Bool
    let isEnabled: Bool
    let size: CGFloat
    @State private var selectedImageName: String?
    
    var body: some View {
        ZStack {
            // King visual
            if let kingImageName = selectedImageName {
                // Image-based king
                Image(kingImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size * 0.6, height: size)
                    .scaleEffect(skin.kingImageScale)
                    .opacity(isHit ? 0.3 : 1.0)
                    .rotationEffect(.degrees(isHit ? 90 : 0))
                    .animation(.easeInOut(duration: 0.3), value: isHit)
            } else {
                // Color-based king
                RoundedRectangle(cornerRadius: 10)
                    .fill(skin.kingColor.color)
                    .frame(width: size * 0.5, height: size)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(skin.kingAccentColor?.color ?? Color.white, lineWidth: 3)
                    )
                    .overlay(
                        Image(systemName: "crown.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    )
                    .opacity(isHit ? 0.3 : 1.0)
                    .rotationEffect(.degrees(isHit ? 90 : 0))
                    .animation(.easeInOut(duration: 0.3), value: isHit)
            }
            
            // Hit indicator
            if isHit {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.green)
                    .background(Color.white)
                    .clipShape(Circle())
            }
        }
        .opacity(isEnabled ? 1.0 : 0.5)
        .scaleEffect(isEnabled ? 1.0 : 0.9)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
        .onAppear {
            selectImage()
        }
    }
    
    private func selectImage() {
        // Use SkinManager for consistent multi-skin selection across all views
        let skinManager = SkinManager.shared
        selectedImageName = skinManager.getRandomKingImageName()
    }
}

#Preview {
    BaseballKubbView()
}
