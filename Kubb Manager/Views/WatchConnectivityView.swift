//
//  WatchConnectivityView.swift
//  Kubb Manager
//
//  Created by AI Assistant on 10/8/25.
//

import SwiftUI

// MARK: - Watch Connectivity Status View

/// Displays watch connectivity status and provides controls
struct WatchConnectivityStatusView: View {
    @ObservedObject var watchManager = WatchConnectivityManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            // Watch icon with status indicator
            ZStack(alignment: .topTrailing) {
                Image(systemName: "applewatch")
                    .font(.title2)
                    .foregroundColor(watchManager.isWatchReachable ? .green : .gray)
                
                // Status indicator dot
                Circle()
                    .fill(watchManager.isWatchReachable ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
                    .offset(x: 4, y: -4)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Apple Watch")
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Text(watchStatusText)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private var watchStatusText: String {
        if !watchManager.isWatchPaired {
            return "Not Paired"
        } else if !watchManager.isWatchAppInstalled {
            return "App Not Installed"
        } else if watchManager.isWatchReachable {
            return "Connected"
        } else {
            return "Not Reachable"
        }
    }
}

// MARK: - Watch Input Button

/// Button to trigger watch input request
struct WatchInputButton: View {
    let title: String
    let icon: String
    let isEnabled: Bool
    let action: () -> Void
    
    @ObservedObject var watchManager = WatchConnectivityManager.shared
    
    init(title: String = "Use Watch", 
         icon: String = "applewatch",
         isEnabled: Bool = true,
         action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isEnabled = isEnabled
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.body)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(buttonBackground)
            .cornerRadius(10)
        }
        .disabled(!canUseWatch)
    }
    
    private var canUseWatch: Bool {
        return watchManager.isWatchReachable && isEnabled
    }
    
    private var buttonBackground: Color {
        if !canUseWatch {
            return Color.gray
        }
        return Color.blue
    }
}

// MARK: - Watch Session Control Panel

/// Control panel for watch-enabled sessions
struct WatchSessionControlPanel: View {
    let sessionType: String
    let onStartWatchInput: () -> Void
    let onSendSessionState: () -> Void
    
