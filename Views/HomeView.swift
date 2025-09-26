//
//  HomeView.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 9/23/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var sessionManager: SessionManager
    @Binding var selectedTab: Int
    @State private var showingTargetSetting = false
    @State private var cloudKitManager = CloudKitManager.shared
    @StateObject private var settingsManager = SettingsManager.shared
    @StateObject private var historyManager = HistoryManager()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Welcome Header
                WelcomeHeaderView()
                
                // Current Session Card
                if sessionManager.isSessionActive {
                    CurrentSessionCardView {
                        selectedTab = 1
                    }
                    .environmentObject(sessionManager)
                } else if sessionManager.hasIncompleteSession() {
                    IncompleteSessionCardView()
                        .environmentObject(sessionManager)
                } else {
                    StartSessionCardView(
                        onStartSession: {
                            showingTargetSetting = true
                        },
                        onShowTutorial: {
                            selectedTab = 3 // Tutorial tab
                        }
                    )
                }
                
                
                // Recent Activity
                RecentActivityView()
                
                // Debug Section (conditional)
                if settingsManager.showDebugTools {
                    DebugSectionView()
                        .environmentObject(cloudKitManager)
                }
            }
            .padding()
        }
        .sheet(isPresented: $showingTargetSetting) {
            TargetSettingView()
        }
    }
}

struct WelcomeHeaderView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image("kubb_crosshair")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
            
            Text("8 Meter Training Overview")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Track your progress, view stats, and manage your 8-meter practice sessions")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct CurrentSessionCardView: View {
    @EnvironmentObject private var sessionManager: SessionManager
    let onContinuePractice: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                
                Text("Practice in Progress")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            // Progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Progress")
                    Spacer()
                    Text("\(sessionManager.totalKubbs) / \(sessionManager.target)")
                        .fontWeight(.medium)
                }
                
                ProgressView(value: sessionManager.progressPercentage)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            }
            
            // Quick Stats
            HStack {
                VStack(alignment: .leading) {
                    Text("Accuracy")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f%%", sessionManager.accuracy * 100))
                        .font(.headline)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Batons")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(sessionManager.totalBatons)")
                        .font(.headline)
                        .fontWeight(.bold)
                }
            }
            
            Button("Continue Practice") {
                onContinuePractice()
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct StartSessionCardView: View {
    let onStartSession: () -> Void
    let onShowTutorial: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            Text("Ready to Practice?")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Set your target and start tracking your kubb practice session.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 12) {
                Button("Start New Session") {
                    onStartSession()
                }
                .buttonStyle(PrimaryButtonStyle())
                
                Button(action: onShowTutorial) {
                    Image(systemName: "questionmark.circle")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .buttonStyle(TutorialButtonStyle(isSecondary: true))
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct QuickStatsView: View {
    @EnvironmentObject private var sessionManager: SessionManager
    @StateObject private var historyManager = HistoryManager()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Stats")
                .font(.headline)
            
            HStack(spacing: 20) {
                QuickStatItem(
                    title: "Today's Target",
                    value: "\(sessionManager.target)",
                    icon: "kubb_crosshair",
                    color: .blue,
                    isCustomImage: true
                )
                
                QuickStatItem(
                    title: "Current Accuracy",
                    value: String(format: "%.1f%%", sessionManager.accuracy * 100),
                    icon: "scope",
                    color: .green
                )
                
                QuickStatItem(
                    title: "Sessions",
                    value: "\(historyManager.totalSessions)",
                    icon: "calendar",
                    color: .orange
                )
            }
        }
    }
}

struct QuickStatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let isCustomImage: Bool
    
    init(title: String, value: String, icon: String, color: Color, isCustomImage: Bool = false) {
        self.title = title
        self.value = value
        self.icon = icon
        self.color = color
        self.isCustomImage = isCustomImage
    }
    
    var body: some View {
        VStack(spacing: 8) {
            if isCustomImage {
                Image(icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
            } else {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
            }
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct RecentActivityView: View {
    @StateObject private var historyManager = HistoryManager()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.headline)
            
            if historyManager.sessions.isEmpty {
                Text("No recent sessions")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(historyManager.sessions.prefix(3)) { session in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(formatDate(session.date))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text("\(session.totalKubbs)/\(session.target) kubbs • \(String(format: "%.1f%%", session.accuracy * 100))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if session.isTargetReached {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct DebugSectionView: View {
    @EnvironmentObject private var cloudKitManager: CloudKitManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Debug Tools")
                .font(.headline)
            
            VStack(spacing: 12) {
                            Button("Test CloudKit Connection") {
                                Task {
                                    await cloudKitManager.testCloudKitConnection()
                                }
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            
                            Button("Test CloudKit Queries") {
                                Task {
                                    await cloudKitManager.testCloudKitQueries()
                                }
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            
                            Button("Remove Duplicates") {
                                Task {
                                    await cloudKitManager.removeDuplicateCloudKitRecords()
                                }
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            
                            Button("Clear CloudKit Data") {
                                Task {
                                    await cloudKitManager.clearAllCloudKitData()
                                }
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            
                            Button("Refresh iCloud Status") {
                                Task {
                                    await cloudKitManager.refreshAccountStatus()
                                }
                            }
                            .buttonStyle(SecondaryButtonStyle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("iCloud Status: \(cloudKitManager.isSignedIn ? "Signed In" : "Not Signed In")")
                        .font(.caption)
                        .foregroundColor(cloudKitManager.isSignedIn ? .green : .red)
                    
                    Text("Account Status: \(cloudKitManager.accountStatus.description)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if case .error(let message) = cloudKitManager.syncStatus {
                        Text("Error: \(message)")
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct IncompleteSessionCardView: View {
    @EnvironmentObject private var sessionManager: SessionManager
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Incomplete Session")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let session = sessionManager.currentSession {
                        Text("Started \(session.date.formatted(date: .abbreviated, time: .shortened))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            if let session = sessionManager.currentSession {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Progress")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(session.totalKubbs) / \(session.target) kubbs")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Accuracy")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(session.accuracy, specifier: "%.1f")%")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color(.systemGray5))
                .cornerRadius(8)
            }
            
            HStack(spacing: 12) {
                Button("Resume") {
                    sessionManager.resumeSession()
                }
                .buttonStyle(ResumeButtonStyle())
                
                Button("Delete") {
                    showingDeleteAlert = true
                }
                .buttonStyle(DeleteButtonStyle())
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
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

struct ResumeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct DeleteButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.red)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct IncompleteSessionPracticeView: View {
    @EnvironmentObject private var sessionManager: SessionManager
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                // Incomplete Session Icon
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.orange)
                
                VStack(spacing: 16) {
                    Text("Incomplete Session")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    if let session = sessionManager.currentSession {
                        Text("Started \(session.date.formatted(date: .abbreviated, time: .shortened))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        // Progress Info
                        VStack(spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Progress")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(session.totalKubbs) / \(session.target) kubbs")
                                        .font(.headline)
                                        .fontWeight(.medium)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Accuracy")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(session.accuracy, specifier: "%.1f")%")
                                        .font(.headline)
                                        .fontWeight(.medium)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button("Resume Session") {
                        sessionManager.resumeSession()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    
                    Button("Delete Session") {
                        showingDeleteAlert = true
                    }
                    .buttonStyle(DeleteButtonStyle())
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Practice")
            .navigationBarTitleDisplayMode(.inline)
        }
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


struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}


#Preview {
    HomeView(selectedTab: .constant(0))
        .environmentObject(SessionManager())
}
