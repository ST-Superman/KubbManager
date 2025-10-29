//
//  ContentView.swift
//  Kubb Manager Watch
//
//  Created by AI Assistant on 10/8/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var connectivityManager: WatchConnectivityManager
    @State private var showingBatonInput = false
    @State private var showingInkastInput = false
    @State private var showingRoundComplete = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                backgroundGradient
                
                // Main content
                if let sessionState = connectivityManager.currentSessionState {
                    activeSessionView(sessionState)
                } else {
                    noSessionView
                }
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showingBatonInput) {
            if let context = connectivityManager.pendingBatonContext {
                BatonThrowInputView(context: context)
                    .environmentObject(connectivityManager)
            }
        }
        .sheet(isPresented: $showingInkastInput) {
            if let context = connectivityManager.pendingInkastContext {
                InkastInputView(context: context)
                    .environmentObject(connectivityManager)
            }
        }
        .sheet(isPresented: $showingRoundComplete) {
            RoundCompleteView()
                .environmentObject(connectivityManager)
        }
        .onChange(of: connectivityManager.pendingBatonContext) { oldContext, newContext in
            // In Watch Mode, automatically show input sheet when baton context arrives
            if connectivityManager.isWatchMode && newContext != nil {
                // Always show input, even if context appears similar
                // (dismiss first to ensure sheet reopens)
                showingBatonInput = false
                showingRoundComplete = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showingBatonInput = true
                }
            } else if newContext == nil {
                // Clear the sheet when context is cleared
                showingBatonInput = false
            }
        }
        .onChange(of: connectivityManager.pendingInkastContext) { oldContext, newContext in
            // In Watch Mode, automatically show input sheet when inkast context arrives
            if connectivityManager.isWatchMode && newContext != nil {
                // Always show input, even if context appears similar
                // (dismiss first to ensure sheet reopens)
                showingInkastInput = false
                showingRoundComplete = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showingInkastInput = true
                }
            } else if newContext == nil {
                // Clear the sheet when context is cleared
                showingInkastInput = false
            }
        }
        .onChange(of: connectivityManager.currentSessionState) { _, newState in
            if let state = newState, state.isWatchMode {
                if state.currentPhase == "Round Complete" || state.currentPhase == "Half Inning Complete" {
                    showingRoundComplete = true
                } else {
                    // Dismiss round complete view when phase changes (e.g., next round starts)
                    showingRoundComplete = false
                }
            }
        }
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.blue.opacity(0.7),
                Color.blue.opacity(0.5)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Active Session View
    
    private func activeSessionView(_ state: WatchSessionState) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 8)
            
            // Session Header
            VStack(spacing: 4) {
                Text(state.sessionType)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                if let currentRound = state.currentRound {
                    HStack(spacing: 4) {
                        if let team = state.currentAttackingTeam {
                            Text("Team \(team)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white.opacity(0.95))
                        }
                        Text("Round \(currentRound)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.85))
                    }
                }
                
                // A-Line Status Badge
                if state.hasALine == true {
                    HStack(spacing: 3) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 9, weight: .bold))
                        Text("A-LINE")
                            .font(.system(size: 9, weight: .black))
                            .tracking(0.5)
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(Color.yellow)
                    )
                }
            }
            .padding(.top, 8)
            
            Spacer()
            
            // Current Phase Action
            if let phase = state.currentPhase {
                // In Watch Mode, hide the manual button since input auto-shows
                if !connectivityManager.isWatchMode || !connectivityManager.hasPendingInput {
                    actionButton(for: phase, state: state)
                        .padding(.horizontal, 12)
                }
            }
            
            Spacer()
            
            // Connection Status
            statusBar
                .padding(.bottom, 8)
        }
    }
    
    // MARK: - Action Button
    
    private func actionButton(for phase: String, state: WatchSessionState) -> some View {
        Button(action: {
            // Don't allow new input while sending
            guard !connectivityManager.isSendingResult else { return }
            
            WKInterfaceDevice.current().play(.click)
            if connectivityManager.pendingBatonContext != nil {
                showingBatonInput = true
            } else if connectivityManager.pendingInkastContext != nil {
                showingInkastInput = true
            }
        }) {
            VStack(spacing: 6) {
                // Icon
                Group {
                    let iconName = iconNameForPhase(phase)
                    if iconName == "KubbInkast" || iconName == "KubbBaton" {
                        // Custom assets
                        Image(iconName)
                    } else {
                        // System symbols
                        Image(systemName: iconName)
                    }
                }
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(.white)
                .frame(height: 32)
                
                // Phase name
                Text(phase)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                // Action prompt
                actionPrompt
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.25))
                    )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(connectivityManager.hasPendingInput ? 0.25 : 0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Color.white.opacity(connectivityManager.hasPendingInput ? 0.6 : 0.3), lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(connectivityManager.hasPendingInput ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: connectivityManager.hasPendingInput)
    }
    
    private func iconNameForPhase(_ phase: String) -> String {
        switch phase.lowercased() {
        case "inkast":
            return "KubbInkast"
        case "blast", "blasting":
            return "KubbBaton"
        case "8-meter", "8meter", "eight-meter", "throwing":
            return "target"
        default:
            return "target"
        }
    }
    
    private var actionPrompt: some View {
        Group {
            if connectivityManager.hasPendingInput {
                if let inkastContext = connectivityManager.pendingInkastContext {
                    Text("Inkast \(inkastContext.maxCount) kubbs")
                } else if let batonContext = connectivityManager.pendingBatonContext {
                    if let totalBatons = batonContext.totalBatons, totalBatons == 2 {
                        Text("2 batons")
                    } else {
                        Text("TAP TO RECORD")
                    }
                } else {
                    Text("TAP TO RECORD")
                }
            } else if connectivityManager.isSendingResult {
                HStack(spacing: 4) {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("SENDING...")
                }
                .foregroundColor(.white.opacity(0.9))
            } else {
                Text("Waiting...")
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }
    
    // MARK: - Status Bar
    
    private var statusBar: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(connectivityManager.isPhoneReachable ? Color.green : Color.red)
                .frame(width: 6, height: 6)
            
            if connectivityManager.isWatchMode {
                Text("WATCH MODE")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.yellow)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.yellow.opacity(0.2))
                    )
            } else {
                Text(connectivityManager.isPhoneReachable ? "Connected" : "Disconnected")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
    
    // MARK: - No Session View
    
    private var noSessionView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "applewatch.watchface")
                .font(.system(size: 40, weight: .light))
                .foregroundColor(.white.opacity(0.6))
            
            VStack(spacing: 4) {
                Text("No Active Session")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Start a session on your iPhone")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            Spacer()
            
            // Connection Status
            HStack(spacing: 4) {
                Circle()
                    .fill(connectivityManager.isPhoneReachable ? Color.green : Color.red)
                    .frame(width: 6, height: 6)
                
                Text(connectivityManager.isPhoneReachable ? "Connected" : "Disconnected")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.bottom, 8)
        }
    }
}

