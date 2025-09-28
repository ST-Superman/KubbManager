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
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                BaseballKubbHeaderView()
                
                // Main Content
                if sessionManager.currentSession == nil {
                    BaseballKubbStartView(sessionManager: sessionManager)
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
                    Button("Close") {
                        dismiss()
                    }
                }
                
                if sessionManager.currentSession != nil && sessionManager.currentSession?.gameOver != true {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Menu") {
                            showingMenu = true
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
    @State private var awayTeam = ""
    @State private var homeTeam = ""
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
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
            }
            
            Spacer()
            
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
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            
                            Button("Abandon Game") {
                                sessionManager.abandonGame()
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
                
                Button(action: startGame) {
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
            
            Spacer()
        }
    }
    
    private var canStartGame: Bool {
        !awayTeam.isEmpty && !homeTeam.isEmpty && awayTeam != homeTeam
    }
    
    private func startGame() {
        sessionManager.startNewGame(awayTeam: awayTeam, homeTeam: homeTeam)
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
    @State private var fieldKubbsHit = 0
    @State private var baselineKubbsHit = 0
    @State private var kingHit = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("What was knocked down?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                VStack(spacing: 16) {
                    // Field Kubbs
                    HStack {
                        Text("Field Kubbs:")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack(spacing: 12) {
                            Button("-") {
                                if fieldKubbsHit > 0 {
                                    fieldKubbsHit -= 1
                                }
                            }
                            .buttonStyle(CircularButtonStyle())
                            
                            Text("\(fieldKubbsHit)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .frame(minWidth: 40)
                            
                            Button("+") {
                                if fieldKubbsHit < (sessionManager.currentSession?.fieldKubbs ?? 0) {
                                    fieldKubbsHit += 1
                                }
                            }
                            .buttonStyle(CircularButtonStyle())
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Baseline Kubbs
                    HStack {
                        Text("Baseline Kubbs:")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack(spacing: 12) {
                            Button("-") {
                                if baselineKubbsHit > 0 {
                                    baselineKubbsHit -= 1
                                }
                            }
                            .buttonStyle(CircularButtonStyle())
                            
                            Text("\(baselineKubbsHit)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .frame(minWidth: 40)
                            
                            Button("+") {
                                if baselineKubbsHit < (sessionManager.currentSession?.currentBaselineKubbs ?? 0) {
                                    baselineKubbsHit += 1
                                }
                            }
                            .buttonStyle(CircularButtonStyle())
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // King Hit
                    HStack {
                        Text("King Hit:")
                            .font(.headline)
                        
                        Spacer()
                        
                        Toggle("", isOn: $kingHit)
                            .toggleStyle(SwitchToggleStyle())
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                Spacer()
                
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


struct BaseballKubbHalfSummaryView: View {
    @ObservedObject var sessionManager: BaseballKubbSessionManager
    @Binding var showingHalfSummary: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Half Inning Complete")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
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
    }
}

#Preview {
    BaseballKubbView()
}

