//
//  UnifiedStatisticsManager.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 1/15/25.
//

import Foundation
import Combine
import UIKit
import SwiftUI

@MainActor
class UnifiedStatisticsManager: ObservableObject {
    static let shared = UnifiedStatisticsManager()
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Session data from all modes
    @Published var practiceSessions: [PracticeSession] = []
    @Published var inkastBlastSessions: [InkastBlastSessionData] = []
    @Published var baseballKubbSessions: [BaseballKubbSession] = []
    
    // Statistics
    @Published var trainingStats: TrainingStatistics = TrainingStatistics(
        totalTrainingSessions: 0,
        maxTrainingStreak: 0,
        currentTrainingStreak: 0,
        totalEightMeterThrows: 0,
        eightMeterAccuracy: 0,
        totalInkastKubbs: 0,
        totalPenaltyKubbs: 0,
        totalNeighbors: 0,
        blastEfficiency: 0,
        fieldHandicap: 0
    )
    @Published var gameLogStats: GameLogStatistics = GameLogStatistics(
        totalGames: 0,
        competitiveGames: 0,
        wins: 0,
        losses: 0,
        ties: 0,
        winRate: 0
    )
    @Published var modeSpecificStats: ModeSpecificStatistics = ModeSpecificStatistics(
        practiceStats: PracticeStatistics(
            totalSessions: 0,
            totalBatonsThrown: 0,
            totalKubbsHit: 0,
            overallAccuracy: 0,
            accuracyTrend: []
        ),
        inkastBlastStats: InkastBlastStatistics(
            totalSessions: 0,
            totalRounds: 0,
            overallHandicap: 0,
            firstInkastRate: 0,
            blastEfficiency: 0,
            earlyGameHandicap: 0,
            earlyGameFirstInkastRate: 0,
            earlyGameBlastEfficiency: 0,
            midGameHandicap: 0,
            midGameFirstInkastRate: 0,
            midGameBlastEfficiency: 0,
            endGameHandicap: 0,
            endGameFirstInkastRate: 0,
            endGameBlastEfficiency: 0
        ),
        baseballKubbStats: BaseballKubbStatistics(
            totalGames: 0,
            completedGames: 0,
            averageGameLength: 0,
            scoringEfficiency: 0,
            totalRuns: 0,
            totalBatons: 0
        )
    )
    
    private let cloudKitManager = CloudKitManager.shared
    private let historyManager = HistoryManager()
    private var cancellables = Set<AnyCancellable>()
    
    // Cache management
    private var lastLoadTime: Date?
    private var isCurrentlyLoading = false
    private let cacheValidityDuration: TimeInterval = 30 // 30 seconds cache
    
    init() {
        // Listen for app becoming active to refresh data
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task {
                await self.loadAllSessionsIfNeeded()
            }
        }
        
