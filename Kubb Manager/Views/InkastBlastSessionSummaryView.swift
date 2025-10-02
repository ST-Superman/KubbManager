//
//  InkastBlastSessionSummaryView.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 1/15/25.
//

import SwiftUI

struct InkastBlastSessionSummaryView: View {
    let session: InkastBlastSessionData
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    sessionHeaderView
                    
                    // Statistics Grid
                    statisticsGridView
                    
                    // Performance Summary
                    performanceSummaryView
                    
                    // Round Details
                    if !session.rounds.isEmpty {
                        roundDetailsView
                    }
                }
                .padding()
            }
            .navigationTitle("Session Complete")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
        }
    }
    
    private var sessionHeaderView: some View {
        VStack(spacing: 12) {
            Image("inkastblast")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Text(session.gamePhase.rawValue)
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Session completed on \(session.date.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var statisticsGridView: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            InkastStatCard(
                title: "Total Rounds",
                value: "\(session.totalRounds)",
                icon: "number.circle"
            )
            
            InkastStatCard(
                title: "Inkast Kubbs",
                value: "\(session.totalInkastKubbs)",
                icon: "target"
            )
            
            InkastStatCard(
                title: "Kubbs Cleared",
                value: "\(session.totalKubbsClearedFirstThrow)",
                icon: "checkmark.circle"
            )
            
            InkastStatCard(
                title: "Total Batons",
                value: "\(session.totalBatonsUsed)",
                icon: "arrow.right.circle"
            )
            
            InkastStatCard(
                title: "Penalty Kubbs",
                value: "\(session.totalPenaltyKubbs)",
                icon: "exclamationmark.triangle"
            )
            
            InkastStatCard(
                title: "Neighbor Kubbs",
                value: "\(session.totalNeighborKubbs)",
                icon: "square.stack.3d.up"
            )
        }
    }
    
    private var performanceSummaryView: some View {
        VStack(spacing: 16) {
            Text("Performance Summary")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                PerformanceRow(
                    title: "Avg Kubbs/Baton",
                    value: String(format: "%.1f", session.averageKubbsPerBaton),
                    color: averageKubbsPerBatonColor(session.averageKubbsPerBaton)
                )
                
                PerformanceRow(
                    title: "Avg Kubbs/Round",
                    value: String(format: "%.1f", session.averageKubbsPerRound),
                    color: .primary
                )
                
                PerformanceRow(
                    title: "Avg Batons/Round",
                    value: String(format: "%.1f", session.averageBatonsPerRound),
                    color: .primary
                )
                
                PerformanceRow(
                    title: "Penalty Rate",
                    value: String(format: "%.1f%%", session.penaltyRate * 100),
                    color: penaltyColor(session.penaltyRate)
                )
                
                PerformanceRow(
                    title: "Neighbor Rate",
                    value: String(format: "%.1f%%", session.neighborRate * 100),
                    color: .primary
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var roundDetailsView: some View {
        VStack(spacing: 16) {
            Text("Round Details")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ForEach(session.rounds) { round in
                RoundDetailCard(round: round)
            }
        }
    }
    
    private func averageKubbsPerBatonColor(_ averageKubbsPerBaton: Double) -> Color {
        if averageKubbsPerBaton >= 2.5 {
            return .purple
        } else if averageKubbsPerBaton >= 1.75 {
            return .green
        } else if averageKubbsPerBaton >= 1.0 {
            return .orange
        } else {
            return .red
        }
    }
    
    private func penaltyColor(_ penaltyRate: Double) -> Color {
        if penaltyRate <= 0.1 {
            return .green
        } else if penaltyRate <= 0.2 {
            return .orange
        } else {
            return .red
        }
    }
}

struct InkastStatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
    }
}

struct PerformanceRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.body)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

struct RoundDetailCard: View {
    let round: InkastBlastRoundData
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Round \(round.roundNumber)")
                    .font(.headline)
                
                Spacer()
                
                Text("\(round.batonsUsed)/\(round.targetBatons) batons")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(performanceColor(round.performanceVsTarget).opacity(0.2))
                    .cornerRadius(6)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(round.inkastKubbs) kubbs inkasted")
                    Text("\(round.kubbsClearedFirstThrow) cleared")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if round.penaltyKubbs > 0 {
                        Text("\(round.penaltyKubbs) penalties")
                            .foregroundColor(.red)
                    }
                    if round.neighborKubbs > 0 {
                        Text("\(round.neighborKubbs) neighbors")
                            .foregroundColor(.orange)
                    }
                }
                .font(.caption)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
    }
    
    private func performanceColor(_ performance: Int) -> Color {
        if performance > 0 {
            return .green
        } else if performance < 0 {
            return .red
        } else {
            return .blue
        }
    }
}

#Preview {
    InkastBlastSessionSummaryView(
        session: InkastBlastSessionData(
            gamePhase: .mid,
            startTime: Date().addingTimeInterval(-3600)
        )
    ) {
        // Preview dismiss action
    }
}