// MARK: - Round Complete View

struct RoundCompleteView: View {
    @EnvironmentObject var connectivityManager: WatchConnectivityManager
    @Environment(\.dismiss) private var dismiss
    
    private var roundCompleteText: String {
        if let phase = connectivityManager.currentSessionState?.currentPhase {
            if phase == "Half Inning Complete" {
                return "Half Inning\nComplete"
            }
        }
        return "Round\nComplete"
    }
    
    private var showEndButton: Bool {
        guard let state = connectivityManager.currentSessionState else { return false }
        
        // Show End Session button for inkast/blast sessions or when target is reached
        let isInkastBlastSession = state.sessionType.lowercased().contains("inkast") || 
                                  state.sessionType.lowercased().contains("blast")
        
        return isInkastBlastSession || state.isTargetReached
    }
    
    private var progressText: String? {
        guard let state = connectivityManager.currentSessionState else { return nil }
        
        let isInkastBlastSession = state.sessionType.lowercased().contains("inkast") || 
                                  state.sessionType.lowercased().contains("blast")
        
        if isInkastBlastSession {
            // For inkast/blast sessions, show current round info
            if let currentRound = state.currentRound {
                return "Round \(currentRound)"
            }
            return nil
        } else {
            // For other sessions, show baton progress
            guard let current = state.currentBatons,
                  let target = state.targetBatons else {
                return nil
            }
            return "\(current) / \(target) batons"
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.green.opacity(0.3),
                        Color.blue.opacity(0.2)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 12) {
                    Spacer(minLength: 8)
                    
                    // Icon and title
                    VStack(spacing: 8) {
                        Image(systemName: showEndButton ? "star.circle.fill" : "checkmark.circle.fill")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(showEndButton ? .yellow : .green)
                        
                        Text(roundCompleteText)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                        
                        if let progress = progressText {
                            Text(progress)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        if showEndButton {
                            let statusText = connectivityManager.currentSessionState?.isTargetReached == true ? "Target Reached!" : "Round Complete"
                            Text(statusText)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.yellow)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(Color.yellow.opacity(0.2))
                                )
                        }
                    }
                    
                    Spacer()
                    
                    // Action buttons
                    VStack(spacing: 8) {
                        Button(action: {
                            continueToNextRound()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 14))
                                Text("Next Round")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.blue)
                            )
                        }
                        .buttonStyle(.plain)
                        
                        if showEndButton {
                            Button(action: {
                                endSession()
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "stop.circle.fill")
                                        .font(.system(size: 14))
                                    Text("End Session")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.red)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private func endSession() {
        WKInterfaceDevice.current().play(.success)
        connectivityManager.endSession()
        dismiss()
    }
    
    private func continueToNextRound() {
        WKInterfaceDevice.current().play(.success)
        connectivityManager.continueToNextRound()
        dismiss()
    }
}

#Preview {
    ContentView()
        .environmentObject(WatchConnectivityManager.shared)
}
