//
//  UserTeamSelectionView.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 1/15/25.
//

import SwiftUI

struct UserTeamSelectionView: View {
    @Binding var selectedTeam: UserTeam?
    let awayTeam: String
    let homeTeam: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Which team are you on?")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 8) {
                ForEach(UserTeam.allCases, id: \.self) { team in
                    Button(action: {
                        print("🎯 Selected team: \(team)")
                        selectedTeam = team
                    }) {
                        HStack {
                            Image(systemName: selectedTeam == team ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(selectedTeam == team ? .blue : .gray)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(team.displayName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                
                                Text(teamDescription(for: team))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedTeam == team ? Color.blue.opacity(0.1) : Color(.systemGray6))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private func teamDescription(for team: UserTeam) -> String {
        switch team {
        case .away:
            return "Track stats for \(awayTeam)"
        case .home:
            return "Track stats for \(homeTeam)"
        case .both:
            return "Practice mode - track stats for both teams"
        case .none:
            return "Just keep score - no personal stats tracking"
        }
    }
}

#Preview {
    UserTeamSelectionView(
        selectedTeam: .constant(nil),
        awayTeam: "Team A",
        homeTeam: "Team B"
    )
    .padding()
}
