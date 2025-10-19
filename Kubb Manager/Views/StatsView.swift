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
        case fullGameSim = "Full Game Sim"
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
                        SimplifiedTrainingOverview(selectedTab: $selectedTab)
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
                    case .fullGameSim:
                        FullGameSimStatsSection()
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

// MARK: - Simplified Training Overview (Session-Type Specific)
struct SimplifiedTrainingOverview: View {
    @EnvironmentObject private var statsManager: UnifiedStatisticsManager
    @Binding var selectedTab: StatsView.StatsTab

    var body: some View {
        VStack(spacing: 24) {
            // Header
            Text("Training Statistics by Session Type")
                .font(.title3)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            // Standard 8-Meter Practice Section
            SessionTypeSection(
                title: "Standard 8-Meter Practice",
                icon: "target",
                iconColor: .blue,
                selectedTab: $selectedTab,
                targetTab: .practice
            ) {
                Standard8MeterOverviewCards()
                    .environmentObject(statsManager)
            }

            // Inkast & Blast Section
            SessionTypeSection(
                title: "Inkast & Blast",
                icon: "scope",
                iconColor: .orange,
                selectedTab: $selectedTab,
                targetTab: .inkastBlast
            ) {
                InkastBlastOverviewCards()
                    .environmentObject(statsManager)
            }

            // Full Game Sim Section
            SessionTypeSection(
                title: "Full Game Sim",
                icon: "figure.2.and.child.holdinghands",
                iconColor: .green,
                selectedTab: $selectedTab,
                targetTab: .fullGameSim
            ) {
                FullGameSimOverviewCards()
                    .environmentObject(statsManager)
            }

            // Baseball Kubb Section
            SessionTypeSection(
                title: "Baseball Kubb",
                icon: "baseball.fill",
                iconColor: .red,
                selectedTab: $selectedTab,
                targetTab: .baseballKubb
            ) {
                BaseballKubbOverviewCards()
                    .environmentObject(statsManager)
            }
        }
        .padding(.vertical)
    }
}

// MARK: - Session Type Section (Clickable Header + Cards)
struct SessionTypeSection<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    @Binding var selectedTab: StatsView.StatsTab
    let targetTab: StatsView.StatsTab
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Clickable Header
            Button(action: {
                selectedTab = targetTab
            }) {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(iconColor)

                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())

            // Content Cards
            content
                .padding(.horizontal)
        }
        .padding(.horizontal)
    }
}

// MARK: - Standard 8-Meter Overview Cards
struct Standard8MeterOverviewCards: View {
    @EnvironmentObject private var statsManager: UnifiedStatisticsManager

    private var practiceSessions: [PracticeSession] {
        statsManager.practiceSessions.filter { $0.isComplete }
    }

    private var totalBatons: Int {
        practiceSessions.reduce(0) { $0 + $1.totalBatons }
    }

    private var recentSessions: [PracticeSession] {
        Array(practiceSessions.sorted { $0.startTime > $1.startTime }.prefix(5))
    }

    private var recentAccuracy: Double {
        recentSessions.isEmpty ? 0.0 : recentSessions.reduce(0.0) { $0 + $1.accuracy } / Double(recentSessions.count)
    }

    private var lifetimeAccuracy: Double {
        practiceSessions.isEmpty ? 0.0 : practiceSessions.reduce(0.0) { $0 + $1.accuracy } / Double(practiceSessions.count)
    }

    private var trend: String {
        if abs(recentAccuracy - lifetimeAccuracy) < 0.02 {
            return "→ Stable"
        } else if recentAccuracy > lifetimeAccuracy {
            return "↑ Improving"
        } else {
            return "↓ Declining"
        }
    }

