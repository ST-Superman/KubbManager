//
//  ContentView.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 9/23/25.
//

import SwiftUI

struct ContentView: View {
    @State private var showingMainApp = false
    @State private var selectedTab = 0
    
    var body: some View {
        if showingMainApp {
            MainTabView(selectedTab: $selectedTab)
        } else {
            LandingPageView(showingMainApp: $showingMainApp, selectedTab: $selectedTab)
        }
    }
}

// MARK: - Landing Page
struct LandingPageView: View {
    @Binding var showingMainApp: Bool
    @Binding var selectedTab: Int
    
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
                            selectedTab = 0
                            showingMainApp = true
                        }
                        
                        // Game Logs Button
                        MainActionButton(
                            title: "Game Logs",
                            description: "Track your game sessions and match results",
                            icon: "play.circle.fill",
                            color: .green
                        ) {
                            selectedTab = 1
                            showingMainApp = true
                        }
                        
                        // Stats Button
                        MainActionButton(
                            title: "Statistics",
                            description: "View your progress and performance analytics",
                            icon: "chart.line.text.clipboard",
                            color: .orange
                        ) {
                            selectedTab = 2
                            showingMainApp = true
                        }
                    }
                    
                    // Quick Access Note
                    VStack(spacing: 12) {
                        Image(systemName: "info.circle")
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        Text("Quick Access")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("You can also use the tabs at the bottom to quickly switch between sections")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.blue.opacity(0.1))
                    )
                }
                .padding()
            }
            .navigationTitle("Kubb Manager")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct LandingAppHeaderView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image("kubb1024")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
            
            Text("Improve your kubb skills with training, track your games, and analyze your progress")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top, 20)
    }
}

struct MainActionButton: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundColor(color)
                    .frame(width: 60, height: 60)
                
                // Content
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
                
                // Arrow
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
struct MainTabView: View {
    @StateObject private var sessionManager = SessionManager()
    @Binding var selectedTab: Int
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Training Tab
            TrainingTabView()
                .tabItem {
                    Image(systemName: "figure.strengthtraining.traditional.circle.fill")
                    Text("Training")
                }
                .tag(0)
            
            // Game Logs Tab
            GameLogsTabView()
                .tabItem {
                    Image(systemName: "play.circle.fill")
                    Text("Game Logs")
                }
                .tag(1)
            
            // Stats Tab
            StatsTabView()
                .tabItem {
                    Image(systemName: "chart.line.text.clipboard")
                    Text("Stats")
                }
                .tag(2)
        }
        .environmentObject(sessionManager)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            sessionManager.handleAppWillResignActive()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            sessionManager.handleAppDidEnterBackground()
        }
    }
}

// MARK: - Training Tab
struct TrainingTabView: View {
    @State private var selectedMode: TrainingMode?
    @State private var showingEightMeterTraining = false
    @State private var showingInkastBlast = false
    @State private var showingFullGameSim = false
    @State private var showingOptions = false
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
                    
                    // Coming Soon Notice
                    ComingSoonNoticeView()
                }
                .padding()
            }
            
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Options") {
                        showingOptions = true
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingEightMeterTraining) {
            EightMeterTrainingView()
        }
        .fullScreenCover(isPresented: $showingInkastBlast) {
            InkastBlastView(
                persistenceController: PersistenceController.shared,
                cloudKitManager: CloudKitManager.shared
            )
        }
        .fullScreenCover(isPresented: $showingFullGameSim) {
            FullGameSimComingSoonView()
        }
        .sheet(isPresented: $showingOptions) {
            OptionsView()
                .environmentObject(settingsManager)
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
