//
//  PracticeView.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 9/23/25.
//

import SwiftUI

// MARK: - Practice View
// This is the main practice interface where users record their baton throws
// It displays the kubb grid, progress tracking, and provides controls for recording hits/misses

struct PracticeView: View {
    // MARK: - Environment Objects
    @EnvironmentObject private var sessionManager: SessionManager  // Manages the current practice session
    @Environment(\.dismiss) private var dismiss                   // Allows dismissing this view
    
    // MARK: - Modal and Alert State
    @State private var showingEndSessionAlert = false            // Controls end session confirmation alert
    @State private var showingPauseSessionAlert = false          // Controls pause session confirmation alert
    @State private var showingResetRoundAlert = false            // Controls reset round confirmation alert
    @State private var showingTargetReachedModal = false         // Controls target reached celebration modal
    @State private var showingRoundCompleteModal = false         // Controls round completion modal
    
    // MARK: - Session State Tracking
    @State private var hasShownTargetReachedAlert = false        // Prevents duplicate target reached alerts
    @State private var lastTargetReachedBatons = 0               // Tracks when target was last reached
    @State private var lastCompletedRound: Round?                // Tracks the last completed round for display
    
    // MARK: - Haptic Feedback
    private let hapticSuccess = UINotificationFeedbackGenerator()  // Success haptic feedback
    private let hapticError = UINotificationFeedbackGenerator()    // Error haptic feedback
    private let hapticImpact = UIImpactFeedbackGenerator(style: .medium)  // Impact haptic feedback
    
    // MARK: - Main View Body
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 24) {
                        // Progress Section - Shows current progress toward target
                        ProgressSection()
                            .environmentObject(sessionManager)
                        
                        // Kubb Grid Section - Visual representation of kubb pieces and hits
                        KubbGridSection(lastCompletedRound: lastCompletedRound)
                            .environmentObject(sessionManager)
                        
                        // Baton Controls Section - Hit/Miss buttons and throw recording
                        BatonControlsSection()
                            .environmentObject(sessionManager)
                        
                        // Session Controls Section - Round management and session controls
                        SessionControlsSection()
                            .environmentObject(sessionManager)
                        
                        // Watch Control Panel
                        WatchSessionControlPanel(
                            sessionType: "8M Training",
                            onStartWatchInput: {
                                sessionManager.requestWatchBatonInput()
                            },
                            onSendSessionState: {
                                sessionManager.sendSessionStateToWatch()
                            }
                        )
                    }
                    .padding()
                }
            }
            // Set navigation title for the practice session
            .navigationTitle("Practice Session")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Ensure watch connectivity is set up when practice view appears
                if sessionManager.isSessionActive {
                    sessionManager.setupWatchConnectivity()
                    sessionManager.sendSessionStateToWatch()
                }
            }
            .toolbar {
                // Left toolbar item - Pause session button
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Pause") {
                        showingPauseSessionAlert = true
                    }
                    .foregroundColor(.orange)
                }
                // Right toolbar item - End session button
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("End Session") {
                        showingEndSessionAlert = true
                    }
                    .foregroundColor(.red)
                }
            }
        }
        // Pause session confirmation alert
        .alert("Pause Session", isPresented: $showingPauseSessionAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Pause") {
                Task {
                    await sessionManager.pauseSession()
                    dismiss()
                }
            }
        } message: {
            Text("Pause this practice session? You can resume it later from the main menu.")
        }
        // End session confirmation alert
        .alert("End Session", isPresented: $showingEndSessionAlert) {
            Button("Cancel", role: .cancel) { }
            Button("End Session", role: .destructive) {
                Task {
                    await sessionManager.completeSession()
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to end this practice session? Your progress will be saved and it will appear in your history.")
        }
        // Reset round confirmation alert
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
        // Monitor target reached status and show celebration modal
        .onChange(of: sessionManager.isTargetReached) { _, isReached in
            if isReached && !hasShownTargetReachedAlert && sessionManager.totalBatons > lastTargetReachedBatons {
                hapticSuccess.notificationOccurred(.success)
                showingTargetReachedModal = true
                lastTargetReachedBatons = sessionManager.totalBatons
            }
        }
        // Monitor current round changes to detect round completion
        .onChange(of: sessionManager.currentRound) { _, newCurrentRound in
            // Check if currentRound became nil (indicating a round just completed)
            if newCurrentRound == nil,
               let session = sessionManager.currentSession,
               !session.rounds.isEmpty,
               let lastRound = session.rounds.last,
               lastRound.isComplete && lastRound != lastCompletedRound {
                lastCompletedRound = lastRound
                showingRoundCompleteModal = true
            }
        }
        // Overlay for round completion modal
        .overlay(
            Group {
                if showingRoundCompleteModal {
                    RoundCompleteModalView(
                        isPresented: $showingRoundCompleteModal,
                        onStartNextRound: {
                            Task {
                                await sessionManager.startNextRound()
                                showingRoundCompleteModal = false
                            }
                        }
                    )
                }
            }
        )
        // Overlay for target reached celebration modal
        .overlay(
            Group {
                if showingTargetReachedModal {
                    TargetReachedModalView(
                        isPresented: $showingTargetReachedModal,
                        target: sessionManager.target,
                        onContinuePractice: {
                            showingTargetReachedModal = false
                            hasShownTargetReachedAlert = true
                        },
                        onEndSession: {
                            Task {
                                await sessionManager.completeSession()
                                dismiss()
                            }
                        }
                    )
                }
            }
        )
    }
}

