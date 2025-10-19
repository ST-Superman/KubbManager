//
//  ContentView.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 9/23/25.
//

import SwiftUI

// MARK: - Content View
// This is the root view that manages the app's main navigation flow
// It switches between the landing page and the main tabbed interface

struct ContentView: View {
    // MARK: - State Management
    @State private var showingMainApp = false  // Controls whether to show main app or landing page
    @State private var selectedTab = 0         // Tracks which tab is currently selected
    
    var body: some View {
        // Conditional view rendering based on app state
        if showingMainApp {
            // Show the main tabbed interface when user has navigated past landing page
            MainTabView(selectedTab: $selectedTab)
        } else {
            // Show the landing page with app introduction and navigation options
            LandingPageView(showingMainApp: $showingMainApp, selectedTab: $selectedTab)
        }
    }
}

// MARK: - Landing Page View
// The initial screen users see when opening the app
// Provides navigation to different sections and app information
struct LandingPageView: View {
    @Binding var showingMainApp: Bool  // Controls navigation to main app
    @Binding var selectedTab: Int      // Controls which tab to show in main app
    @State private var showingOptions = false  // Controls options sheet presentation
    @StateObject private var settingsManager = SettingsManager.shared  // Manages app settings
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 40) {
                    // App Header - Logo and description
                    LandingAppHeaderView()
                    
                    // Main Action Buttons - Primary navigation options
                    VStack(spacing: 24) {
                        // Training Button - Navigate to training modes
                        MainActionButton(
                            title: "Training",
                            description: "Practice your kubb skills with various training modes",
                            icon: "figure.strengthtraining.traditional.circle.fill",
                            color: .blue
                        ) {
                            selectedTab = 1  // Training tab
                            showingMainApp = true
                        }
                        
                        // Game Logs Button - Navigate to game tracking
                        MainActionButton(
                            title: "Game Logs",
                            description: "Track your game sessions and match results",
                            icon: "play.circle.fill",
                            color: .green
                        ) {
                            selectedTab = 2  // Game Logs tab
                            showingMainApp = true
                        }
                        
                        // Stats Button - Navigate to statistics
                        MainActionButton(
                            title: "Statistics",
                            description: "View your progress and performance analytics",
                            icon: "chart.line.text.clipboard",
                            color: .orange
                        ) {
                            selectedTab = 3  // Stats tab
                            showingMainApp = true
                        }
                    }
                    
                    // Coming Soon Notice
                    ComingSoonNoticeView()
                    
                    // Debug Section (conditional)
                    if settingsManager.showDebugTools {
                        DebugSectionView()
                            .environmentObject(CloudKitManager.shared)
                    } else {
                        // Debug info to help troubleshoot
                        VStack {
                            Text("Debug Tools Status: OFF")
                                .font(.caption)
                                .foregroundColor(.red)
                            Text("Go to Options → Debug Options → Enable 'Include Debug Tools'")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                }
                .padding()
            }
            .navigationTitle("Kubb Manager")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Options") {
                        showingOptions = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingOptions) {
            OptionsView()
                .environmentObject(settingsManager)
        }
    }
}

// MARK: - Landing App Header View
// Displays the app logo and description on the landing page
struct LandingAppHeaderView: View {
    var body: some View {
        VStack(spacing: 20) {
            // App logo image
            Image("kubb1024")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
            
            // App description text
            Text("Improve your kubb skills with training, track your games, and analyze your progress")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top, 20)
    }
}

// MARK: - Main Action Button
// A reusable button component for the main navigation actions on the landing page
struct MainActionButton: View {
    let title: String        // Button title text
    let description: String  // Descriptive text below the title
    let icon: String         // SF Symbol name for the icon
    let color: Color         // Theme color for the button
    let action: () -> Void   // Action to perform when button is tapped
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                // Icon section
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundColor(color)
                    .frame(width: 60, height: 60)
                
