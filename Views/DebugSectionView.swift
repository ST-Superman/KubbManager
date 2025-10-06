//
//  DebugSectionView.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 1/15/25.
//

import SwiftUI

struct DebugSectionView: View {
    @EnvironmentObject private var cloudKitManager: CloudKitManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Debug Tools")
                .font(.headline)
            
            VStack(spacing: 12) {
                Button("Test CloudKit Connection") {
                    Task {
                        await cloudKitManager.testCloudKitConnection()
                    }
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Button("Test CloudKit Queries") {
                    Task {
                        await cloudKitManager.testCloudKitQueries()
                    }
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Button("Remove Duplicates") {
                    Task {
                        await cloudKitManager.removeDuplicateCloudKitRecords()
                    }
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Button("Cleanup Old & Empty Records") {
                    Task {
                        await cloudKitManager.cleanupOldAndEmptyRecords()
                    }
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Button("Clear All CloudKit Data") {
                    Task {
                        await cloudKitManager.clearAllCloudKitData()
                    }
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Divider()
                
                Text("Individual Record Types")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
                
                Button("Clear Baseball_Kubb_Session") {
                    Task {
                        await cloudKitManager.clearBaseballKubbSessionData()
                    }
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Button("Clear InkastBlast_Session") {
                    Task {
                        await cloudKitManager.clearInkastBlastSessionData()
                    }
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Button("Clear Practice_Session (Legacy)") {
                    Task {
                        await cloudKitManager.clearPracticeSessionDataLegacy()
                    }
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Button("Refresh iCloud Status") {
                    Task {
                        await cloudKitManager.refreshAccountStatus()
                    }
                }
                .buttonStyle(SecondaryButtonStyle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("iCloud Status: \(cloudKitManager.isSignedIn ? "Signed In" : "Not Signed In")")
                        .font(.caption)
                        .foregroundColor(cloudKitManager.isSignedIn ? .green : .red)
                    
                    Text("Account Status: \(cloudKitManager.accountStatus.description)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if case .error(let message) = cloudKitManager.syncStatus {
                        Text("Error: \(message)")
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

#Preview {
    let cloudKitManager = CloudKitManager.shared
    return DebugSectionView()
        .environmentObject(cloudKitManager)
}