// MARK: - Progress Section View
// Displays the current progress toward the session target and key statistics
struct ProgressSection: View {
    @EnvironmentObject private var sessionManager: SessionManager
    
    var body: some View {
        VStack(spacing: 16) {
            // Progress Bar Section - Shows visual progress toward target
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Progress")
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("\(sessionManager.totalBatons) / \(sessionManager.target)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                
                // Linear progress bar showing current vs target batons
                ProgressView(value: sessionManager.progressPercentage)
                    .progressViewStyle(LinearProgressViewStyle(tint: progressColor))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
            }
            
            // Statistics Row - Shows key performance metrics
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
    
    // MARK: - Computed Properties
    
    /// Progress bar color based on completion percentage
    /// Green: 100%+ complete, Blue: 70%+, Orange: 40%+, Red: <40%
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
    
    /// Accuracy text color based on performance level
    /// Green: 70%+, Yellow: 50-69%, Red: <50%
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

// MARK: - Statistic Item View
// A reusable component for displaying individual statistics with icon, value, and title
struct StatisticItem: View {
    let title: String    // The label for the statistic (e.g., "Accuracy")
    let value: String    // The numeric value to display (e.g., "85.2%")
    let icon: String     // SF Symbol name for the icon
    let color: Color     // Color theme for the icon and value
    
    var body: some View {
        VStack(spacing: 4) {
            // Icon at the top
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            // Main value in bold
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            // Title label below
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)  // Equal width distribution
    }
}

// MARK: - Kubb Grid Section View
// Displays the visual representation of kubb pieces and tracks which ones have been hit
struct KubbGridSection: View {
    @EnvironmentObject private var sessionManager: SessionManager  // Manages current session state
    @StateObject private var skinManager = SkinManager.shared     // Manages skin customization
    let lastCompletedRound: Round?                                // Reference to last completed round for animations
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Current Round")
                .font(.headline)
            
            VStack(spacing: 12) {
                // First line: 5 regular kubbs (baseline kubbs)
                HStack(spacing: 12) {
                    ForEach(0..<5, id: \.self) { index in
                        KubbView(
                            number: index + 1,
                            isKnockedDown: getKubbState(at: index),
                            skin: skinManager.selectedKubbSkin
                        )
                    }
                }
                
                // Second line: King kubb (only shown when all 5 baseline kubbs are hit)
                if let displayRound = getDisplayRound(), displayRound.hits >= 5 {
                    KingKubbView(
                        isKnockedDown: displayRound.kingThrowsCount > 0 && displayRound.kingHits > 0,
                        skin: skinManager.selectedKingSkin
                    )
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)
            
            // Round statistics display
            if let displayRound = getDisplayRound() {
                VStack(spacing: 4) {
                    Text("Round \(displayRound.roundNumber)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 16) {
                        VStack {
                            Text("\(displayRound.hits)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                            Text("Hits")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack {
                            Text("\(displayRound.misses)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                            Text("Misses")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack {
                            Text("\(displayRound.totalBatonThrows)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            Text("Throws")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Baseline clear achievement indicator
                    if displayRound.hasBaselineClear {
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
                    
                    // King throw attempts indicator
                    if displayRound.kingThrowsCount > 0 {
                        HStack {
                            Image(systemName: "crown")
                                .foregroundColor(.purple)
                            Text("King Throws: \(displayRound.kingThrowsCount)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.purple)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    /// Determines which round to display (current active round or last completed round)
    private func getDisplayRound() -> Round? {
        // Show current round if available, otherwise show the last completed round
        return sessionManager.currentRound ?? lastCompletedRound
    }
    
    /// Gets the hit/miss state for a specific kubb piece at the given index
    private func getKubbState(at index: Int) -> Bool {
        // Get kubb state from the display round
        return getDisplayRound()?.kubbState(at: index) ?? false
    }
}

// MARK: - Kubb View
// Individual kubb piece display with animation and skin support
struct KubbView: View {
    let number: Int                    // Kubb piece number (1-5)
    let isKnockedDown: Bool           // Whether this kubb has been hit
    let skin: KubbSkin?               // Optional skin for customization
    
    @StateObject private var skinManager = SkinManager.shared  // Skin management
    @State private var animationOffset: CGFloat = 0           // Vertical offset for knockdown animation
    @State private var animationRotation: Double = 0          // Rotation for knockdown animation
    @State private var selectedImageName: String?             // Selected image for upright state
    @State private var selectedDownImageName: String?         // Selected image for knocked down state
    
    init(number: Int, isKnockedDown: Bool, skin: KubbSkin? = nil) {
        self.number = number
        self.isKnockedDown = isKnockedDown
        self.skin = skin
        
        // Initialize images immediately for better performance
        let skinManager = SkinManager.shared
        self._selectedImageName = State(initialValue: skinManager.getRandomKubbImageName(for: number - 1))
        self._selectedDownImageName = State(initialValue: skinManager.getRandomKubbDownImageName(for: number - 1))
    }
    
    var body: some View {
        ZStack {
            // Image-based kubb rendering (if skin has images)
            if let imageName = getCurrentImageName() {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 50)
                    .scaleEffect(skin?.kubbImageScale ?? 1.0)
                    .rotationEffect(.degrees(isKnockedDown ? animationRotation : 0))
                    .offset(y: isKnockedDown ? animationOffset : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isKnockedDown)
                    .onAppear {
                        selectImages()
                    }
            } else {
                // Color-based kubb rendering (fallback/default)
                RoundedRectangle(cornerRadius: 4)
                    .fill(kubbColor)
                    .frame(width: 20, height: 50)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(accentColor, lineWidth: 1)
                    )
                    .rotationEffect(.degrees(isKnockedDown ? animationRotation : 0))
                    .offset(y: isKnockedDown ? animationOffset : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isKnockedDown)
                    .onAppear {
                        selectImages()
                    }
            }
            
            // Kubb number display (only for color-based kubbs)
            if skin?.kubbImageName == nil {
                Text("\(number)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(isKnockedDown ? animationRotation : 0))
                    .offset(y: isKnockedDown ? animationOffset : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isKnockedDown)
            }
        }
        .frame(width: 60, height: 60)
        // Monitor knockdown state changes to trigger animations
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
    
    private var kubbColor: Color {
        if isKnockedDown {
            return Color.green
        } else {
            return skin?.kubbColor.color ?? Color.blue
        }
    }
    
    private var accentColor: Color {
        return skin?.kubbAccentColor?.color ?? Color.white
    }
    
    // MARK: - Multi-Image Helper Methods
    
    private func selectImages() {
        // Always use SkinManager for random selection to ensure multi-skin packages work correctly
        selectedImageName = skinManager.getRandomKubbImageName(for: number - 1)
        selectedDownImageName = skinManager.getRandomKubbDownImageName(for: number - 1)
    }
    
    private func getCurrentImageName() -> String? {
        // If we have custom down images and kubb is knocked down, use down image
        if isKnockedDown, let downImageName = selectedDownImageName {
            return downImageName
        }
        
        // Otherwise use standing image
        return selectedImageName
    }
}

// MARK: - King Kubb View
// King kubb piece display with animation and skin support (larger than regular kubbs)
struct KingKubbView: View {
    let isKnockedDown: Bool           // Whether the king has been hit
    let skin: KubbSkin?               // Optional skin for customization
    
    @StateObject private var skinManager = SkinManager.shared  // Skin management
    @State private var animationOffset: CGFloat = 0           // Vertical offset for knockdown animation
    @State private var animationRotation: Double = 0          // Rotation for knockdown animation
    @State private var selectedImageName: String?             // Selected image for upright state
    @State private var selectedDownImageName: String?         // Selected image for knocked down state
    
    init(isKnockedDown: Bool, skin: KubbSkin? = nil) {
        self.isKnockedDown = isKnockedDown
        self.skin = skin
        
        // Initialize images immediately for better performance
        let skinManager = SkinManager.shared
        self._selectedImageName = State(initialValue: skinManager.getRandomKingImageName())
        self._selectedDownImageName = State(initialValue: skinManager.getRandomKingDownImageName())
    }
    
    var body: some View {
        ZStack {
            // Image-based king rendering (if skin has images)
            if let imageName = getCurrentImageName() {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 100)
                    .scaleEffect(skin?.kingImageScale ?? 1.0)
                    .rotationEffect(.degrees(isKnockedDown ? animationRotation : 0))
                    .offset(y: isKnockedDown ? animationOffset : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isKnockedDown)
                    .onAppear {
                        selectImages()
                    }
            } else {
                // Color-based king rendering (fallback/default)
                RoundedRectangle(cornerRadius: 8)
                    .fill(kingColor)
                    .frame(width: 40, height: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(accentColor, lineWidth: 2)
                    )
                    .rotationEffect(.degrees(isKnockedDown ? animationRotation : 0))
                    .offset(y: isKnockedDown ? animationOffset : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isKnockedDown)
                
                // King crown icon (only for color-based kings)
                Image(systemName: "crown.fill")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(isKnockedDown ? animationRotation : 0))
                    .offset(y: isKnockedDown ? animationOffset : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isKnockedDown)
            }
        }
        .frame(width: 120, height: 120)
        // Monitor knockdown state changes to trigger animations
        .onChange(of: isKnockedDown) { _, newValue in
            if newValue {
                // Trigger knock-over animation with larger movement for king
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
    
    private var kingColor: Color {
        if isKnockedDown {
            return Color.green
        } else {
            return skin?.kingColor.color ?? Color.purple
        }
    }
    
    private var accentColor: Color {
        return skin?.kingAccentColor?.color ?? Color.white
    }
    
    // MARK: - Multi-Image Helper Methods
    
    private func selectImages() {
        // Always use SkinManager for random selection to ensure multi-skin packages work correctly
        selectedImageName = skinManager.getRandomKingImageName()
        selectedDownImageName = skinManager.getRandomKingDownImageName()
    }
    
    private func getCurrentImageName() -> String? {
        // If we have custom down images and king is knocked down, use down image
        if isKnockedDown, let downImageName = selectedDownImageName {
            return downImageName
        }
        
        // Otherwise use standing image
        return selectedImageName
    }
}

// MARK: - Baton Controls Section View
// Provides the main interface for recording baton throws (hit/miss)
struct BatonControlsSection: View {
    @EnvironmentObject private var sessionManager: SessionManager
    
    // MARK: - Haptic Feedback
    private let hapticSuccess = UINotificationFeedbackGenerator()  // Success feedback
    private let hapticError = UINotificationFeedbackGenerator()    // Error feedback
    private let hapticImpact = UIImpactFeedbackGenerator(style: .heavy)  // Heavy impact feedback
    
    // MARK: - Computed Properties
    
    /// Determines if the current round is complete (controls button states)
    private var isRoundComplete: Bool {
        // Round is complete if current round is complete OR if there's no current round (modal should show)
        return sessionManager.currentRound?.isRoundComplete ?? true
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Baton Result")
                .font(.headline)
            
            HStack(spacing: 30) {
                // MISS Button - Records a missed baton throw
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
                    .background(isRoundComplete ? Color.gray : Color.red)
                    .cornerRadius(20)
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(1.0)
                .animation(.easeInOut(duration: 0.1), value: UUID())
                .disabled(isRoundComplete)
                .accessibilityLabel("Miss")
                .accessibilityHint(isRoundComplete ? "Round complete - wait for next round" : "Record a missed baton throw")
                
                // HIT Button - Records a successful baton throw
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
                    .background(isRoundComplete ? Color.gray : Color.green)
                    .cornerRadius(20)
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(1.0)
                .animation(.easeInOut(duration: 0.1), value: UUID())
                .disabled(isRoundComplete)
                .accessibilityLabel("Hit")
                .accessibilityHint(isRoundComplete ? "Round complete - wait for next round" : "Record a successful baton throw")
            }
            
            // Instructional text that changes based on round state
            Text(isRoundComplete ? "Round complete - tap 'Start Next Round' to continue" : "Tap the result of your baton throw")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Helper Functions
    
    /// Records a baton throw result (hit or miss) with haptic feedback
    private func recordBatonResult(isHit: Bool) {
        // Provide immediate haptic feedback for button press
        hapticImpact.impactOccurred()
        
        // Provide success/error haptic feedback based on result
        if isHit {
            hapticSuccess.notificationOccurred(.success)
        } else {
            hapticError.notificationOccurred(.error)
        }
        
        // Record the result in the session manager asynchronously
        Task {
            await sessionManager.addBatonResult(isHit: isHit)
        }
    }
}

// MARK: - Session Controls Section View
// Provides controls for managing the current session (reset round, etc.)
struct SessionControlsSection: View {
    @EnvironmentObject private var sessionManager: SessionManager  // Manages current session state
    @State private var showingResetRoundAlert = false             // Controls reset confirmation alert
    
    var body: some View {
        VStack(spacing: 12) {
            // Reset round button with confirmation
            Button("Reset Current Round") {
                showingResetRoundAlert = true
            }
            .buttonStyle(SecondaryButtonStyle())
            
            // Help text for the reset button
            Text("Tap to reset the current round if you need to start over")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        // Reset round confirmation alert
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

// MARK: - Secondary Button Style
// Custom button style for secondary actions (reset, etc.)
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

// MARK: - Custom Modal Views

// MARK: - Round Complete Modal View
// Modal shown when a round is completed, prompting user to start next round
struct RoundCompleteModalView: View {
    @Binding var isPresented: Bool    // Controls modal visibility
    let onStartNextRound: () -> Void  // Callback when user starts next round
    
    var body: some View {
        ZStack {
            // Background overlay - dims the background content
            Color.black.opacity(0.6)
                .ignoresSafeArea(.container, edges: .bottom)
                .onTapGesture {
                    // Prevent dismissing by tapping background
                }
            
            // Modal content container
            VStack(spacing: 24) {
                // Success icon
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                // Modal title
                Text("Round Complete!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                // Instructional message
                Text("Please stand any knocked down kubbs back up and retrieve your batons before starting the next round.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Primary action button
                Button("Start Next Round") {
                    onStartNextRound()
                }
                .buttonStyle(PrimaryButtonStyle())
                .controlSize(.large)
            }
            .padding(32)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 20)
            .padding(.horizontal, 40)
        }
    }
}

// MARK: - Target Reached Modal View
// Modal shown when user reaches their practice target, offering options to continue or end
struct TargetReachedModalView: View {
    @Binding var isPresented: Bool      // Controls modal visibility
    let target: Int                     // The target number of batons that was reached
    let onContinuePractice: () -> Void  // Callback when user chooses to continue practicing
    let onEndSession: () -> Void        // Callback when user chooses to end the session
    
    var body: some View {
        ZStack {
            // Background overlay - dims the background content
            Color.black.opacity(0.6)
                .ignoresSafeArea(.container, edges: .bottom)
                .onTapGesture {
                    // Prevent dismissing by tapping background
                }
            
            // Modal content container
            VStack(spacing: 24) {
                // Celebration icon
                Image(systemName: "trophy.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.yellow)
                
                // Modal title
                Text("Target Reached!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                // Congratulatory message with target info
                Text("Congratulations! You've reached your target of \(target) batons! 🎉\n\nWould you like to continue practicing or end your session?")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Action buttons - two options for the user
                VStack(spacing: 12) {
                    Button("Continue Practice") {
                        onContinuePractice()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .controlSize(.large)
                    
                    Button("End Session") {
                        onEndSession()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .controlSize(.large)
                }
            }
            .padding(32)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 20)
            .padding(.horizontal, 40)
        }
    }
}


#Preview {
    PracticeView()
        .environmentObject(SessionManager())
}
