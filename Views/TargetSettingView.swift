//
//  TargetSettingView.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 9/23/25.
//

import SwiftUI

struct TargetSettingView: View {
    @EnvironmentObject private var sessionManager: SessionManager
    @State private var target: Int = 100
    @State private var showingSession = false
    @State private var showingError = false
    
    private let hapticFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "target")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("Kubb Practice Tracker")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Set your daily target and start practicing!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Target Setting
                VStack(spacing: 20) {
                    Text("Daily Target")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 20) {
                        Button(action: decreaseTarget) {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.red)
                        }
                        .disabled(target <= 1)
                        .accessibilityLabel("Decrease target")
                        .accessibilityHint("Decrease the daily practice target by 1")
                        
                        Text("\(target)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .frame(minWidth: 100)
                            .accessibilityLabel("Daily target: \(target) kubbs")
                        
                        Button(action: increaseTarget) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.green)
                        }
                        .disabled(target >= 1000)
                        .accessibilityLabel("Increase target")
                        .accessibilityHint("Increase the daily practice target by 1")
                    }
                    
                    // Quick target buttons
                    HStack(spacing: 15) {
                        ForEach([50, 100, 150, 200], id: \.self) { quickTarget in
                            Button("\(quickTarget)") {
                                target = quickTarget
                                hapticFeedback.impactOccurred()
                            }
                            .buttonStyle(QuickTargetButtonStyle(isSelected: target == quickTarget))
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                
                // Start Session Button
                Button(action: startSession) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start Practice Session")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .disabled(sessionManager.isLoading)
                
                Spacer()
                
                // CloudKit Status
                CloudKitStatusView()
            }
            .padding()
            .navigationTitle("Practice Setup")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingSession) {
            if sessionManager.isSessionActive {
                PracticeView()
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(sessionManager.errorMessage ?? "An unknown error occurred")
        }
        .onChange(of: sessionManager.errorMessage) { _, errorMessage in
            showingError = errorMessage != nil
        }
    }
    
    private func decreaseTarget() {
        guard target > 1 else { return }
        target -= 1
        hapticFeedback.impactOccurred()
    }
    
    private func increaseTarget() {
        guard target < 1000 else { return }
        target += 1
        hapticFeedback.impactOccurred()
    }
    
    private func startSession() {
        hapticFeedback.impactOccurred()
        
        Task {
            await sessionManager.startNewSession(target: target)
            
            if sessionManager.isSessionActive {
                showingSession = true
            }
        }
    }
}

struct QuickTargetButtonStyle: ButtonStyle {
    let isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(.systemGray5))
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct CloudKitStatusView: View {
    @StateObject private var cloudKitManager = CloudKitManager.shared
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
                .font(.caption)
            
            Text(statusText)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var statusIcon: String {
        switch cloudKitManager.syncStatus {
        case .idle:
            return cloudKitManager.isSignedIn ? "icloud" : "icloud.slash"
        case .syncing:
            return "icloud.and.arrow.up"
        case .success:
            return "checkmark.icloud"
        case .error:
            return "exclamationmark.icloud"
        }
    }
    
    private var statusColor: Color {
        switch cloudKitManager.syncStatus {
        case .idle:
            return cloudKitManager.isSignedIn ? .blue : .orange
        case .syncing:
            return .blue
        case .success:
            return .green
        case .error:
            return .red
        }
    }
    
    private var statusText: String {
        switch cloudKitManager.syncStatus {
        case .idle:
            return cloudKitManager.isSignedIn ? "iCloud Ready" : "iCloud Unavailable"
        case .syncing:
            return "Syncing..."
        case .success:
            return "Synced"
        case .error:
            return "Sync Error"
        }
    }
}

#Preview {
    TargetSettingView()
}