        // Load data immediately and ensure it completes
        Task { @MainActor in
            await loadAllSessions()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Data Loading
    
    func loadAllSessions() async {
        // Prevent multiple simultaneous loads
        guard !isCurrentlyLoading else {
            print("📊 Stats loading already in progress, skipping...")
            return
        }
        
        // Check cache validity - but only if we already have data loaded
        // Reduced cache duration to 5 seconds to be more responsive
        if let lastLoad = lastLoadTime,
           Date().timeIntervalSince(lastLoad) < 5.0,
           !practiceSessions.isEmpty {
            print("📊 Using cached stats data (age: \(Int(Date().timeIntervalSince(lastLoad)))s)")
            return
        }
        
        isCurrentlyLoading = true
        isLoading = true
        errorMessage = nil
        
        print("📊 Loading stats data from CloudKit...")
        
        do {
            // Load practice sessions (8M training)
            print("📊 Loading practice sessions...")
            await historyManager.loadSessions()
            practiceSessions = historyManager.sessions
            print("📊 Loaded \(practiceSessions.count) practice sessions")
            
            // Load Inkast & Blast sessions
            print("📊 Loading Inkast & Blast sessions...")
            inkastBlastSessions = await cloudKitManager.fetchInkastBlastSessions()
            print("📊 Loaded \(inkastBlastSessions.count) Inkast & Blast sessions")
            
            // Load Baseball Kubb sessions
            print("📊 Loading Baseball Kubb sessions...")
            baseballKubbSessions = try await cloudKitManager.fetchBaseballKubbSessions()
            print("📊 Loaded \(baseballKubbSessions.count) Baseball Kubb sessions")
            
            // Calculate statistics
            print("📊 Calculating statistics...")
            calculateTrainingStatistics()
            calculateGameLogStatistics()
            calculateModeSpecificStatistics()
            
            // Update cache timestamp
            lastLoadTime = Date()
            print("✅ Stats data loaded and cached successfully - Total sessions: \(practiceSessions.count + inkastBlastSessions.count + baseballKubbSessions.count)")
            
            isLoading = false
            isCurrentlyLoading = false
        } catch {
            print("❌ Error loading stats data: \(error)")
            errorMessage = cloudKitManager.handleCloudKitError(error)
            isLoading = false
            isCurrentlyLoading = false
        }
    }
    
    func refreshAllSessions() async {
        // Force refresh by clearing cache
        lastLoadTime = nil
        await loadAllSessions()
    }
    
    func invalidateCache() {
        lastLoadTime = nil
        print("📊 Stats cache invalidated")
    }
    
    func loadAllSessionsIfNeeded() async {
        // If we have no data or cache is stale, load fresh data
        if practiceSessions.isEmpty || 
           (lastLoadTime != nil && Date().timeIntervalSince(lastLoadTime!) > 5.0) {
            await loadAllSessions()
        }
    }
    
    func forceReload() async {
        print("📊 Force reloading all stats data...")
        lastLoadTime = nil
        isCurrentlyLoading = false
        await loadAllSessions()
    }
    
    func debugDataStatus() {
        print("📊 Debug - Data Status:")
        print("   - Practice Sessions: \(practiceSessions.count)")
        print("   - Inkast Blast Sessions: \(inkastBlastSessions.count)")
        print("   - Baseball Kubb Sessions: \(baseballKubbSessions.count)")
        print("   - Last Load Time: \(lastLoadTime?.description ?? "Never")")
        print("   - Is Currently Loading: \(isCurrentlyLoading)")
        
        if !practiceSessions.isEmpty {
            print("   - First Practice Session: \(practiceSessions.first?.id ?? "Unknown")")
            print("   - Last Practice Session: \(practiceSessions.last?.id ?? "Unknown")")
        }
    }
    
    // MARK: - Round-by-Round Data
    
    func getRoundByRoundAccuracyData() -> [RoundAccuracyDataPoint] {
        var dataPoints: [RoundAccuracyDataPoint] = []
        var globalRoundNumber = 1
        
        // Sort sessions by date to maintain chronological order and filter out sessions with 0 batons
        let sortedSessions = practiceSessions
            .filter { $0.totalBatons > 0 } // Filter out sessions with 0 batons thrown
            .sorted { $0.startTime < $1.startTime }
        
        for session in sortedSessions {
            let sessionRounds = session.rounds.sorted { $0.roundNumber < $1.roundNumber }
            
            for round in sessionRounds {
                dataPoints.append(RoundAccuracyDataPoint(
                    globalRoundNumber: globalRoundNumber,
                    sessionId: session.id,
                    sessionDate: session.date,
                    roundNumber: round.roundNumber,
                    accuracy: round.accuracy,
                    sessionTarget: session.target
                ))
                globalRoundNumber += 1
            }
        }
        
        return dataPoints
    }
    
    func getSessionsForTrellis() -> [SessionTrellisData] {
        let sortedSessions = practiceSessions
            .filter { $0.totalBatons > 0 } // Filter out sessions with 0 batons thrown
            .sorted { $0.startTime < $1.startTime }
        
        return sortedSessions.map { session in
            let sessionRounds = session.rounds.sorted { $0.roundNumber < $1.roundNumber }
            let roundData = sessionRounds.map { round in
                RoundAccuracyDataPoint(
                    globalRoundNumber: 0, // Will be set by the chart
                    sessionId: session.id,
                    sessionDate: session.date,
                    roundNumber: round.roundNumber,
                    accuracy: round.accuracy,
                    sessionTarget: session.target
                )
            }
            
            return SessionTrellisData(
                id: session.id,
                sessionId: session.id,
                sessionDate: session.date,
                rounds: roundData
            )
        }
    }
    
    // MARK: - Training Statistics Calculation
    
    private func calculateTrainingStatistics() {
        let newStats = TrainingStatistics(
            totalTrainingSessions: practiceSessions.count + inkastBlastSessions.count,
            maxTrainingStreak: calculateMaxTrainingStreak(),
            currentTrainingStreak: calculateCurrentTrainingStreak(),
            totalEightMeterThrows: calculateTotalEightMeterThrows(),
            eightMeterAccuracy: calculateEightMeterAccuracy(),
            totalInkastKubbs: calculateTotalInkastKubbs(),
            totalPenaltyKubbs: calculateTotalPenaltyKubbs(),
            totalNeighbors: calculateTotalNeighbors(),
            blastEfficiency: calculateBlastEfficiency(),
            fieldHandicap: calculateFieldHandicap()
        )
        
        DispatchQueue.main.async {
            self.trainingStats = newStats
        }
    }
    
    // MARK: - Game Log Statistics Calculation
    
    private func calculateGameLogStatistics() {
        let competitiveGames = baseballKubbSessions.filter { $0.userTeam != .none && $0.userTeam != .both }
        let wins = competitiveGames.filter { game in
            let opponentScore = game.userTeam == .away ? game.homeScore : game.awayScore
            return game.userScore > opponentScore
        }.count
        let losses = competitiveGames.filter { game in
            let opponentScore = game.userTeam == .away ? game.homeScore : game.awayScore
            return game.userScore < opponentScore
        }.count
        let ties = competitiveGames.filter { game in
            let opponentScore = game.userTeam == .away ? game.homeScore : game.awayScore
            return game.userScore == opponentScore
        }.count
        let winRate = competitiveGames.count > 0 ? Double(wins) / Double(competitiveGames.count) : 0.0
        
        let newStats = GameLogStatistics(
            totalGames: baseballKubbSessions.count,
            competitiveGames: competitiveGames.count,
            wins: wins,
            losses: losses,
            ties: ties,
            winRate: winRate
        )
        
        DispatchQueue.main.async {
            self.gameLogStats = newStats
        }
    }
    
    // MARK: - Training Statistics Helper Methods
    
    private func calculateMaxTrainingStreak() -> Int {
        let allSessions = (practiceSessions + inkastBlastSessions.map { $0.toPracticeSession() })
            .sorted { $0.startTime < $1.startTime }
        
        var maxStreak = 0
        var currentStreak = 0
        var lastDate: Date?
        
        for session in allSessions {
            let sessionDate = Calendar.current.startOfDay(for: session.startTime)
            
            if let last = lastDate {
                let daysBetween = Calendar.current.dateComponents([.day], from: last, to: sessionDate).day ?? 0
                
                if daysBetween == 1 {
                    currentStreak += 1
                } else if daysBetween > 1 {
                    maxStreak = max(maxStreak, currentStreak)
                    currentStreak = 1
                }
                // If daysBetween == 0, it's the same day, so don't increment
            } else {
                currentStreak = 1
            }
            
            lastDate = sessionDate
        }
        
        return max(maxStreak, currentStreak)
    }
    
    private func calculateCurrentTrainingStreak() -> Int {
        let allSessions = (practiceSessions + inkastBlastSessions.map { $0.toPracticeSession() })
            .sorted { $0.startTime > $1.startTime } // Most recent first
        
        var currentStreak = 0
        var lastDate: Date?
        let today = Calendar.current.startOfDay(for: Date())
        
        for session in allSessions {
            let sessionDate = Calendar.current.startOfDay(for: session.startTime)
            
            if let last = lastDate {
                let daysBetween = Calendar.current.dateComponents([.day], from: sessionDate, to: last).day ?? 0
                
                if daysBetween == 1 {
                    currentStreak += 1
                } else if daysBetween > 1 {
                    break
                }
            } else {
                // Check if this is today or yesterday
                let daysFromToday = Calendar.current.dateComponents([.day], from: sessionDate, to: today).day ?? 0
                if daysFromToday <= 1 {
                    currentStreak = 1
                } else {
                    break
                }
            }
            
            lastDate = sessionDate
        }
        
        return currentStreak
    }
    
    private func calculateTotalEightMeterThrows() -> Int {
        return practiceSessions.reduce(0) { $0 + $1.totalBatons }
    }
    
    private func calculateEightMeterAccuracy() -> Double {
        let totalKubbs = practiceSessions.reduce(0) { $0 + $1.totalKubbs }
        let totalBatons = calculateTotalEightMeterThrows()
        
        guard totalBatons > 0 else { return 0.0 }
        return Double(totalKubbs) / Double(totalBatons)
    }
    
    private func calculateTotalInkastKubbs() -> Int {
        return inkastBlastSessions.reduce(0) { $0 + $1.totalKubbsKnockedDown }
    }
    
    private func calculateTotalPenaltyKubbs() -> Int {
        return inkastBlastSessions.reduce(0) { $0 + $1.totalPenaltyKubbsCount }
    }
    
    private func calculateTotalNeighbors() -> Int {
        return inkastBlastSessions.reduce(0) { $0 + $1.totalNeighbors }
    }
    
    private func calculateBlastEfficiency() -> Double {
        var totalFirstThrowKubbs = 0
        var totalFirstThrows = 0
        
        for session in inkastBlastSessions {
            for round in session.rounds {
                if round.batonThrows.count > 0 {
                    totalFirstThrows += 1
                    if let firstThrow = round.batonThrows.first, firstThrow.isHit {
                        totalFirstThrowKubbs += firstThrow.kubbsHit
                    }
                }
            }
        }
        
        guard totalFirstThrows > 0 else { return 0.0 }
        return Double(totalFirstThrowKubbs) / Double(totalFirstThrows)
    }
    
    private func calculateFieldHandicap() -> Double {
        var totalHandicap = 0.0
        var totalRounds = 0
        
        for session in inkastBlastSessions {
            for round in session.rounds {
                let target = round.targetBatons
                let actual = round.batonsUsed
                let handicap = actual - target
                
                totalHandicap += Double(handicap)
                totalRounds += 1
            }
        }
        
        guard totalRounds > 0 else { return 0.0 }
        return totalHandicap / Double(totalRounds)
    }
    
    // MARK: - Mode Specific Statistics Calculation
    
    private func calculateModeSpecificStatistics() {
        let newStats = ModeSpecificStatistics(
            practiceStats: calculatePracticeStats(),
            inkastBlastStats: calculateInkastBlastStats(),
            baseballKubbStats: calculateBaseballKubbStats()
        )
        
        DispatchQueue.main.async {
            self.modeSpecificStats = newStats
        }
    }
    
    private func calculatePracticeStats() -> PracticeStatistics {
        let totalSessions = practiceSessions.count
        let totalBatonsThrown = practiceSessions.reduce(0) { $0 + $1.totalBatons }
        let totalKubbsHit = practiceSessions.reduce(0) { $0 + $1.totalKubbs }
        let overallAccuracy = totalBatonsThrown > 0 ? Double(totalKubbsHit) / Double(totalBatonsThrown) : 0.0
        let accuracyTrend = practiceSessions.sorted { $0.startTime < $1.startTime }.map { $0.accuracy }
        
        return PracticeStatistics(
            totalSessions: totalSessions,
            totalBatonsThrown: totalBatonsThrown,
            totalKubbsHit: totalKubbsHit,
            overallAccuracy: overallAccuracy,
            accuracyTrend: accuracyTrend
        )
    }
    
    private func calculateInkastBlastStats() -> InkastBlastStatistics {
        let totalSessions = inkastBlastSessions.count
        let totalRounds = inkastBlastSessions.reduce(0) { $0 + $1.rounds.count }
        let overallHandicap = calculateFieldHandicap()
        let firstInkastRate = calculateFirstInkastRate()
        let blastEfficiency = calculateBlastEfficiency()
        
        // Phase-specific calculations
        let earlyGameStats = calculatePhaseStats(.early)
        let midGameStats = calculatePhaseStats(.mid)
        let endGameStats = calculatePhaseStats(.end)
        
        return InkastBlastStatistics(
            totalSessions: totalSessions,
            totalRounds: totalRounds,
            overallHandicap: overallHandicap,
            firstInkastRate: firstInkastRate,
            blastEfficiency: blastEfficiency,
            earlyGameHandicap: earlyGameStats.handicap,
            earlyGameFirstInkastRate: earlyGameStats.firstInkastRate,
            earlyGameBlastEfficiency: earlyGameStats.blastEfficiency,
            midGameHandicap: midGameStats.handicap,
            midGameFirstInkastRate: midGameStats.firstInkastRate,
            midGameBlastEfficiency: midGameStats.blastEfficiency,
            endGameHandicap: endGameStats.handicap,
            endGameFirstInkastRate: endGameStats.firstInkastRate,
            endGameBlastEfficiency: endGameStats.blastEfficiency
        )
    }
    
    private func calculateFirstInkastRate() -> Double {
        var totalInkastAttempts = 0
        var successfulInkasts = 0
        
        for session in inkastBlastSessions {
            for round in session.rounds {
                totalInkastAttempts += round.kubbsInkast
                successfulInkasts += round.kubbsInkast - round.kubbsOutOfBounds
            }
        }
        
        guard totalInkastAttempts > 0 else { return 0.0 }
        return Double(successfulInkasts) / Double(totalInkastAttempts)
    }
    
    private func calculatePhaseStats(_ phase: GamePhase) -> (handicap: Double, firstInkastRate: Double, blastEfficiency: Double) {
        let phaseSessions = inkastBlastSessions.filter { $0.gamePhase == phase }
        
        var totalHandicap = 0.0
        var totalRounds = 0
        var totalInkastAttempts = 0
        var successfulInkasts = 0
        var totalFirstThrowKubbs = 0
        var totalFirstThrows = 0
        
        for session in phaseSessions {
            for round in session.rounds {
                // Handicap calculation
                let target = round.targetBatons
                let actual = round.batonsUsed
                totalHandicap += Double(actual - target)
                totalRounds += 1
                
                // First inkast rate
                totalInkastAttempts += round.kubbsInkast
                successfulInkasts += round.kubbsInkast - round.kubbsOutOfBounds
                
                // Blast efficiency
                if round.batonThrows.count > 0 {
                    totalFirstThrows += 1
                    if let firstThrow = round.batonThrows.first, firstThrow.isHit {
                        totalFirstThrowKubbs += firstThrow.kubbsHit
                    }
                }
            }
        }
        
        let handicap = totalRounds > 0 ? totalHandicap / Double(totalRounds) : 0.0
        let firstInkastRate = totalInkastAttempts > 0 ? Double(successfulInkasts) / Double(totalInkastAttempts) : 0.0
        let blastEfficiency = totalFirstThrows > 0 ? Double(totalFirstThrowKubbs) / Double(totalFirstThrows) : 0.0
        
        return (handicap, firstInkastRate, blastEfficiency)
    }
    
    // MARK: - Helper Methods for UI
    
    func getAvailablePracticeDates() -> [Date] {
        let calendar = Calendar.current
        let uniqueDates = Set(practiceSessions.map { calendar.startOfDay(for: $0.startTime) })
        return Array(uniqueDates).sorted { $0 > $1 }
    }
    
    func getRoundAccuracyForDate(_ date: Date) -> [Double] {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)
        
        let sessionsOnDate = practiceSessions.filter { session in
            calendar.startOfDay(for: session.startTime) == targetDate
        }
        
        var allRounds: [Double] = []
        for session in sessionsOnDate.sorted(by: { $0.startTime < $1.startTime }) {
            // For practice sessions, we'll use the overall accuracy per session
            // In a real implementation, you'd want to track round-by-round data
            allRounds.append(session.accuracy)
        }
        
        return allRounds
    }
    