                // Content section - title and description
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Navigation arrow
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(color)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(color.opacity(0.3), lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Main Tab View
// The main tabbed interface that contains all the app's primary sections
struct MainTabView: View {
    @StateObject private var sessionManager = SessionManager()  // Manages practice sessions
    @Binding var selectedTab: Int                               // Controls which tab is selected
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Main Menu Tab - Landing page content within the tabbed interface
            MainMenuTabView(selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: "filemenu.and.selection")
                    Text("Main Menu")
                }
                .tag(0)
            
            // Training Tab - Practice modes and training options
            TrainingTabView()
                .tabItem {
                    Image(systemName: "figure.strengthtraining.traditional.circle.fill")
                    Text("Training")
                }
                .tag(1)
            
            // Game Logs Tab - Game tracking and match recording
            GameLogsTabView()
                .tabItem {
                    Image(systemName: "play.circle.fill")
                    Text("Game Logs")
                }
                .tag(2)
            
            // Stats Tab - Statistics and performance analytics
            StatsTabView()
                .tabItem {
                    Image(systemName: "chart.line.text.clipboard")
                    Text("Stats")
                }
                .tag(3)
        }
        .environmentObject(sessionManager)
        // Handle app lifecycle events for session management
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            sessionManager.handleAppWillResignActive()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            sessionManager.handleAppDidEnterBackground()
        }
    }
}

// MARK: - Main Menu Tab
struct MainMenuTabView: View {
    @Binding var selectedTab: Int
    @State private var showingOptions = false
    @StateObject private var settingsManager = SettingsManager.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 40) {
                    // App Header
                    LandingAppHeaderView()
                    
                    // Main Action Buttons
                    VStack(spacing: 24) {
                        // Training Button
                        MainActionButton(
                            title: "Training",
                            description: "Practice your kubb skills with various training modes",
                            icon: "figure.strengthtraining.traditional.circle.fill",
                            color: .blue
                        ) {
                            selectedTab = 1
                        }
                        
                        // Game Logs Button
                        MainActionButton(
                            title: "Game Logs",
                            description: "Track your game sessions and match results",
                            icon: "play.circle.fill",
                            color: .green
                        ) {
                            selectedTab = 2
                        }
                        
                        // Stats Button
                        MainActionButton(
                            title: "Statistics",
                            description: "View your progress and performance analytics",
                            icon: "chart.line.text.clipboard",
                            color: .orange
                        ) {
                            selectedTab = 3
                        }
                    }
                    
                    // Coming Soon Notice
                    ComingSoonNoticeView()
                    
                    // Debug Section (conditional)
                    if settingsManager.showDebugTools {
                        DebugSectionView()
                            .environmentObject(CloudKitManager.shared)
                    } else {
                        // Debug info to help troubleshoot
                        VStack {
                            Text("Debug Tools Status: OFF")
                                .font(.caption)
                                .foregroundColor(.red)
                            Text("Go to Options → Debug Options → Enable 'Include Debug Tools'")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                }
                .padding()
            }
            .navigationTitle("Kubb Manager")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Options") {
                        showingOptions = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingOptions) {
            OptionsView()
                .environmentObject(settingsManager)
        }
    }
}

// MARK: - Training Tab
struct TrainingTabView: View {
    @State private var selectedMode: TrainingMode?
    @State private var showingEightMeterTraining = false
    @State private var showingInkastBlast = false
    @State private var showingFullGameSim = false
    @StateObject private var settingsManager = SettingsManager.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                TrainingHeaderView()
                ScrollView {
                    // Training Mode Buttons
                    VStack(spacing: 20) {
                        ForEach(TrainingMode.allCases, id: \.self) { mode in
                            TrainingModeButton(
                                mode: mode,
                                isSelected: selectedMode == mode
                            ) {
                                if mode.isAvailable {
                                    selectedMode = mode
                                    if mode == .eightMeter {
                                        showingEightMeterTraining = true
                                    } else if mode == .inkastBlast {
                                        showingInkastBlast = true
                                    } else if mode == .fullGameSim {
                                        showingFullGameSim = true
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            
            
        }
        .fullScreenCover(isPresented: $showingEightMeterTraining) {
            EightMeterTrainingViewRedesigned()
                .environmentObject(SessionManager())
        }
        .fullScreenCover(isPresented: $showingInkastBlast) {
            InkastBlastView(
                persistenceController: PersistenceController.shared,
                cloudKitManager: CloudKitManager.shared
            )
        }
        .fullScreenCover(isPresented: $showingFullGameSim) {
            FullGameSimView(
                persistenceController: PersistenceController.shared,
                cloudKitManager: CloudKitManager.shared
            )
        }
    }
}

struct TrainingHeaderView: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "figure.strengthtraining.traditional.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Choose your training mode to improve your kubb skills")
                .font(.title3)
                .foregroundColor(.blue)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 6)
    }
}

