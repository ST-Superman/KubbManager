//
//  StatsView.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 9/23/25.
//

import SwiftUI
import Charts

// MARK: - DateFormatter Extensions
extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
    
    static let gameDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - Data Types
struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let accuracy: Double
    let kubbs: Int
    let batons: Int
}

// MARK: - Main Stats View
struct StatsView: View {
    @StateObject private var unifiedStatsManager = UnifiedStatisticsManager.shared
    @State private var selectedTab: StatsTab = .trainingOverview
    
    enum StatsTab: String, CaseIterable {
        case trainingOverview = "Training Overview"
        case practice = "8 Meters"
        case inkastBlast = "Inkast & Blast"
        case gameLogs = "Game Logs"
        case baseballKubb = "Baseball Kubb"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Dropdown Menu - fixed at top, outside scrollable area
            VStack(spacing: 8) {
                HStack {
                    Text("Type:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Menu {
                        ForEach(StatsTab.allCases, id: \.self) { tab in
                            Button(action: {
                                selectedTab = tab
                            }) {
                                HStack {
                                    Text(tab.rawValue)
                                    if selectedTab == tab {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedTab.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .background(Color(.systemBackground))
            
            // Scrollable content area
            if unifiedStatsManager.isLoading && unifiedStatsManager.practiceSessions.isEmpty {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading statistics...")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        // Content based on selected tab
                        switch selectedTab {
                    case .trainingOverview:
                        TrainingOverviewStatsSection()
                            .environmentObject(unifiedStatsManager)
                            .onAppear {
                                Task {
                                    await unifiedStatsManager.loadAllSessionsIfNeeded()
                                }
                            }
                    case .practice:
                        PracticeStatsSection()
                            .environmentObject(unifiedStatsManager)
                            .onAppear {
                                Task {
                                    await unifiedStatsManager.loadAllSessionsIfNeeded()
                                }
                            }
                    case .inkastBlast:
                        InkastBlastStatsSection()
                            .environmentObject(unifiedStatsManager)
                            .onAppear {
                                Task {
                                    await unifiedStatsManager.loadAllSessionsIfNeeded()
                                }
                            }
                    case .gameLogs:
                        GameLogsStatsSection()
                            .environmentObject(unifiedStatsManager)
                            .onAppear {
                                Task {
                                    await unifiedStatsManager.loadAllSessionsIfNeeded()
                                }
                            }
                    case .baseballKubb:
                        BaseballKubbStatsSection()
                            .environmentObject(unifiedStatsManager)
                            .onAppear {
                                Task {
                                    await unifiedStatsManager.loadAllSessionsIfNeeded()
                                }
                            }
                    }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
        }
        .onAppear {
            Task {
                // Always try to load fresh data when the view appears
                await unifiedStatsManager.loadAllSessions()
            }
        }
        .refreshable {
            await unifiedStatsManager.refreshAllSessions()
        }
    }
}

// MARK: - Training Overview Stats Section
struct TrainingOverviewStatsSection: View {
    @EnvironmentObject private var statsManager: UnifiedStatisticsManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Training Overview")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            // Main stats grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                TrainingStatCard(
                    title: "Training Sessions",
                    value: "\(statsManager.trainingStats.totalTrainingSessions)",
                    icon: "calendar.badge.plus",
                    color: .blue,
                    description: "The total number of training sessions you've completed across all training modes (8M Training and Inkast & Blast). This includes both completed and paused sessions."
                )
                
                TrainingStatCard(
                    title: "Max Training Streak",
                    value: "\(statsManager.trainingStats.maxTrainingStreak) days",
                    icon: "flame.fill",
                    color: .red,
                    description: "Your longest consecutive streak of days with at least one training session. This shows your best period of consistent training."
                )
                
                TrainingStatCard(
                    title: "Current Streak",
                    value: "\(statsManager.trainingStats.currentTrainingStreak) days",
                    icon: "flame",
                    color: .orange,
                    description: "Your current consecutive streak of days with training sessions. This resets if you miss a day of training."
                )
                
                TrainingStatCard(
                    title: "8M Throws",
                    value: "\(statsManager.trainingStats.totalEightMeterThrows)",
                    icon: "arrow.right.circle.fill",
                    color: .green,
                    description: "The total number of 8-meter (baseline) throws you've made across all training sessions. This includes throws from 8M Training sessions and any 8M throws from other training modes."
                )
                
                TrainingStatCard(
                    title: "8M Accuracy",
                    value: String(format: "%.1f%%", statsManager.trainingStats.eightMeterAccuracy * 100),
                    icon: "target",
                    color: .purple,
                    description: "Your overall accuracy for 8-meter throws, calculated as the percentage of throws that successfully hit kubbs. Higher percentages indicate better precision."
                )
                
                TrainingStatCard(
                    title: "Inkast Kubbs",
                    value: "\(statsManager.trainingStats.totalInkastKubbs)",
                    icon: "target",
                    color: .cyan,
                    description: "The total number of kubbs you've successfully inkast (thrown into the field) during Inkast & Blast training sessions."
                )
                
                TrainingStatCard(
                    title: "Penalty Kubbs",
                    value: "\(statsManager.trainingStats.totalPenaltyKubbs)",
                    icon: "exclamationmark.triangle.fill",
                    color: .red,
                    description: "The total number of penalty kubbs you've thrown during Inkast & Blast sessions. Penalty kubbs are kubbs that go out of bounds on the second attempt."
                )
                
                TrainingStatCard(
                    title: "Neighbors",
                    value: "\(statsManager.trainingStats.totalNeighbors)",
                    icon: "person.2.fill",
                    color: .yellow,
                    description: "The total number of neighbor kubbs you've thrown during Inkast & Blast sessions. A Neighbor means that an inkasted kubb has landed on top of another kubb (or kubbs) and is not touching the ground at all."
                )
                
                TrainingStatCard(
                    title: "Field Handicap",
                    value: String(format: "%.1f", statsManager.trainingStats.fieldHandicap),
                    icon: "scope",
                    color: .brown,
                    description: "Your average performance against target baton counts, calculated like a golf handicap. Lower numbers are better - negative values mean you're performing better than the target."
                )
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
}

// MARK: - Training Stat Card
struct TrainingStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let description: String
    @State private var showingDescription = false
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onTapGesture {
            showingDescription = true
        }
        .sheet(isPresented: $showingDescription) {
            StatDescriptionView(
                title: title,
                value: value,
                description: description,
                icon: icon,
                color: color
            )
        }
    }
}

// MARK: - Stat Description View
struct StatDescriptionView: View {
    let title: String
    let value: String
    let description: String
    let icon: String
    let color: Color
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: icon)
                            .font(.system(size: 60))
                            .foregroundColor(color)
                        
                        Text(title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text(value)
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundColor(color)
                    }
                    .padding(.top, 20)
                    
                    // Description
                    VStack(alignment: .leading, spacing: 16) {
                        Text("What does this mean?")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationTitle("Statistic Details")
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

// MARK: - Game Logs Stats Section
struct GameLogsStatsSection: View {
    @EnvironmentObject private var statsManager: UnifiedStatisticsManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Game Logs Overview")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                TrainingStatCard(
                    title: "Total Games",
                    value: "\(statsManager.gameLogStats.totalGames)",
                    icon: "gamecontroller.fill",
                    color: .blue,
                    description: "The total number of Baseball Kubb games you've recorded, including competitive games, practice games, and games where you were a spectator."
                )
                
                TrainingStatCard(
                    title: "Competitive Games",
                    value: "\(statsManager.gameLogStats.competitiveGames)",
                    icon: "person.2.fill",
                    color: .green,
                    description: "The number of games where you played on a specific team (either away or home) and your performance counts toward your record. Excludes practice games and spectator games."
                )
                
                TrainingStatCard(
                    title: "Wins",
                    value: "\(statsManager.gameLogStats.wins)",
                    icon: "checkmark.circle.fill",
                    color: .green,
                    description: "The number of competitive games where your team scored more runs than the opposing team."
                )
                
                TrainingStatCard(
                    title: "Losses",
                    value: "\(statsManager.gameLogStats.losses)",
                    icon: "xmark.circle.fill",
                    color: .red,
                    description: "The number of competitive games where your team scored fewer runs than the opposing team."
                )
                
                TrainingStatCard(
                    title: "Ties",
                    value: "\(statsManager.gameLogStats.ties)",
                    icon: "minus.circle.fill",
                    color: .orange,
                    description: "The number of competitive games where your team and the opposing team scored the same number of runs."
                )
                
                TrainingStatCard(
                    title: "Win Rate",
                    value: String(format: "%.1f%%", statsManager.gameLogStats.winRate * 100),
                    icon: "percent",
                    color: .purple,
                    description: "Your winning percentage in competitive games, calculated as wins divided by total competitive games. Higher percentages indicate better competitive performance."
                )
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
}

// MARK: - Practice Stats Section
struct PracticeStatsSection: View {
    @EnvironmentObject private var statsManager: UnifiedStatisticsManager
    @State private var selectedDate: Date?
    @State private var availableDates: [Date] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("8M Training Statistics")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            let stats = statsManager.modeSpecificStats.practiceStats
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                TrainingStatCard(
                    title: "Total Sessions",
                    value: "\(stats.totalSessions)",
                    icon: "calendar.badge.plus",
                    color: .blue,
                    description: "The total number of 8M Training sessions you've completed. This includes all practice sessions focused on 8-meter throwing technique."
                )
                
                TrainingStatCard(
                    title: "Total Batons",
                    value: "\(stats.totalBatonsThrown)",
                    icon: "arrow.right.circle.fill",
                    color: .green,
                    description: "The total number of batons you've thrown during 8M Training sessions. This represents your practice volume for 8-meter throws."
                )
                
                TrainingStatCard(
                    title: "Total Kubbs Hit",
                    value: "\(stats.totalKubbsHit)",
                    icon: "target",
                    color: .orange,
                    description: "The total number of kubbs you've successfully hit during 8M Training sessions. This shows your overall success rate."
                )
                
                TrainingStatCard(
                    title: "Overall Accuracy",
                    value: String(format: "%.1f%%", stats.overallAccuracy * 100),
                    icon: "checkmark.circle.fill",
                    color: .purple,
                    description: "Your overall accuracy for 8M Training, calculated as the percentage of batons that successfully hit kubbs. This is the key metric for measuring your 8-meter throwing skill."
                )
            }
            
            // Round-by-round accuracy trend chart
            RoundByRoundAccuracyChart()
                .environmentObject(statsManager)
            
            // Date selection for detailed view
            if !availableDates.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Session Details")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Menu {
                        ForEach(availableDates, id: \.self) { date in
                            Button(action: {
                                selectedDate = date
                            }) {
                                HStack {
                                    Text(DateFormatter.shortDate.string(from: date))
                                    if selectedDate == date {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedDate != nil ? DateFormatter.shortDate.string(from: selectedDate!) : "Select Date")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // Round-by-round accuracy graph for selected date
                    if let selectedDate = selectedDate {
                        let roundData = statsManager.getRoundAccuracyForDate(selectedDate)
                        if !roundData.isEmpty {
                            HStack(alignment: .bottom, spacing: 4) {
                                ForEach(Array(roundData.enumerated()), id: \.offset) { index, accuracy in
                                    VStack {
                                        Rectangle()
                                            .fill(Color.green.opacity(0.7))
                                            .frame(width: 20, height: max(4, CGFloat(accuracy) * 100))
                                            .cornerRadius(2)
                                        
                                        Text("R\(index + 1)")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .frame(height: 100)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
        .onAppear {
            availableDates = statsManager.getAvailablePracticeDates()
        }
    }
}

// MARK: - Inkast Blast Stats Section
struct InkastBlastStatsSection: View {
    @EnvironmentObject private var statsManager: UnifiedStatisticsManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Inkast & Blast Statistics")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            let stats = statsManager.modeSpecificStats.inkastBlastStats
            
            // Overall Statistics
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                TrainingStatCard(
                    title: "Total Sessions",
                    value: "\(stats.totalSessions)",
                    icon: "calendar.badge.plus",
                    color: .blue,
                    description: "The total number of Inkast & Blast training sessions you've completed. These sessions focus on both inkast (throwing kubbs into the field) and blast (knocking down field kubbs) techniques."
                )
                
                TrainingStatCard(
                    title: "Total Rounds",
                    value: "\(stats.totalRounds)",
                    icon: "arrow.clockwise",
                    color: .green,
                    description: "The total number of rounds you've completed across all Inkast & Blast sessions. Each round involves both inkast and blast phases."
                )
                
                TrainingStatCard(
                    title: "Overall Handicap",
                    value: String(format: "%.1f", stats.overallHandicap),
                    icon: "scope",
                    color: .purple,
                    description: "Your average performance against target baton counts across all Inkast & Blast rounds. Lower numbers are better - negative values mean you're performing better than the target."
                )
                
                TrainingStatCard(
                    title: "First Inkast Rate",
                    value: String(format: "%.1f%%", stats.firstInkastRate * 100),
                    icon: "target",
                    color: .cyan,
                    description: "The percentage of inkast kubbs that land inbounds on the first attempt. Higher percentages indicate better inkast accuracy and control."
                )
                
            }
            
            // Phase-specific statistics
            VStack(alignment: .leading, spacing: 12) {
                Text("Phase Performance")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                // Early Game
                VStack(alignment: .leading, spacing: 8) {
                    Text("Early Game")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Handicap")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.1f", stats.earlyGameHandicap))
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("First Inkast")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.1f%%", stats.earlyGameFirstInkastRate * 100))
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Blast Eff.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.1f", stats.earlyGameBlastEfficiency))
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Rounds")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("\(stats.earlyGameTotalRounds)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Mid Game
                VStack(alignment: .leading, spacing: 8) {
                    Text("Mid Game")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Handicap")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.1f", stats.midGameHandicap))
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("First Inkast")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.1f%%", stats.midGameFirstInkastRate * 100))
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Blast Eff.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.1f", stats.midGameBlastEfficiency))
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Rounds")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("\(stats.midGameTotalRounds)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // End Game
                VStack(alignment: .leading, spacing: 8) {
                    Text("End Game")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Handicap")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.1f", stats.endGameHandicap))
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("First Inkast")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.1f%%", stats.endGameFirstInkastRate * 100))
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Blast Eff.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.1f", stats.endGameBlastEfficiency))
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Rounds")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("\(stats.endGameTotalRounds)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
}

// MARK: - Baseball Kubb Stats Section
struct BaseballKubbStatsSection: View {
    @EnvironmentObject private var statsManager: UnifiedStatisticsManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Baseball Kubb Games")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            let games = statsManager.baseballKubbSessions.sorted { $0.date > $1.date }
            
            if games.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "gamecontroller")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    
                    Text("No games recorded yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(games, id: \.id) { game in
                        BaseballKubbGameRow(game: game)
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
}

// MARK: - Baseball Kubb Game Row
struct BaseballKubbGameRow: View {
    let game: BaseballKubbSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(game.awayTeam)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(game.userTeam == .away ? .blue : .primary)
                    
                    Text(game.homeTeam)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(game.userTeam == .home ? .blue : .primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(game.awayScore)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(game.userTeam == .away ? .blue : .primary)
                    
                    Text("\(game.homeScore)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(game.userTeam == .home ? .blue : .primary)
                }
            }
            
            HStack {
                Text(DateFormatter.gameDate.string(from: game.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if game.userTeam == .both {
                    Text("Both Teams")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(4)
                } else if game.userTeam == .none {
                    Text("Spectator")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                } else {
                    Text("Your Team")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(4)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Round-by-Round Accuracy Chart

struct RoundByRoundAccuracyChart: View {
    @EnvironmentObject private var statsManager: UnifiedStatisticsManager
    @State private var selectedSessionId: String?
    @State private var isShowingAllSessions = true
    @State private var chartData: [RoundAccuracyDataPoint] = []
    @State private var trellisData: [SessionTrellisData] = []
    
    private let settingsManager = SettingsManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with controls
            HStack {
                Text("Round-by-Round Accuracy Trend")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Debug button (only show in debug builds)
                #if DEBUG
                Button("Debug") {
                    statsManager.debugDataStatus()
                }
                .font(.caption)
                .foregroundColor(.blue)
                #endif
                
                // Toggle between all sessions and individual sessions
                Picker("View", selection: $isShowingAllSessions) {
                    Text("All Sessions").tag(true)
                    Text("By Session").tag(false)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 200)
            }
            
            if chartData.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    
                    Text("No round data available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button("Force Reload Data") {
                        Task {
                            await statsManager.forceReload()
                            loadChartData()
                        }
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.blue)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                if isShowingAllSessions {
                    // Single large chart with all data
                    AllSessionsChartView(
                        data: chartData,
                        targetAccuracy: settingsManager.chartTargetAccuracy
                    )
                } else {
                    // Trellis view by session
                    TrellisChartView(
                        data: trellisData,
                        targetAccuracy: settingsManager.chartTargetAccuracy
                    )
                }
            }
        }
        .onAppear {
            loadChartData()
        }
        .onChange(of: statsManager.practiceSessions) {
            loadChartData()
        }
    }
    
    private func loadChartData() {
        chartData = statsManager.getRoundByRoundAccuracyData()
        trellisData = statsManager.getSessionsForTrellis()
    }
}

// MARK: - All Sessions Chart View

struct AllSessionsChartView: View {
    let data: [RoundAccuracyDataPoint]
    let targetAccuracy: Double
    
    @State private var selectedRange: ClosedRange<Int> = 0...19
    @State private var isDragging = false
    @State private var selectedTimePeriod: TimePeriod = .last20
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGFloat = 0.0
    
    enum TimePeriod: String, CaseIterable {
        case last10 = "Last 10"
        case last20 = "Last 20"
        case last50 = "Last 50"
        case all = "All"
        
        var rangeSize: Int {
            switch self {
            case .last10: return 10
            case .last20: return 20
            case .last50: return 50
            case .all: return Int.max
            }
        }
    }
    
    init(data: [RoundAccuracyDataPoint], targetAccuracy: Double) {
        self.data = data
        self.targetAccuracy = targetAccuracy
        
        // Set default range to show last 20 rounds
        let visibleRangeSize = 20
        if data.count > visibleRangeSize {
            let startIndex = max(0, data.count - visibleRangeSize)
            self._selectedRange = State(initialValue: startIndex...(data.count - 1))
        } else {
            self._selectedRange = State(initialValue: 0...(data.count - 1))
        }
    }
    
    private var visibleData: [RoundAccuracyDataPoint] {
        guard !data.isEmpty else { return [] }
        let startIndex = max(0, selectedRange.lowerBound)
        let endIndex = min(data.count - 1, selectedRange.upperBound)
        return Array(data[startIndex...endIndex])
    }
    
    private var maxAccuracy: Double {
        max(1.0, (visibleData.map { $0.accuracy }.max() ?? 0.0) * 1.1)
    }
    
    private var trendLineData: [TrendPoint] {
        guard visibleData.count > 1 else { return [] }
        
        // Calculate 5-round moving average for smoother trend
        let windowSize = min(5, visibleData.count)
        var trendPoints: [TrendPoint] = []
        
        for i in 0..<visibleData.count {
            let startIndex = max(0, i - windowSize + 1)
            let endIndex = i + 1
            let windowData = Array(visibleData[startIndex..<endIndex])
            
            let averageAccuracy = windowData.map { $0.accuracy }.reduce(0, +) / Double(windowData.count)
            
            trendPoints.append(TrendPoint(
                x: Double(i),
                y: averageAccuracy,
                roundNumber: visibleData[i].globalRoundNumber
            ))
        }
        
        return trendPoints
    }
    
    private var performanceZones: [PerformanceZone] {
        guard !visibleData.isEmpty else { return [] }
        
        let firstRound = visibleData.first!.globalRoundNumber
        let lastRound = visibleData.last!.globalRoundNumber
        
        return [
            PerformanceZone(
                startRound: firstRound,
                endRound: lastRound,
                upperBound: 1.0,
                lowerBound: targetAccuracy,
                color: .green.opacity(0.1)
            ),
            PerformanceZone(
                startRound: firstRound,
                endRound: lastRound,
                upperBound: targetAccuracy,
                lowerBound: 0.0,
                color: .red.opacity(0.1)
            )
        ]
    }
    
    private func updateRangeForTimePeriod(_ period: TimePeriod) {
        let rangeSize = min(period.rangeSize, data.count)
        if data.count > rangeSize {
            let startIndex = max(0, data.count - rangeSize)
            selectedRange = startIndex...(data.count - 1)
        } else {
            selectedRange = 0...(data.count - 1)
        }
        selectedTimePeriod = period
    }
    
    private func resetToDefault() {
        updateRangeForTimePeriod(.last20)
        scale = 1.0
        offset = 0.0
    }
    
    private var userFriendlyRangeText: String {
        guard !data.isEmpty else { return "No data" }
        let startRound = selectedRange.lowerBound + 1
        let endRound = selectedRange.upperBound + 1
        let totalRounds = data.count
        
        if selectedTimePeriod == .all {
            return "All \(totalRounds) rounds"
        } else {
            return "Rounds \(startRound)-\(endRound) of \(totalRounds)"
        }
    }
    
    private var chartView: some View {
        Chart {
            // Performance zones (background)
            ForEach(performanceZones) { zone in
                RectangleMark(
                    xStart: .value("Start", zone.startRound),
                    xEnd: .value("End", zone.endRound),
                    yStart: .value("Lower", zone.lowerBound),
                    yEnd: .value("Upper", zone.upperBound)
                )
                .foregroundStyle(zone.color)
            }
            
            // Target line (horizontal reference)
            RuleMark(y: .value("Target", targetAccuracy))
                .foregroundStyle(.red)
                .lineStyle(StrokeStyle(lineWidth: 3))
            
            // Trend line (moving average) - most prominent
            ForEach(trendLineData) { trendPoint in
                LineMark(
                    x: .value("Round", trendPoint.roundNumber),
                    y: .value("Trend", trendPoint.y)
                )
                .foregroundStyle(.green)
                .lineStyle(StrokeStyle(lineWidth: 4))
            }
            
            // Individual data points (smaller, less prominent)
            ForEach(visibleData) { point in
                PointMark(
                    x: .value("Round", point.globalRoundNumber),
                    y: .value("Accuracy", point.accuracy)
                )
                .foregroundStyle(.blue.opacity(0.6))
                .symbolSize(20)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Time period selector
            Picker("Time Period", selection: $selectedTimePeriod) {
                ForEach(TimePeriod.allCases, id: \.self) { period in
                    Text(period.rawValue).tag(period)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: selectedTimePeriod) { _, newPeriod in
                updateRangeForTimePeriod(newPeriod)
            }
            
            // Range info
            Text(userFriendlyRangeText)
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Main chart with proper scales and gestures
            chartView
            .chartYScale(domain: 0...maxAccuracy)
            .chartXScale(domain: selectedRange.lowerBound...selectedRange.upperBound)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let accuracy = value.as(Double.self) {
                            Text("\(Int(accuracy * 100))%")
                                .font(.caption)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(position: .bottom) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let round = value.as(Int.self) {
                            Text("\(round)")
                                .font(.caption)
                        }
                    }
                }
            }
            .frame(height: 350)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .scaleEffect(scale)
            .offset(x: offset)
            .gesture(
                SimultaneousGesture(
                    // Pinch to zoom
                    MagnificationGesture()
                        .onChanged { value in
                            scale = max(0.5, min(2.0, value))
                        },
                    // Pan to navigate (when zoomed)
                    DragGesture()
                        .onChanged { value in
                            if scale > 1.0 {
                                offset = value.translation.width
                            }
                        }
                        .onEnded { _ in
                            // Reset offset when drag ends
                            withAnimation(.easeOut(duration: 0.3)) {
                                offset = 0
                            }
                        }
                )
            )
            .onTapGesture(count: 2) {
                // Double tap to reset
                withAnimation(.easeInOut(duration: 0.3)) {
                    resetToDefault()
                }
            }
            
            // Legend
            VStack(spacing: 8) {
                HStack(spacing: 16) {
                    // Trend line (most prominent)
                    HStack(spacing: 4) {
                        Rectangle()
                            .fill(Color.green)
                            .frame(width: 24, height: 4)
                        Text("5-Round Trend")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    
                    // Target line
                    HStack(spacing: 4) {
                        Rectangle()
                            .fill(Color.red)
                            .frame(width: 24, height: 4)
                        Text("Target (\(Int(targetAccuracy * 100))%)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    
                    // Individual points
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.blue.opacity(0.6))
                            .frame(width: 8, height: 8)
                        Text("Individual Rounds")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("\(visibleData.count) rounds shown")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Performance zones explanation
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Rectangle()
                            .fill(Color.green.opacity(0.1))
                            .frame(width: 16, height: 12)
                        Text("Above Target")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 4) {
                        Rectangle()
                            .fill(Color.red.opacity(0.1))
                            .frame(width: 16, height: 12)
                        Text("Below Target")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
            .padding(.horizontal)
            
            // Gesture instructions
            HStack {
                Image(systemName: "hand.pinch")
                    .foregroundColor(.secondary)
                Text("Pinch to zoom • Double-tap to reset")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Trellis Chart View

struct TrellisChartView: View {
    let data: [SessionTrellisData]
    let targetAccuracy: Double
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(data) { sessionData in
                    VStack(alignment: .leading, spacing: 12) {
                        // Session header
                        HStack {
                            Text(DateFormatter.shortDate.string(from: sessionData.sessionDate))
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text("\(sessionData.rounds.count) rounds")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Mini chart for this session
                        Chart(sessionData.rounds) { point in
                            // Accuracy line
                            LineMark(
                                x: .value("Round", point.roundNumber),
                                y: .value("Accuracy", point.accuracy)
                            )
                            .foregroundStyle(.blue)
                            .lineStyle(StrokeStyle(lineWidth: 2))
                            
                            // Data points
                            PointMark(
                                x: .value("Round", point.roundNumber),
                                y: .value("Accuracy", point.accuracy)
                            )
                            .foregroundStyle(.blue)
                            .symbolSize(20)
                            
                            // Target line
                            RuleMark(y: .value("Target", targetAccuracy))
                                .foregroundStyle(.red)
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        }
                        .chartYScale(domain: 0...1.0)
                        .chartYAxis {
                            AxisMarks(position: .leading) { value in
                                AxisGridLine()
                                AxisValueLabel {
                                    if let accuracy = value.as(Double.self) {
                                        Text("\(Int(accuracy * 100))%")
                                            .font(.caption2)
                                    }
                                }
                            }
                        }
                        .chartXAxis {
                            AxisMarks(position: .bottom) { value in
                                AxisValueLabel {
                                    if let round = value.as(Int.self) {
                                        Text("\(round)")
                                            .font(.caption2)
                                    }
                                }
                            }
                        }
                        .frame(height: 150)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
            }
            .padding(.horizontal)
        }
    }
}


#Preview {
    StatsView()
}
