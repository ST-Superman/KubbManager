//
//  PersonalRecords.swift
//  Kubb Manager
//
//  Created for enhanced statistics tracking
//

import Foundation

// MARK: - Personal Records Model
// Tracks all-time best performances across different metrics

struct PersonalRecords: Codable, Equatable {
    // MARK: - Accuracy Records
    var bestAccuracyAllTime: Double
    var bestAccuracySingleRound: Double
    var sessionIdForBestAccuracy: String?
    var dateOfBestAccuracy: Date?
    var roundNumberForBestRound: Int?

    // MARK: - Streak Records
    var longestHitStreak: Int           // Longest consecutive successful throws
    var currentHitStreak: Int           // Current active hit streak
    var dateOfLongestStreak: Date?
    var sessionIdForLongestStreak: String?

    // MARK: - Performance Records
    var mostBaselineClears: Int         // Most clears in a single session
    var sessionIdForMostClears: String?
    var dateOfMostClears: Date?

    var perfectRoundsCount: Int         // Total count of perfect (100%) rounds

    var bestKingAccuracy: Double        // Best king throwing accuracy
    var sessionIdForBestKingAccuracy: String?

    // MARK: - Session Records
    var mostBatonsInSession: Int
    var mostKubbsInSession: Int
    var sessionIdForMostBatons: String?

    // MARK: - Inkast & Blast Records
    var bestInkastSuccessRate: Double   // Best first inkast success rate
    var lowestHandicap: Double          // Best (lowest) handicap score
    var sessionIdForBestInkast: String?
    var sessionIdForLowestHandicap: String?

    // MARK: - Initialization

    init() {
        // Initialize with zero/empty values
        self.bestAccuracyAllTime = 0.0
        self.bestAccuracySingleRound = 0.0
        self.sessionIdForBestAccuracy = nil
        self.dateOfBestAccuracy = nil
        self.roundNumberForBestRound = nil

        self.longestHitStreak = 0
        self.currentHitStreak = 0
        self.dateOfLongestStreak = nil
        self.sessionIdForLongestStreak = nil

        self.mostBaselineClears = 0
        self.sessionIdForMostClears = nil
        self.dateOfMostClears = nil

        self.perfectRoundsCount = 0

        self.bestKingAccuracy = 0.0
        self.sessionIdForBestKingAccuracy = nil

        self.mostBatonsInSession = 0
        self.mostKubbsInSession = 0
        self.sessionIdForMostBatons = nil

        self.bestInkastSuccessRate = 0.0
        self.lowestHandicap = Double.infinity
        self.sessionIdForBestInkast = nil
        self.sessionIdForLowestHandicap = nil
    }

    // MARK: - Record Update Methods

    /// Updates records based on a completed practice session
    mutating func updateWithPracticeSession(_ session: PracticeSession) {
        // Update accuracy records
        if session.accuracy > bestAccuracyAllTime {
            bestAccuracyAllTime = session.accuracy
            sessionIdForBestAccuracy = session.id
            dateOfBestAccuracy = session.date
        }

        // Check for best single round accuracy
        for round in session.rounds where round.isComplete {
            if round.accuracy > bestAccuracySingleRound {
                bestAccuracySingleRound = round.accuracy
                roundNumberForBestRound = round.roundNumber
                sessionIdForBestAccuracy = session.id
            }

            // Count perfect rounds
            if round.accuracy == 1.0 {
                perfectRoundsCount += 1
            }
        }

        // Update baseline clears
        let clears = session.totalBaselineClears
        if clears > mostBaselineClears {
            mostBaselineClears = clears
            sessionIdForMostClears = session.id
            dateOfMostClears = session.date
        }

        // Update king accuracy
        if session.totalKingThrowAttempts > 0 && session.kingAccuracy > bestKingAccuracy {
            bestKingAccuracy = session.kingAccuracy
            sessionIdForBestKingAccuracy = session.id
        }

        // Update session volume records
        if session.totalBatons > mostBatonsInSession {
            mostBatonsInSession = session.totalBatons
            sessionIdForMostBatons = session.id
        }

        if session.totalKubbs > mostKubbsInSession {
            mostKubbsInSession = session.totalKubbs
        }
    }

    /// Updates records based on an Inkast & Blast session
    mutating func updateWithInkastBlastSession(_ session: InkastBlastSessionData) {
        // Calculate first inkast success rate for this session
        let totalInkastAttempts = session.totalInkastKubbs
        let successfulInkasts = totalInkastAttempts - session.totalPenaltyKubbs

        if totalInkastAttempts > 0 {
            let successRate = Double(successfulInkasts) / Double(totalInkastAttempts)
            if successRate > bestInkastSuccessRate {
                bestInkastSuccessRate = successRate
                sessionIdForBestInkast = session.id
            }
        }

        // Calculate handicap for this session
        if session.totalRounds > 0 {
            var totalHandicap = 0.0
            for round in session.rounds {
                let target = round.targetBatons
                let actual = round.batonsUsed
                totalHandicap += Double(actual - target)
            }
            let avgHandicap = totalHandicap / Double(session.totalRounds)

            if avgHandicap < lowestHandicap {
                lowestHandicap = avgHandicap
                sessionIdForLowestHandicap = session.id
            }
        }
    }

    /// Updates the current hit streak
    mutating func updateCurrentStreak(_ streak: Int, sessionId: String? = nil) {
        currentHitStreak = streak

        if streak > longestHitStreak {
            longestHitStreak = streak
            dateOfLongestStreak = Date()
            sessionIdForLongestStreak = sessionId
        }
    }

