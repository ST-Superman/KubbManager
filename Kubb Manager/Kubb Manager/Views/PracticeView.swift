//
//  PracticeView.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 9/23/25.
//

import SwiftUI

struct PracticeView: View {
    @EnvironmentObject private var sessionManager: SessionManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingEndSessionAlert = false
    @State private var showingResetRoundAlert = false
    @State private var showingTargetReachedAlert = false
    
    private let hapticSuccess = UINotificationFeedbackGenerator()
    private let hapticError = UINotificationFeedbackGenerator()
    private let hapticImpact = UIImpactFeedbackGenerator(style: .medium)
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 24) {
                        // Progress Section
                        ProgressSection()
                            .environmentObject(sessionManager)
                        
                        // Kubb Grid Section
                        KubbGridSection()
                            .environmentObject(sessionManager)
                        
                        // Baton Controls Section
                        BatonControlsSection()
                            .environmentObject(sessionManager)
                        
                        // Session Controls Section
                        SessionControlsSection()
                            .environmentObject(sessionManager)
                    }
                    .padding()
                }
            }
            .navigationTitle("Practice Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("End Session") {
                        showingEndSessionAlert = true
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .alert("End Session", isPresented: $showingEndSessionAlert) {
            Button("Cancel", role: .cancel) { }
            Button("End Session", role: .destructive) {
                Task {
                    await sessionManager.endSessionEarly()
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to end this practice session? Your progress will be saved and you can resume it later if it's from today.")
        }
        .alert("Reset Round", isPresented: $showingResetRoundAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset Round", role: .destructive) {
                Task {
                    await sessionManager.resetCurrentRound()
                }
            }
        } message: {
            Text("Are you sure you want to reset the current round? This will clear all progress for this round.")
        }
        .alert("Target Reached!", isPresented: $showingTargetReachedAlert) {
            Button("Continue Practice") { }
            Button("End Session") {
                Task {
                    await sessionManager.completeSession()
                    dismiss()
                }
            }
        } message: {
            Text("Congratulations! You've reached your target of \(sessionManager.target) kubbs! 🎉")
        }
        .onChange(of: sessionManager.isTargetReached) { _, isReached in
            if isReached {
                hapticSuccess.notificationOccurred(.success)
                showingTargetReachedAlert = true
            }
        }
    }
}

struct ProgressSection: View {
    @EnvironmentObject private var sessionManager: SessionManager
    
