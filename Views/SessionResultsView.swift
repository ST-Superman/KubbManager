//
//  SessionResultsView.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 9/23/25.
//

import SwiftUI

struct SessionResultsView: View {
    let session: PracticeSession
    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet = false
    @State private var shareText = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    SessionHeaderView(session: session)
                    
                    // Statistics Grid
                    StatisticsGridView(session: session)
                    
                    // Round Details
                    RoundDetailsView(session: session)
                    
                    // Share Button
                    ShareButton {
                        showingShareSheet = true
                    }
                }
                .padding()
            }
            .navigationTitle("Session Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [generateSessionSummary()])
        }
    }
    
    private func generateSessionSummary() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        let duration: String
        if let endTime = session.endTime {
            let interval = endTime.timeIntervalSince(session.startTime)
            let minutes = Int(interval) / 60
            let seconds = Int(interval) % 60
            duration = "\(minutes):\(String(format: "%02d", seconds))"
        } else {
            duration = "N/A"
        }
        
        return """
        🎯 Kubb Practice Session Results
        
        📅 Date: \(dateFormatter.string(from: session.date))
        🎯 Target: \(session.target) kubbs
        ✅ Kubbs Knocked: \(session.totalKubbs)
        🪃 Batons Used: \(session.totalBatons)
        🎯 Accuracy: \(String(format: "%.1f%%", session.accuracy * 100))
        ⏱️ Duration: \(duration)
        🔄 Rounds: \(session.completedRounds.count)
        👑 Baseline Clears: \(session.totalBaselineClears)
        🏰 King Throws: \(session.totalKingThrows) (\(String(format: "%.1f%%", session.kingAccuracy * 100)) hits)
        
        Great practice session! Keep up the good work! 🏆
        """
    }
}

struct SessionHeaderView: View {
    let session: PracticeSession
    
    var body: some View {
        VStack(spacing: 16) {
            // Status Animation
            ZStack {
                Circle()
                    .fill(session.isTargetReached ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                    .frame(width: 100, height: 100)
                
                Image(systemName: session.isTargetReached ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(session.isTargetReached ? .green : .orange)
            }
            
            if session.isTargetReached {
                Text("Session Complete!")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("🎉 Target Reached!")
                    .font(.headline)
                    .foregroundColor(.green)
            } else {
                Text("Session Ended")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Target not reached - \(session.target - session.totalKubbs) kubbs remaining")
                    .font(.headline)
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct StatisticsGridView: View {
    let session: PracticeSession
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Session Statistics")
                .font(.headline)
            
            LazyVGrid(columns: columns, spacing: 16) {
                StatisticCard(
                    title: "Kubbs Knocked",
                    value: "\(session.totalKubbs)",
                    subtitle: "of \(session.target)",
                    icon: "target",
                    color: .blue
                )
                
                StatisticCard(
                    title: "Accuracy",
                    value: String(format: "%.1f%%", session.accuracy * 100),
                    subtitle: accuracySubtitle,
                    icon: "scope",
                    color: accuracyColor
                )
                
                StatisticCard(
                    title: "Batons Used",
                    value: "\(session.totalBatons)",
                    subtitle: "total throws",
                    icon: "bolt",
                    color: .orange
                )
                
                StatisticCard(
                    title: "Rounds",
                    value: "\(session.completedRounds.count)",
                    subtitle: "completed",
                    icon: "arrow.clockwise",
                    color: .purple
                )
                
                StatisticCard(
                    title: "Baseline Clears",
                    value: "\(session.totalBaselineClears)",
                    subtitle: "rounds",
                    icon: "crown.fill",
                    color: .yellow
                )
                
                StatisticCard(
                    title: "King Throws",
                    value: "\(session.totalKingThrows)",
                    subtitle: String(format: "%.1f%% hits", session.kingAccuracy * 100),
                    icon: "crown",
                    color: .purple
                )
            }
        }
    }
    
    private var accuracyColor: Color {
        let accuracy = session.accuracy
        if accuracy >= 0.7 {
            return .green
        } else if accuracy >= 0.5 {
            return .orange
        } else {
            return .red
        }
    }
    
    private var accuracySubtitle: String {
        let accuracy = session.accuracy
        if accuracy >= 0.7 {
            return "excellent"
        } else if accuracy >= 0.5 {
            return "good"
        } else {
            return "practice more"
        }
    }
}

struct StatisticCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct RoundDetailsView: View {
    let session: PracticeSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Round Details")
                .font(.headline)
            
            if session.completedRounds.isEmpty {
                Text("No completed rounds")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(session.completedRounds) { round in
                    RoundDetailRow(round: round)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct RoundDetailRow: View {
    let round: Round
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Round \(round.roundNumber)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("\(round.kubbsKnockedDown) kubbs • \(round.totalBatonThrows) batons")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(String(format: "%.1f%%", round.accuracy * 100))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(accuracyColor)
                    
                    HStack(spacing: 2) {
                        ForEach(0..<6, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(round.kubbState(at: index) ? Color.green : Color.gray)
                                .frame(width: 6, height: 12)
                        }
                    }
                }
            }
            
            // Show throw details
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text("\(round.hits) hits")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                    Text("\(round.misses) misses")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if round.hasBaselineClear {
                    HStack(spacing: 4) {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        Text("Baseline Clear")
                            .font(.caption)
                            .foregroundColor(.yellow)
                            .fontWeight(.medium)
                    }
                }
                
                if round.kingThrowsCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "crown")
                            .foregroundColor(.purple)
                            .font(.caption)
                        Text("\(round.kingThrowsCount) king")
                            .font(.caption)
                            .foregroundColor(.purple)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var accuracyColor: Color {
        if round.accuracy >= 0.7 {
            return .green
        } else if round.accuracy >= 0.5 {
            return .orange
        } else {
            return .red
        }
    }
}

struct ShareButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "square.and.arrow.up")
                Text("Share Results")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(12)
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    let sampleSession = PracticeSession(target: 100)
    return SessionResultsView(session: sampleSession)
}