    @ObservedObject var watchManager = WatchConnectivityManager.shared
    @State private var showingWatchInfo = false
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Compact Header (always visible)
            Button(action: { 
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "applewatch")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Text("Watch")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    // Watch Mode Badge
                    if watchManager.isWatchMode {
                        Text("MODE")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .cornerRadius(4)
                    }
                    
                    Spacer()
                    
                    // Status Indicator
                    Circle()
                        .fill(watchManager.isWatchReachable ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)
                    
                    // Expand/Collapse Icon
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            
            // Expanded Controls
            if isExpanded {
                VStack(spacing: 12) {
                    // Status
                    WatchConnectivityStatusView()
                    
                    if watchManager.isWatchReachable {
                        // Control buttons
                        VStack(spacing: 8) {
                            // Watch Mode Toggle
                            Button(action: {
                                if watchManager.isWatchMode {
                                    watchManager.disableWatchMode()
                                } else {
                                    watchManager.enableWatchMode()
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: watchManager.isWatchMode ? "applewatch.slash" : "applewatch")
                                        .font(.body)
                                    
                                    Text(watchManager.isWatchMode ? "Disable Watch Mode" : "Enable Watch Mode")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(watchManager.isWatchMode ? .orange : .green)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background((watchManager.isWatchMode ? Color.orange : Color.green).opacity(0.1))
                                .cornerRadius(10)
                            }
                            
                            WatchInputButton(
                                title: "Request Input on Watch",
                                icon: "applewatch.radiowaves.left.and.right",
                                action: onStartWatchInput
                            )
                            
                            Button(action: onSendSessionState) {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .font(.body)
                                    
                                    Text("Sync Session State")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.blue)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(10)
                            }
                        }
                    }
                    
                    // Info Button
                    Button(action: { showingWatchInfo.toggle() }) {
                        HStack {
                            Image(systemName: "info.circle")
                                .font(.caption)
                            Text("Watch Info")
                                .font(.caption)
                        }
                        .foregroundColor(.blue)
                    }
                }
                .padding(.top, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .sheet(isPresented: $showingWatchInfo) {
            WatchInfoSheet(sessionType: sessionType)
        }
    }
}

// MARK: - Watch Info Sheet

/// Information sheet about using Apple Watch with the app
struct WatchInfoSheet: View {
    let sessionType: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "applewatch")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Using Apple Watch")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Record your throws directly from your wrist")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom)
                    
                    // How it works
                    VStack(alignment: .leading, spacing: 16) {
                        WatchSectionHeader(title: "How It Works")
                        
                        InfoRow(
                            number: 1,
                            title: "Start Session on iPhone",
                            description: "Begin your \(sessionType) session on your iPhone as usual."
                        )
                        
                        InfoRow(
                            number: 2,
                            title: "Open Watch App",
                            description: "Open the Kubb Manager app on your Apple Watch."
                        )
                        
                        InfoRow(
                            number: 3,
                            title: "Request Input",
                            description: "Tap 'Request Input on Watch' to send the next throw prompt to your watch."
                        )
                        
                        InfoRow(
                            number: 4,
                            title: "Record on Watch",
                            description: "Use your watch to record hits, misses, and kubb counts."
                        )
                        
                        InfoRow(
                            number: 5,
                            title: "Auto Sync",
                            description: "Results automatically sync back to your iPhone."
                        )
                    }
                    
                    // Benefits
                    VStack(alignment: .leading, spacing: 16) {
                        WatchSectionHeader(title: "Benefits")
                        
                        BenefitRow(
                            icon: "hand.raised.fill",
                            title: "Hands-Free",
                            description: "Keep your phone in your pocket while playing."
                        )
                        
                        BenefitRow(
                            icon: "bolt.fill",
                            title: "Quick Recording",
                            description: "Record throws faster with simple watch buttons."
                        )
                        
                        BenefitRow(
                            icon: "arrow.triangle.2.circlepath",
                            title: "Real-Time Sync",
                            description: "All data syncs instantly between devices."
                        )
                    }
                    
                    // Requirements
                    VStack(alignment: .leading, spacing: 12) {
                        WatchSectionHeader(title: "Requirements")
                        
                        RequirementRow(
                            icon: "checkmark.circle.fill",
                            text: "Apple Watch paired with iPhone"
                        )
                        
                        RequirementRow(
                            icon: "checkmark.circle.fill",
                            text: "Kubb Manager watch app installed"
                        )
                        
                        RequirementRow(
                            icon: "checkmark.circle.fill",
                            text: "Watch within Bluetooth range"
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Watch Guide")
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

// MARK: - Supporting Views

struct WatchSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.headline)
            .fontWeight(.bold)
            .foregroundColor(.primary)
    }
}

struct InfoRow: View {
    let number: Int
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 28, height: 28)
                
                Text("\(number)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct BenefitRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.green)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct RequirementRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.green)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Compact Watch Button

/// Compact button for inline use in existing UIs
struct CompactWatchButton: View {
    let action: () -> Void
    @ObservedObject var watchManager = WatchConnectivityManager.shared
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "applewatch")
                    .font(.caption)
                
                Text("Watch")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(watchManager.isWatchReachable ? Color.blue : Color.gray)
            .cornerRadius(8)
        }
        .disabled(!watchManager.isWatchReachable)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        WatchConnectivityStatusView()
        
        WatchSessionControlPanel(
            sessionType: "8M Training",
            onStartWatchInput: { print("Start watch input") },
            onSendSessionState: { print("Send session state") }
        )
        
        CompactWatchButton(action: { print("Watch button tapped") })
    }
    .padding()
}
