//
//  UnifiedSessionDetailView.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 1/15/25.
//

import SwiftUI

struct UnifiedSessionDetailView: View {
    let session: UnifiedSession
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    UnifiedSessionHeaderView(session: session)
                    
                    // Content based on session type
                    switch session {
                    case .practice(let practiceSession):
                        PracticeSessionDetailView(session: practiceSession)
                    case .inkastBlast(let inkastBlastSession):
                        InkastBlastSessionDetailView(session: inkastBlastSession)
                    case .baseballKubb(let baseballKubbSession):
                        BaseballKubbSessionDetailView(session: baseballKubbSession)
                    }
                }
                .padding()
            }
            .navigationTitle("Session Details")
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

struct UnifiedSessionHeaderView: View {
    let session: UnifiedSession
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: session.sessionType.icon)
                    .font(.title2)
                    .foregroundColor(session.sessionType.color)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(session.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(session.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let duration = session.duration {
                        Text(formatDuration(duration))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            HStack(spacing: 20) {
                VStack {
                    Text(session.primaryStat)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(session.sessionType.color)
                    Text("Primary")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text(session.secondaryStat)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Text("Secondary")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let accuracy = session.accuracy {
                    VStack {
                        Text(String(format: "%.1f%%", accuracy * 100))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(accuracyColor(accuracy))
                        Text("Accuracy")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration.truncatingRemainder(dividingBy: 3600)) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func accuracyColor(_ accuracy: Double) -> Color {
        if accuracy >= 0.7 {
            return .green
        } else if accuracy >= 0.5 {
            return .orange
        } else {
            return .red
        }
    }
}

struct PracticeSessionDetailView: View {
    let session: PracticeSession
    
    var body: some View {
        VStack(spacing: 16) {
            // Session Overview
            VStack(alignment: .leading, spacing: 12) {
                Text("Session Overview")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    DetailStatCard(
                        title: "Target",
                        value: "\(session.target)",
                        icon: "target",
                        color: .blue
                    )
                    
                    DetailStatCard(
                        title: "Kubbs Hit",
                        value: "\(session.totalKubbs)",
                        icon: "checkmark.circle",
                        color: .green
                    )
                    
                    DetailStatCard(
                        title: "Accuracy",
                        value: String(format: "%.1f%%", session.accuracy * 100),
                        icon: "scope",
                        color: .orange
                    )
                    
                    DetailStatCard(
                        title: "Baseline Clears",
                        value: "\(session.totalBaselineClears)",
                        icon: "crown.fill",
                        color: .purple
                    )
                    
                    DetailStatCard(
                        title: "King Throws",
                        value: "\(session.totalKingThrows)",
                        icon: "star.fill",
                        color: .yellow
                    )
                    
                    DetailStatCard(
                        title: "King Accuracy",
                        value: String(format: "%.1f%%", session.kingAccuracy * 100),
                        icon: "star",
                        color: .red
                    )
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Rounds Detail
            if !session.rounds.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Round Details")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    ForEach(Array(session.rounds.enumerated()), id: \.offset) { index, round in
                        UnifiedRoundDetailRow(round: round, roundNumber: index + 1)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
    }
}

struct InkastBlastSessionDetailView: View {
    let session: InkastBlastSessionData
    
    var body: some View {
        VStack(spacing: 16) {
            // Session Overview
            VStack(alignment: .leading, spacing: 12) {
                Text("Session Overview")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    DetailStatCard(
                        title: "Rounds",
                        value: "\(session.totalRounds)",
                        icon: "repeat",
                        color: .blue
                    )
                    
                    DetailStatCard(
                        title: "Kubbs Hit",
                        value: "\(session.totalInkastKubbs)",
                        icon: "checkmark.circle",
                        color: .green
                    )
                    
                    DetailStatCard(
                        title: "Batons Used",
                        value: "\(session.totalBatonsUsed)",
                        icon: "arrow.right.circle",
                        color: .orange
                    )
                    
                    DetailStatCard(
                        title: "First Throw Success",
                        value: "\(session.totalKubbsClearedFirstThrow)",
                        icon: "bolt.fill",
                        color: .yellow
                    )
                    
                    DetailStatCard(
                        title: "Penalty Kubbs",
                        value: "\(session.totalPenaltyKubbs)",
                        icon: "exclamationmark.triangle",
                        color: .red
                    )
                    
                    DetailStatCard(
                        title: "Neighbor Kubbs",
                        value: "\(session.totalNeighborKubbs)",
                        icon: "arrow.left.arrow.right",
                        color: .purple
                    )
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

struct BaseballKubbSessionDetailView: View {
    let session: BaseballKubbSession
    
    var body: some View {
        VStack(spacing: 16) {
            // Game Overview
            VStack(alignment: .leading, spacing: 12) {
                Text("Game Overview")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    DetailStatCard(
                        title: "Score",
                        value: "\(session.awayScore)-\(session.homeScore)",
                        icon: "sportscourt",
                        color: .blue
                    )
                    
                    DetailStatCard(
                        title: "Inning",
                        value: "\(session.currentInning)\(session.isTop ? " (Top)" : " (Bottom)")",
                        icon: "arrow.clockwise",
                        color: .green
                    )
                    
                    DetailStatCard(
                        title: "Your Score",
                        value: "\(session.userScore)",
                        icon: "person.fill",
                        color: .orange
                    )
                    
                    DetailStatCard(
                        title: "Your Kings",
                        value: "\(session.userKings)",
                        icon: "star.fill",
                        color: .yellow
                    )
                    
                    DetailStatCard(
                        title: "Batons Used",
                        value: "\(session.batonCount)",
                        icon: "arrow.right.circle",
                        color: .purple
                    )
                    
                    DetailStatCard(
                        title: "Field Kubbs",
                        value: "\(session.fieldKubbs)",
                        icon: "target",
                        color: .red
                    )
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Team Details
            VStack(alignment: .leading, spacing: 12) {
                Text("Team Details")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(session.awayTeam) (Away)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        HStack {
                            Text("Score: \(session.awayScore)")
                            Spacer()
                            Text("Kings: \(session.awayKings)")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 8) {
                        Text("\(session.homeTeam) (Home)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        HStack {
                            Text("Kings: \(session.homeKings)")
                            Spacer()
                            Text("Score: \(session.homeScore)")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

struct DetailStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct UnifiedRoundDetailRow: View {
    let round: Round
    let roundNumber: Int
    
    var body: some View {
        HStack {
            Text("Round \(roundNumber)")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            HStack(spacing: 16) {
                Text("\(round.hits)/5")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Text(String(format: "%.1f%%", round.accuracy * 100))
                    .font(.caption)
                    .foregroundColor(.orange)
                
                if round.kingThrowsCount > 0 {
                    Text("👑 \(round.kingThrowsCount)")
                        .font(.caption)
                        .foregroundColor(.yellow)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let sampleSession = PracticeSession(target: 20)
    return UnifiedSessionDetailView(session: .practice(sampleSession))
}