    /// Resets current streak (e.g., when a throw is missed)
    mutating func resetCurrentStreak() {
        currentHitStreak = 0
    }
}

// MARK: - Recent Form Statistics

struct RecentFormStatistics: Equatable {
    let recentSessions: [SessionSummary]
    let recentAccuracy: Double
    let lifetimeAccuracy: Double
    let improvementPercentage: Double
    let trendDirection: TrendDirection
    let performanceZone: PerformanceZone

    // Simplified session summary for recent form
    struct SessionSummary: Equatable {
        let id: String
        let date: Date
        let accuracy: Double
        let totalBatons: Int
        let totalKubbs: Int
    }

    enum TrendDirection: String, Codable {
        case improving = "↑"
        case declining = "↓"
        case stable = "→"

        var description: String {
            switch self {
            case .improving: return "Improving"
            case .declining: return "Declining"
            case .stable: return "Stable"
            }
        }

        var color: String {
            switch self {
            case .improving: return "green"
            case .declining: return "red"
            case .stable: return "orange"
            }
        }
    }

    enum PerformanceZone: String, Codable {
        case excellent = "Excellent"
        case good = "Good"
        case average = "Average"
        case needsWork = "Needs Work"

        var color: String {
            switch self {
            case .excellent: return "green"
            case .good: return "blue"
            case .average: return "orange"
            case .needsWork: return "red"
            }
        }

        var description: String {
            switch self {
            case .excellent: return "80%+ accuracy"
            case .good: return "70-80% accuracy"
            case .average: return "60-70% accuracy"
            case .needsWork: return "Below 60%"
            }
        }
    }

    init(recentSessions: [SessionSummary],
         recentAccuracy: Double,
         lifetimeAccuracy: Double) {
        self.recentSessions = recentSessions
        self.recentAccuracy = recentAccuracy
        self.lifetimeAccuracy = lifetimeAccuracy

        // Calculate improvement percentage
        if lifetimeAccuracy > 0 {
            self.improvementPercentage = ((recentAccuracy - lifetimeAccuracy) / lifetimeAccuracy) * 100
        } else {
            self.improvementPercentage = 0
        }

        // Determine trend direction
        let difference = recentAccuracy - lifetimeAccuracy
        if abs(difference) < 0.02 { // Within 2% is considered stable
            self.trendDirection = .stable
        } else if difference > 0 {
            self.trendDirection = .improving
        } else {
            self.trendDirection = .declining
        }

        // Determine performance zone
        if recentAccuracy >= 0.80 {
            self.performanceZone = .excellent
        } else if recentAccuracy >= 0.70 {
            self.performanceZone = .good
        } else if recentAccuracy >= 0.60 {
            self.performanceZone = .average
        } else {
            self.performanceZone = .needsWork
        }
    }
}

// MARK: - Consistency Metrics

struct ConsistencyMetrics: Equatable {
    let standardDeviation: Double
    let rating: ConsistencyRating
    let meanAccuracy: Double
    let variancePercentage: Double

    enum ConsistencyRating: String, Codable {
        case veryStable = "Very Stable"
        case stable = "Stable"
        case moderate = "Moderate"
        case variable = "Variable"
        case volatile = "Volatile"

        var color: String {
            switch self {
            case .veryStable: return "green"
            case .stable: return "blue"
            case .moderate: return "orange"
            case .variable: return "yellow"
            case .volatile: return "red"
            }
        }

        var description: String {
            switch self {
            case .veryStable: return "Highly consistent performance"
            case .stable: return "Consistent performance"
            case .moderate: return "Some variation in performance"
            case .variable: return "Noticeable performance swings"
            case .volatile: return "Highly inconsistent performance"
            }
        }
    }

    init(accuracies: [Double]) {
        guard !accuracies.isEmpty else {
            self.standardDeviation = 0
            self.rating = .stable
            self.meanAccuracy = 0
            self.variancePercentage = 0
            return
        }

        // Calculate mean
        let mean = accuracies.reduce(0, +) / Double(accuracies.count)
        self.meanAccuracy = mean

        // Calculate variance
        let variance = accuracies.map { pow($0 - mean, 2) }.reduce(0, +) / Double(accuracies.count)

        // Calculate standard deviation
        self.standardDeviation = sqrt(variance)

        // Calculate variance as percentage of mean
        self.variancePercentage = mean > 0 ? (standardDeviation / mean) * 100 : 0

        // Determine rating based on coefficient of variation (CV)
        let cv = variancePercentage
        if cv < 5 {
            self.rating = .veryStable
        } else if cv < 10 {
            self.rating = .stable
        } else if cv < 15 {
            self.rating = .moderate
        } else if cv < 20 {
            self.rating = .variable
        } else {
            self.rating = .volatile
        }
    }
}

// MARK: - Clutch Performance Metrics

struct ClutchPerformanceMetrics: Equatable {
    let clutchAccuracy: Double          // Accuracy when 3-4 kubbs remain
    let normalAccuracy: Double          // Accuracy in non-pressure situations
    let clutchAttempts: Int            // Total clutch throws attempted
    let performanceRatio: Double        // Clutch / Normal (>1.0 means better under pressure)

    var description: String {
        if performanceRatio > 1.05 {
            return "Thrives under pressure"
        } else if performanceRatio > 0.95 {
            return "Consistent under pressure"
        } else {
            return "Struggles under pressure"
        }
    }

    var color: String {
        if performanceRatio > 1.05 {
            return "green"
        } else if performanceRatio > 0.95 {
            return "blue"
        } else {
            return "orange"
        }
    }
}