    private var trendColor: Color {
        if abs(recentAccuracy - lifetimeAccuracy) < 0.02 {
            return .orange
        } else if recentAccuracy > lifetimeAccuracy {
            return .green
        } else {
            return .red
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Total Batons Card
            VStack(spacing: 8) {
                Image(systemName: "bolt.fill")
                    .font(.title2)
                    .foregroundColor(.blue)

                Text("\(totalBatons)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text("Total Batons")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)

            // Accuracy Card
            VStack(spacing: 8) {
                Image(systemName: "target")
                    .font(.title2)
                    .foregroundColor(.green)

                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Text("Recent:")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1f%%", recentAccuracy * 100))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }

                    HStack(spacing: 4) {
                        Text("Lifetime:")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1f%%", lifetimeAccuracy * 100))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    Text(trend)
                        .font(.caption)
                        .foregroundColor(trendColor)
                        .fontWeight(.medium)
                }

                Text("Accuracy")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }
}

// MARK: - Inkast & Blast Overview Cards
struct InkastBlastOverviewCards: View {
    @EnvironmentObject private var statsManager: UnifiedStatisticsManager

    private var sessions: [InkastBlastSessionData] {
        statsManager.inkastBlastSessions.filter { $0.isComplete }
    }

    var body: some View {
        VStack(spacing: 12) {
            // Row 1: Overall and Early Game
            HStack(spacing: 12) {
                PhaseCard(
                    title: "Overall",
                    phase: .all,
                    sessions: sessions,
                    iconColor: .purple
                )

                PhaseCard(
                    title: "Early Game",
                    subtitle: "1-3 kubbs",
                    phase: .early,
                    sessions: sessions,
                    iconColor: .green
                )
            }

            // Row 2: Mid Game and End Game
            HStack(spacing: 12) {
                PhaseCard(
                    title: "Mid Game",
                    subtitle: "4-7 kubbs",
                    phase: .mid,
                    sessions: sessions,
                    iconColor: .orange
                )

                PhaseCard(
                    title: "End Game",
                    subtitle: "8-10 kubbs",
                    phase: .end,
                    sessions: sessions,
                    iconColor: .red
                )
            }
        }
    }
}

struct PhaseCard: View {
    let title: String
    var subtitle: String? = nil
    let phase: GamePhase
    let sessions: [InkastBlastSessionData]
    let iconColor: Color

    private var phaseRounds: [InkastBlastRoundData] {
        sessions.flatMap { session in
            session.rounds.filter { round in
                let roundPhase = session.gamePhaseForRound(round)
                return phase == .all || roundPhase == phase
            }
        }
    }

    private var totalRounds: Int {
        phaseRounds.count
    }

    private var recentRounds: [InkastBlastRoundData] {
        Array(phaseRounds.suffix(5))
    }

    private var recentHandicap: Double {
        calculateHandicap(rounds: recentRounds)
    }

    private var lifetimeHandicap: Double {
        calculateHandicap(rounds: phaseRounds)
    }

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "scope")
                .font(.title3)
                .foregroundColor(iconColor)

            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Divider()

            VStack(spacing: 2) {
                Text("\(totalRounds)")
                    .font(.headline)
                    .fontWeight(.bold)
                Text("rounds")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Divider()

            VStack(spacing: 2) {
                Text("Handicap")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                HStack(spacing: 4) {
                    Text("Recent:")
                        .font(.caption2)
                    Text(String(format: "%+.1f", recentHandicap))
                        .font(.caption)
                        .fontWeight(.semibold)
                }

                HStack(spacing: 4) {
                    Text("Lifetime:")
                        .font(.caption2)
                    Text(String(format: "%+.1f", lifetimeHandicap))
                        .font(.caption)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    func calculateHandicap(rounds: [InkastBlastRoundData]) -> Double {
        guard !rounds.isEmpty else { return 0.0 }
        let totalHandicap = rounds.reduce(0.0) { sum, round in
            let target = round.targetBatons
            let actual = round.batonsUsed
            return sum + Double(actual - target)
        }
        return totalHandicap / Double(rounds.count)
    }
}

// MARK: - Full Game Sim Overview Cards
struct FullGameSimOverviewCards: View {
    @EnvironmentObject private var statsManager: UnifiedStatisticsManager

    private var totalSessions: Int {
        statsManager.fullGameSimSessions.filter { $0.isComplete }.count
    }

    var body: some View {
        HStack {
            VStack(spacing: 8) {
                Image(systemName: "figure.2.and.child.holdinghands")
                    .font(.title2)
                    .foregroundColor(.green)

                Text("\(totalSessions)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text("Total Sessions")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }
}

// MARK: - Baseball Kubb Overview Cards
struct BaseballKubbOverviewCards: View {
    @EnvironmentObject private var statsManager: UnifiedStatisticsManager

    private var totalSessions: Int {
        statsManager.baseballKubbSessions.filter { $0.isComplete }.count
    }

    var body: some View {
        HStack {
            VStack(spacing: 8) {
                Image(systemName: "baseball.fill")
                    .font(.title2)
                    .foregroundColor(.red)

                Text("\(totalSessions)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text("Total Sessions")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }
}

// MARK: - Training Overview Stats Section (OLD - KEEP FOR REFERENCE)
struct TrainingOverviewStatsSection_OLD: View {
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

                TrainingStatCard(
                    title: "Blast Efficiency",
                    value: String(format: "%.2f", stats.blastEfficiency),
                    icon: "bolt.fill",
                    color: .yellow,
                    description: "Average number of kubbs knocked down on the first throw of each round. Higher values indicate better blast efficiency."
                )
            }

            // Additional Metrics Row
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                // Calculate penalty rate from stats manager's data
                let penaltyRate = statsManager.inkastBlastSessions.isEmpty ? 0.0 :
                    Double(statsManager.inkastBlastSessions.reduce(0) { $0 + $1.totalPenaltyKubbs }) /
                    Double(statsManager.inkastBlastSessions.reduce(0) { $0 + $1.totalInkastKubbs })

                TrainingStatCard(
                    title: "Penalty Rate",
                    value: String(format: "%.1f%%", penaltyRate * 100),
                    icon: "exclamationmark.triangle.fill",
                    color: .red,
                    description: "Percentage of inkast kubbs that go out of bounds on both attempts, resulting in penalty kubbs. Lower is better."
                )

                let neighborRate = statsManager.inkastBlastSessions.isEmpty ? 0.0 :
                    Double(statsManager.inkastBlastSessions.reduce(0) { $0 + $1.totalNeighborKubbs }) /
                    Double(statsManager.inkastBlastSessions.reduce(0) { $0 + $1.totalInkastKubbs })

                TrainingStatCard(
                    title: "Neighbor Rate",
                    value: String(format: "%.1f%%", neighborRate * 100),
                    icon: "person.2.fill",
                    color: .purple,
                    description: "Percentage of inkast kubbs that land on top of another kubb (neighbors). Strategic neighbors can be advantageous."
                )

                let kubbsPerBaton = statsManager.inkastBlastSessions.isEmpty ? 0.0 :
                    Double(statsManager.inkastBlastSessions.reduce(0) { $0 + $1.totalKubbsKnockedDown }) /
                    Double(statsManager.inkastBlastSessions.reduce(0) { $0 + $1.totalBatonsUsed })

                TrainingStatCard(
                    title: "Kubbs per Baton",
                    value: String(format: "%.2f", kubbsPerBaton),
                    icon: "chart.bar.fill",
                    color: .green,
                    description: "Average number of kubbs knocked down per baton thrown. Higher efficiency means better accuracy and multi-kubb hits."
                )
            }
            .padding(.top, 8)
            
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

// MARK: - Full Game Sim Stats Section
struct FullGameSimStatsSection: View {
    @EnvironmentObject private var statsManager: UnifiedStatisticsManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Text("Full Game Sim Sessions")
                .font(.title2)
                .fontWeight(.bold)
            
            let sessions = statsManager.fullGameSimSessions.sorted { $0.date > $1.date }
            
            if sessions.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "crown")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    
                    Text("No Full Game Sim sessions yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Play a Full Game Sim session to see your statistics here!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                // Summary Stats Card
                VStack(alignment: .leading, spacing: 12) {
                    Text("Summary Statistics")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    // Top-level stats
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Sessions")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(sessions.count)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total Rounds")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(sessions.reduce(0) { $0 + $1.totalRounds })")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("8M Accuracy")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            let totalHits = sessions.reduce(0) { $0 + $1.totalEightMeterHits }
                            let totalBatons = sessions.reduce(0) { $0 + $1.totalEightMeterBatons }
                            let accuracy = totalBatons > 0 ? Double(totalHits) / Double(totalBatons) : 0.0
                            Text(String(format: "%.1f%%", accuracy * 100))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.purple)
                        }
                    }
                    
                    Divider()
                    
                    // Inkast & Blast stats from Full Game Sim
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Inkast Success")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            let totalInkast = sessions.reduce(0) { $0 + $1.totalInkastKubbs }
                            let penalties = sessions.reduce(0) { $0 + $1.totalPenaltyKubbs }
                            let successRate = totalInkast > 0 ? Double(totalInkast - penalties) / Double(totalInkast) : 0.0
                            Text(String(format: "%.1f%%", successRate * 100))
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.orange)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Kubbs Cleared")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(sessions.reduce(0) { $0 + $1.totalKubbsClearedFirstThrow })")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total Batons")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(sessions.reduce(0) { $0 + $1.totalBatonsUsed })")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Recent Sessions List
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Sessions")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    LazyVStack(spacing: 8) {
                        ForEach(sessions.prefix(10), id: \.id) { session in
                            FullGameSimSessionRow(session: session)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
}

// MARK: - Full Game Sim Session Row
struct FullGameSimSessionRow: View {
    let session: FullGameSimSessionStruct
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Session Info
                VStack(alignment: .leading, spacing: 4) {
                    Text("Full Game Sim")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Text(session.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Round count
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(session.totalRounds)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("rounds")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Stats row
            HStack(spacing: 16) {
                // Game Status
                HStack(spacing: 4) {
                    Image(systemName: session.outcome == "Victory" ? "checkmark.circle.fill" : 
                                     session.outcome == "In Progress" ? "clock.fill" : "xmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(session.outcome == "Victory" ? .green : 
                                       session.outcome == "In Progress" ? .orange : .red)
                    Text(session.outcome)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // 8-meter accuracy
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.right.circle")
                        .font(.caption)
                        .foregroundColor(.blue)
                    let accuracy = session.totalEightMeterBatons > 0 ? 
                        Double(session.totalEightMeterHits) / Double(session.totalEightMeterBatons) : 0.0
                    Text(String(format: "%.0f%%", accuracy * 100))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Handicap
                HStack(spacing: 4) {
                    Image(systemName: "target")
                        .font(.caption)
                        .foregroundColor(handicapColor(session.overallHandicap))
                    Text(formatHandicap(session.overallHandicap))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private func formatHandicap(_ handicap: Double) -> String {
        let sign = handicap >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", handicap))"
    }
    
    private func handicapColor(_ handicap: Double) -> Color {
        if handicap < -0.5 {
            return .green  // Under target = good
        } else if handicap > 0.5 {
            return .red    // Over target = bad
        } else {
            return .orange // Near target = ok
        }
    }
}

// MARK: - Personal Records Section

struct PersonalRecordsSection: View {
    @EnvironmentObject private var statsManager: UnifiedStatisticsManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Personal Records")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                RecordCard(
                    title: "Best Accuracy",
                    value: String(format: "%.1f%%", statsManager.personalRecords.bestAccuracyAllTime * 100),
                    icon: "target",
                    color: .green
                )

                RecordCard(
                    title: "Best Single Round",
                    value: String(format: "%.1f%%", statsManager.personalRecords.bestAccuracySingleRound * 100),
                    icon: "star.fill",
                    color: .yellow
                )

                RecordCard(
                    title: "Longest Hit Streak",
                    value: "\(statsManager.personalRecords.longestHitStreak)",
                    icon: "flame.fill",
                    color: .orange
                )

                RecordCard(
                    title: "Most Baseline Clears",
                    value: "\(statsManager.personalRecords.mostBaselineClears)",
                    icon: "checkmark.circle.fill",
                    color: .blue
                )

                RecordCard(
                    title: "Perfect Rounds",
                    value: "\(statsManager.personalRecords.perfectRoundsCount)",
                    icon: "sparkles",
                    color: .purple
                )

                RecordCard(
                    title: "Best King Accuracy",
                    value: String(format: "%.1f%%", statsManager.personalRecords.bestKingAccuracy * 100),
                    icon: "crown.fill",
                    color: .yellow
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct RecordCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Streaks Section

struct StreaksSection: View {
    @EnvironmentObject private var statsManager: UnifiedStatisticsManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Streaks")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            HStack(spacing: 16) {
                // Current Streak
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "flame")
                            .font(.title)
                            .foregroundColor(.orange)
                        Text("Current Streak")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }

                    Text("\(statsManager.personalRecords.currentHitStreak)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.orange)

                    Text("consecutive hits")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)

                // Best Streak
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "flame.fill")
                            .font(.title)
                            .foregroundColor(.red)
                        Text("Best Streak")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }

                    Text("\(statsManager.personalRecords.longestHitStreak)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.red)

                    Text("all-time best")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

// MARK: - Recent Performance Section

struct RecentPerformanceSection: View {
    @EnvironmentObject private var statsManager: UnifiedStatisticsManager

    var body: some View {
        if let recentForm = statsManager.recentFormStats {
            VStack(alignment: .leading, spacing: 16) {
                Text("Recent Performance")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                // Performance Summary Card
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Last 5 Sessions")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.1f%%", recentForm.recentAccuracy * 100))
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(colorForZone(recentForm.performanceZone))
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("vs Lifetime")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            HStack(spacing: 4) {
                                Text(recentForm.trendDirection.rawValue)
                                    .font(.title2)
                                Text(String(format: "%.1f%%", abs(recentForm.improvementPercentage)))
                                    .font(.headline)
                            }
                            .foregroundColor(colorForTrend(recentForm.trendDirection))
                        }
                    }

                    Divider()

                    // Performance Zone Badge
                    HStack {
                        Image(systemName: zoneIcon(recentForm.performanceZone))
                            .foregroundColor(colorForZone(recentForm.performanceZone))
                        Text(recentForm.performanceZone.rawValue)
                            .font(.headline)
                            .foregroundColor(colorForZone(recentForm.performanceZone))
                        Spacer()
                        Text(recentForm.performanceZone.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(colorForZone(recentForm.performanceZone).opacity(0.1))
                    .cornerRadius(8)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)

                // Recent Sessions List
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Sessions")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    ForEach(Array(recentForm.recentSessions.enumerated()), id: \.element.id) { index, session in
                        HStack {
                            Text("\(index + 1).")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 20)

                            Text(session.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.subheadline)
                                .foregroundColor(.primary)

                            Spacer()

                            Text(String(format: "%.1f%%", session.accuracy * 100))
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(session.accuracy >= recentForm.lifetimeAccuracy ? .green : .orange)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)
        }
    }

    private func colorForZone(_ zone: RecentFormStatistics.PerformanceZone) -> Color {
        switch zone {
        case .excellent: return .green
        case .good: return .blue
        case .average: return .orange
        case .needsWork: return .red
        }
    }

    private func colorForTrend(_ trend: RecentFormStatistics.TrendDirection) -> Color {
        switch trend {
        case .improving: return .green
        case .declining: return .red
        case .stable: return .orange
        }
    }

    private func zoneIcon(_ zone: RecentFormStatistics.PerformanceZone) -> String {
        switch zone {
        case .excellent: return "star.fill"
        case .good: return "checkmark.circle.fill"
        case .average: return "minus.circle.fill"
        case .needsWork: return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Clutch Performance Card

struct ClutchPerformanceCard: View {
    @EnvironmentObject private var statsManager: UnifiedStatisticsManager

    var body: some View {
        if let clutchMetrics = statsManager.clutchPerformanceMetrics {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "bolt.fill")
                        .font(.title2)
                        .foregroundColor(.yellow)
                    Text("Clutch Performance")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }

                VStack(spacing: 12) {
                    // Comparison bars
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Under Pressure")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.1f%%", clutchMetrics.clutchAccuracy * 100))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)

                            ProgressView(value: clutchMetrics.clutchAccuracy)
                                .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Normal")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.1f%%", clutchMetrics.normalAccuracy * 100))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)

                            ProgressView(value: clutchMetrics.normalAccuracy)
                                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Divider()

                    // Performance assessment
                    HStack {
                        Image(systemName: clutchMetrics.performanceRatio > 1.0 ? "arrow.up.circle.fill" : clutchMetrics.performanceRatio < 0.95 ? "arrow.down.circle.fill" : "minus.circle.fill")
                            .foregroundColor(clutchPerformanceColor(clutchMetrics.performanceRatio))
                        Text(clutchMetrics.description)
                            .font(.headline)
                            .foregroundColor(clutchPerformanceColor(clutchMetrics.performanceRatio))
                        Spacer()
                        Text("\(clutchMetrics.clutchAttempts) attempts")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(clutchPerformanceColor(clutchMetrics.performanceRatio).opacity(0.1))
                    .cornerRadius(8)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)
        }
    }

    private func clutchPerformanceColor(_ ratio: Double) -> Color {
        if ratio > 1.05 {
            return .green
        } else if ratio > 0.95 {
            return .blue
        } else {
            return .orange
        }
    }
}

// MARK: - Consistency Card

struct ConsistencyCard: View {
    @EnvironmentObject private var statsManager: UnifiedStatisticsManager

    var body: some View {
        if let consistency = statsManager.consistencyMetrics {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "waveform.path.ecg")
                        .font(.title2)
                        .foregroundColor(colorForRating(consistency.rating))
                    Text("Consistency")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }

                VStack(spacing: 12) {
                    // Rating and description
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(consistency.rating.rawValue)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(colorForRating(consistency.rating))
                            Spacer()
                            Text(String(format: "σ = %.3f", consistency.standardDeviation))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Text(consistency.rating.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(colorForRating(consistency.rating).opacity(0.1))
                    .cornerRadius(8)

                    Divider()

                    // Statistics
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Mean Accuracy")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.1f%%", consistency.meanAccuracy * 100))
                                .font(.headline)
                                .foregroundColor(.primary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Variance")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.1f%%", consistency.variancePercentage))
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)
        }
    }

    private func colorForRating(_ rating: ConsistencyMetrics.ConsistencyRating) -> Color {
        switch rating {
        case .veryStable: return .green
        case .stable: return .blue
        case .moderate: return .orange
        case .variable: return .yellow
        case .volatile: return .red
        }
    }
}


#Preview {
    StatsView()
}