    private func calculateBaseballKubbStats() -> BaseballKubbStatistics {
        let userGames = baseballKubbSessions.filter { $0.userTeam != .none }
        let totalGames = userGames.count
        let completedGames = userGames.filter { $0.isComplete }.count
        let averageGameLength = userGames.reduce(0.0) { $0 + Double($1.currentInning) } / Double(max(totalGames, 1))
        let totalRuns = userGames.reduce(0) { $0 + $1.userScore }
        let totalBatons = userGames.reduce(0) { $0 + $1.batonCount }
        let scoringEfficiency = totalBatons > 0 ? (Double(totalRuns) / Double(totalBatons)).isNaN ? 0.0 : Double(totalRuns) / Double(totalBatons) : 0.0
        
        return BaseballKubbStatistics(
            totalGames: totalGames,
            completedGames: completedGames,
            averageGameLength: averageGameLength,
            scoringEfficiency: scoringEfficiency,
            totalRuns: totalRuns,
            totalBatons: totalBatons
        )
    }
}

// MARK: - Data Structures

struct TrainingStatistics {
    let totalTrainingSessions: Int
    let maxTrainingStreak: Int
    let currentTrainingStreak: Int
    let totalEightMeterThrows: Int
    let eightMeterAccuracy: Double
    let totalInkastKubbs: Int
    let totalPenaltyKubbs: Int
    let totalNeighbors: Int
    let blastEfficiency: Double
    let fieldHandicap: Double
}