    var body: some View {
        VStack(spacing: 16) {
            // Progress Bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Progress")
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("\(sessionManager.totalKubbs) / \(sessionManager.target)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                
                ProgressView(value: sessionManager.progressPercentage)
                    .progressViewStyle(LinearProgressViewStyle(tint: progressColor))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
            }
            
            // Statistics Row
            HStack(spacing: 20) {
                StatisticItem(
                    title: "Accuracy",
                    value: String(format: "%.1f%%", sessionManager.accuracy * 100),
                    icon: "target",
                    color: accuracyColor
                )
                
                StatisticItem(
                    title: "Batons",
                    value: "\(sessionManager.totalBatons)",
                    icon: "bolt",
                    color: .orange
                )
                
                StatisticItem(
                    title: "Rounds",
                    value: "\(sessionManager.currentSession?.completedRounds.count ?? 0)",
                    icon: "arrow.clockwise",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private var progressColor: Color {
        let percentage = sessionManager.progressPercentage
        if percentage >= 1.0 {
            return .green
        } else if percentage >= 0.7 {
            return .blue
        } else if percentage >= 0.4 {
            return .orange
        } else {
            return .red
        }
    }
    
    private var accuracyColor: Color {
        let accuracy = sessionManager.accuracy
        if accuracy >= 0.7 {
            return .green
        } else if accuracy >= 0.5 {
            return .orange
        } else {
            return .red
        }
    }
}

struct StatisticItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct KubbGridSection: View {
    @EnvironmentObject private var sessionManager: SessionManager
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Current Round")
                .font(.headline)
            
            VStack(spacing: 12) {
                // First line: 5 regular kubbs
                HStack(spacing: 12) {
                    ForEach(0..<5, id: \.self) { index in
                        KubbView(
                            number: index + 1,
                            isKnockedDown: sessionManager.currentRound?.kubbState(at: index) ?? false
                        )
                    }
                }
                
                // Second line: King kubb (only shown when all 5 are hit)
                if let currentRound = sessionManager.currentRound, currentRound.hits >= 5 {
                    KingKubbView(
                        isKnockedDown: currentRound.kingThrowsCount > 0 && currentRound.kingHits > 0
                    )
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)
            
            if let currentRound = sessionManager.currentRound {
                VStack(spacing: 4) {
                    Text("Round \(currentRound.roundNumber)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 16) {
                        VStack {
                            Text("\(currentRound.hits)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                            Text("Hits")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack {
                            Text("\(currentRound.misses)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                            Text("Misses")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack {
                            Text("\(currentRound.totalBatonThrows)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            Text("Throws")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if currentRound.hasBaselineClear {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow)
                            Text("Baseline Clear!")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.yellow)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.yellow.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    if currentRound.kingThrowsCount > 0 {
                        HStack {
                            Image(systemName: "crown")
                                .foregroundColor(.purple)
                            Text("King Throws: \(currentRound.kingThrowsCount)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.purple)
                        }
                    }
                }
            }
        }
    }
}

struct KubbView: View {
    let number: Int
    let isKnockedDown: Bool
    @State private var animationOffset: CGFloat = 0
    @State private var animationRotation: Double = 0
    
    var body: some View {
        ZStack {
            // Kubb base (rectangular box)
            RoundedRectangle(cornerRadius: 4)
                .fill(isKnockedDown ? Color.green : Color.blue)
                .frame(width: 20, height: 50)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.white, lineWidth: 1)
                )
                .rotationEffect(.degrees(isKnockedDown ? animationRotation : 0))
                .offset(y: isKnockedDown ? animationOffset : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isKnockedDown)
            
            // Kubb number
            Text("\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .rotationEffect(.degrees(isKnockedDown ? animationRotation : 0))
                .offset(y: isKnockedDown ? animationOffset : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isKnockedDown)
        }
        .frame(width: 60, height: 60)
        .onChange(of: isKnockedDown) { _, newValue in
            if newValue {
                // Trigger knock-over animation
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    animationOffset = 15
                    animationRotation = 90
                }
            } else {
                // Reset animation when kubb is reset
                animationOffset = 0
                animationRotation = 0
            }
        }
        .accessibilityLabel("Kubb \(number), \(isKnockedDown ? "knocked down" : "standing")")
        .accessibilityHint("Kubb number \(number) in the practice round")
    }
}

struct KingKubbView: View {
    let isKnockedDown: Bool
    @State private var animationOffset: CGFloat = 0
    @State private var animationRotation: Double = 0
    
    var body: some View {
        ZStack {
            // King kubb base (rectangular box - twice the size)
            RoundedRectangle(cornerRadius: 8)
                .fill(isKnockedDown ? Color.green : Color.purple)
                .frame(width: 40, height: 100)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white, lineWidth: 2)
                )
                .rotationEffect(.degrees(isKnockedDown ? animationRotation : 0))
                .offset(y: isKnockedDown ? animationOffset : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isKnockedDown)
            
            // King crown icon
            Image(systemName: "crown.fill")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .rotationEffect(.degrees(isKnockedDown ? animationRotation : 0))
                .offset(y: isKnockedDown ? animationOffset : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isKnockedDown)
        }
        .frame(width: 120, height: 120)
        .onChange(of: isKnockedDown) { _, newValue in
            if newValue {
                // Trigger knock-over animation
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    animationOffset = 20
                    animationRotation = 90
                }
            } else {
                // Reset animation when kubb is reset
                animationOffset = 0
                animationRotation = 0
            }
        }
        .accessibilityLabel("King kubb, \(isKnockedDown ? "knocked down" : "standing")")
        .accessibilityHint("King kubb - available for king throw")
    }
}

struct BatonControlsSection: View {
    @EnvironmentObject private var sessionManager: SessionManager
    
    private let hapticSuccess = UINotificationFeedbackGenerator()
    private let hapticError = UINotificationFeedbackGenerator()
    private let hapticImpact = UIImpactFeedbackGenerator(style: .heavy)
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Baton Result")
                .font(.headline)
            
            HStack(spacing: 30) {
                // MISS Button
                Button(action: { recordBatonResult(isHit: false) }) {
                    VStack(spacing: 8) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                        
                        Text("MISS")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .frame(width: 140, height: 140)
                    .background(Color.red)
                    .cornerRadius(20)
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(1.0)
                .animation(.easeInOut(duration: 0.1), value: UUID())
                .accessibilityLabel("Miss")
                .accessibilityHint("Record a missed baton throw")
                
                // HIT Button
                Button(action: { recordBatonResult(isHit: true) }) {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                        
                        Text("HIT")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .frame(width: 140, height: 140)
                    .background(Color.green)
                    .cornerRadius(20)
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(1.0)
                .animation(.easeInOut(duration: 0.1), value: UUID())
                .accessibilityLabel("Hit")
                .accessibilityHint("Record a successful baton throw")
            }
            
            Text("Tap the result of your baton throw")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func recordBatonResult(isHit: Bool) {
        hapticImpact.impactOccurred()
        
        if isHit {
            hapticSuccess.notificationOccurred(.success)
        } else {
            hapticError.notificationOccurred(.error)
        }
        
        Task {
            await sessionManager.addBatonResult(isHit: isHit)
        }
    }
}

struct SessionControlsSection: View {
    @EnvironmentObject private var sessionManager: SessionManager
    @State private var showingResetRoundAlert = false
    
    var body: some View {
        VStack(spacing: 12) {
            Button("Reset Current Round") {
                showingResetRoundAlert = true
            }
            .buttonStyle(SecondaryButtonStyle())
            
            Text("Tap to reset the current round if you need to start over")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .alert("Reset Round", isPresented: $showingResetRoundAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset Round", role: .destructive) {
                Task {
                    await sessionManager.resetCurrentRound()
                }
            }
        } message: {
            Text("Are you sure you want to reset the current round? This will clear all progress for this round.")
        }
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.orange)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    PracticeView()
        .environmentObject(SessionManager())
}
