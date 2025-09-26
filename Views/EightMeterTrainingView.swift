//
//  EightMeterTrainingView.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 9/23/25.
//

import SwiftUI

struct EightMeterTrainingView: View {
    @EnvironmentObject private var sessionManager: SessionManager
    @State private var selectedTab = 0
    @State private var showingPracticeView = false
    @State private var showingRecoveryAlert = false
    @State private var showingTutorial = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                // Overview Tab
                HomeView(selectedTab: $selectedTab)
                    .tabItem {
                        Image(systemName: "chart.bar.fill")
                        Text("Overview")
                    }
                    .tag(0)
                
                // Practice Tab
                if sessionManager.isSessionActive {
                    PracticeView()
                        .tabItem {
                            Image(systemName: "target")
                            Text("Practice")
                        }
                        .tag(1)
                } else if sessionManager.hasIncompleteSession() {
                    IncompleteSessionPracticeView()
                        .tabItem {
                            Image(systemName: "target")
                            Text("Practice")
                        }
                        .tag(1)
                } else {
                    TargetSettingView()
                        .tabItem {
                            Image(systemName: "target")
                            Text("Practice")
                        }
                        .tag(1)
                }
                
                // History Tab
                HistoryView()
                    .tabItem {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("History")
                    }
                    .tag(2)
                
                // Tutorial Tab
                TutorialOverviewView()
                    .tabItem {
                        Image(systemName: "questionmark.circle")
                        Text("Tutorial")
                    }
                    .tag(3)
            }
            .navigationTitle("8 Meter Training")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back to Menu") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Incomplete Practice Session", isPresented: $showingRecoveryAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Resume", role: .none) {
                sessionManager.resumeSession()
                selectedTab = 1
            }
            Button("Delete", role: .destructive) {
                Task {
                    await sessionManager.deleteIncompleteSession()
                }
            }
        } message: {
            if let session = sessionManager.currentSession {
                Text("You have an incomplete practice session from \(session.date.formatted(date: .abbreviated, time: .shortened)). What would you like to do?")
            } else {
                Text("You have an incomplete practice session. What would you like to do?")
            }
        }
        .onAppear {
            checkForIncompleteSession()
        }
        .onChange(of: sessionManager.isSessionActive) { _, isActive in
            if isActive {
                selectedTab = 1
            }
        }
        .fullScreenCover(isPresented: $showingTutorial) {
            EightMeterTutorialView()
        }
    }
    
    private func checkForIncompleteSession() {
        if sessionManager.shouldShowRecoveryAlert() {
            showingRecoveryAlert = true
        }
    }
}

struct TutorialOverviewView: View {
    @State private var showingTutorial = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        Text("8-Meter Training Tutorial")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text("Learn how to set up your pitch and run training sessions")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Quick Overview
                    VStack(spacing: 20) {
                        Text("What You'll Learn")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 12) {
                            TutorialFeatureRow(
                                icon: "target",
                                title: "Pitch Setup",
                                description: "Equipment needed and how to set up your training area"
                            )
                            
                            TutorialFeatureRow(
                                icon: "hand.raised",
                                title: "Proper Technique",
                                description: "Correct throwing rules and safety considerations"
                            )
                            
                            TutorialFeatureRow(
                                icon: "arrow.triangle.2.circlepath",
                                title: "Round Process",
                                description: "Step-by-step guide for completing training rounds"
                            )
                            
                            TutorialFeatureRow(
                                icon: "chart.line.uptrend.xyaxis",
                                title: "Progress Tracking",
                                description: "How to reach your daily target and track improvement"
                            )
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    
                    // Start Tutorial Button
                    Button(action: {
                        showingTutorial = true
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Start Tutorial")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationTitle("Tutorial")
            .navigationBarTitleDisplayMode(.inline)
        }
        .fullScreenCover(isPresented: $showingTutorial) {
            EightMeterTutorialView()
        }
    }
}

struct TutorialFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    EightMeterTrainingView()
        .environmentObject(SessionManager())
}