struct GameLogStatistics {
    let totalGames: Int
    let competitiveGames: Int
    let wins: Int
    let losses: Int
    let ties: Int
    let winRate: Double
}

struct ModeSpecificStatistics {
    let practiceStats: PracticeStatistics
    let inkastBlastStats: InkastBlastStatistics
    let baseballKubbStats: BaseballKubbStatistics
}

struct PracticeStatistics {
    let totalSessions: Int
    let totalBatonsThrown: Int
    let totalKubbsHit: Int
    let overallAccuracy: Double
    let accuracyTrend: [Double]
}

struct InkastBlastStatistics {
    let totalSessions: Int
    let totalRounds: Int
    let overallHandicap: Double
    let firstInkastRate: Double
    let blastEfficiency: Double
    let earlyGameHandicap: Double
    let earlyGameFirstInkastRate: Double
    let earlyGameBlastEfficiency: Double
    let midGameHandicap: Double
    let midGameFirstInkastRate: Double
    let midGameBlastEfficiency: Double
    let endGameHandicap: Double
    let endGameFirstInkastRate: Double
    let endGameBlastEfficiency: Double
}

struct BaseballKubbStatistics {
    let totalGames: Int
    let completedGames: Int
    let averageGameLength: Double
    let scoringEfficiency: Double
    let totalRuns: Int
    let totalBatons: Int
}

// MARK: - Round-by-Round Data Structures

struct RoundAccuracyDataPoint: Identifiable {
    let id = UUID()
    let globalRoundNumber: Int
    let sessionId: String
    let sessionDate: Date
    let roundNumber: Int
    let accuracy: Double
    let sessionTarget: Int
}

struct TrendPoint: Identifiable {
    let id = UUID()
    let x: Double
    let y: Double
    let roundNumber: Int
}

struct PerformanceZone: Identifiable {
    let id = UUID()
    let startRound: Int
    let endRound: Int
    let upperBound: Double
    let lowerBound: Double
    let color: Color
}

struct SessionTrellisData: Identifiable {
    let id: String
    let sessionId: String
    let sessionDate: Date
    let rounds: [RoundAccuracyDataPoint]
}