// MARK: - Game Logs Tab
struct GameLogsTabView: View {
    @State private var showingBaseballKubb = false
    @State private var showingTraditionalKubb = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Game Logs Header
                GameLogsHeaderView()
                    
                ScrollView {
                    VStack(spacing: 16) {
                    // Game Mode Buttons
                    VStack(spacing: 20) {
                        // Baseball Kubb
                        GameModeButton(
                            title: "Baseball Kubb",
                            description: "Baseball-style Kubb game with innings and scoring",
                            icon: "baseball_kubb",
                            isAvailable: true
                        ) {
                            showingBaseballKubb = true
                        }
                        
                        // Traditional Kubb (Coming Soon)
                        GameModeButton(
                            title: "Traditional Kubb",
                            description: "Classic Kubb game with traditional rules",
                            icon: "king",
                            isAvailable: false
                        ) {
                            showingTraditionalKubb = true
                        }
                    }
                }
                .padding()
            }
            }   
        }
        .fullScreenCover(isPresented: $showingBaseballKubb) {
            BaseballKubbView()
        }
        .fullScreenCover(isPresented: $showingTraditionalKubb) {
            TraditionalKubbComingSoonView()
        }
    }
}

struct GameLogsHeaderView: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "play.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.green)
            
            Text("Track your game sessions and match results")
                .font(.title3)
                .foregroundColor(.blue)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 6)
    }
}

// MARK: - Stats Tab
struct StatsTabView: View {
    @State private var selectedStatsTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Stats Header
                StatsHeaderView()
                
                // Stats Sub-tabs
                Picker("Stats View", selection: $selectedStatsTab) {
                    Text("Statistics").tag(0)
                    Text("Session Logs").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Stats Content
                if selectedStatsTab == 0 {
                    StatsView()
                } else {
                    HistoryView()
                }
            }
            
        }
    }
}

struct StatsHeaderView: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "chart.line.text.clipboard")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            
            Text("Track your progress and analyze your performance")
                .font(.title3)
                .foregroundColor(.blue)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 6)
        .padding(.horizontal)
    }
}

// MARK: - Game Mode Button
struct GameModeButton: View {
    let title: String
    let description: String
    let icon: String
    let isAvailable: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                Image(icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60)
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(isAvailable ? .primary : .secondary)
                        
                        if !isAvailable {
                            Text("Coming Soon")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .cornerRadius(8)
                        }
                        
                        Spacer()
                    }
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                // Arrow
                if isAvailable {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
            )
        }
        .disabled(!isAvailable)
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Coming Soon Views
struct FullGameSimComingSoonView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: "clock.badge.exclamationmark")
                    .font(.system(size: 80))
                    .foregroundColor(.orange)
                
                VStack(spacing: 16) {
                    Text("Full Game Simulation")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Coming Soon!")
                        .font(.title2)
                        .foregroundColor(.orange)
                        .fontWeight(.semibold)
                    
                    Text("We're working on a full game simulation mode that will let you practice complete Kubb games with AI opponents and various difficulty levels.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Full Game Sim")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TraditionalKubbComingSoonView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                Image("king")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                
                VStack(spacing: 16) {
                    Text("Traditional Kubb")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Coming Soon!")
                        .font(.title2)
                        .foregroundColor(.orange)
                        .fontWeight(.semibold)
                    
                    Text("We're developing a traditional Kubb game mode that will track your matches, record scores, and help you improve your strategic gameplay.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Traditional Kubb")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}



#Preview {
    ContentView()
}
