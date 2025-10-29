//
//  ContentView.swift
//  Kubb Manager Watch
//
//  Created by AI Assistant on 10/8/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var connectivityManager: WatchConnectivityManager
    @State private var showingBatonInput = false
    @State private var showingInkastInput = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // App Header
                    headerView
                    
                    // Session Status
                    if let sessionState = connectivityManager.currentSessionState {
                        sessionStatusView(sessionState)
                    } else {
                        noSessionView
                    }
                    
                    // Connection Status
                    connectionStatusView
                    
                    // Pending Input
                    if connectivityManager.hasPendingInput {
                        pendingInputView
                    }
                }
                .padding()
            }
            .navigationTitle("Kubb Manager")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingBatonInput) {
            if let context = connectivityManager.pendingBatonContext {
                BatonThrowInputView(context: context)
                    .environmentObject(connectivityManager)
            }
        }
        .sheet(isPresented: $showingInkastInput) {
            if let context = connectivityManager.pendingInkastContext {
                InkastInputView(context: context)
                    .environmentObject(connectivityManager)
            }
        }
        .onChange(of: connectivityManager.hasPendingInput) { hasPending in
            if hasPending {
                // Show appropriate input view
                if connectivityManager.pendingBatonContext != nil {
                    showingBatonInput = true
                } else if connectivityManager.pendingInkastContext != nil {
                    showingInkastInput = true
                }
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 8) {
            Image(systemName: "figure.play")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            
            Text("Kubb Manager")
                .font(.headline)
                .fontWeight(.bold)
        }
        .padding(.vertical)
    }
    
    // MARK: - Session Status View
    
    private func sessionStatusView(_ state: WatchSessionState) -> some View {
        VStack(spacing: 12) {
            // Session Type
            Text(state.sessionType)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            // Round Info
            if let currentRound = state.currentRound {
                HStack(spacing: 4) {
                    Text("Round \(currentRound)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let totalRounds = state.totalRounds {
                        Text("of \(totalRounds)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Phase Info
            if let phase = state.currentPhase {
                Text(phase)
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // Status Badge
            HStack(spacing: 4) {
                Circle()
                    .fill(state.isActive ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
                
                Text(state.isActive ? "Active" : "Inactive")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(red: 0.95, green: 0.95, blue: 0.97))
        .cornerRadius(12)
    }
    
    // MARK: - No Session View
    
    private var noSessionView: some View {
        VStack(spacing: 12) {
            Image(systemName: "iphone")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text("No Active Session")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Start a session on your iPhone to begin recording throws.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    // MARK: - Connection Status View
    
    private var connectionStatusView: some View {
        HStack(spacing: 8) {
            Image(systemName: connectivityManager.isPhoneReachable ? "iphone.radiowaves.left.and.right" : "iphone.slash")
                .font(.caption)
                .foregroundColor(connectivityManager.isPhoneReachable ? .green : .red)
            
            Text(connectivityManager.isPhoneReachable ? "Connected to iPhone" : "iPhone Not Reachable")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(red: 0.95, green: 0.95, blue: 0.97))
        .cornerRadius(8)
    }
    
    // MARK: - Pending Input View
    
    private var pendingInputView: some View {
        VStack(spacing: 12) {
            Image(systemName: "bell.badge.fill")
                .font(.title2)
                .foregroundColor(.orange)
            
            Text("Input Requested")
                .font(.headline)
                .fontWeight(.bold)
            
            Text("Tap to record your throw")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button(action: {
                if connectivityManager.pendingBatonContext != nil {
                    showingBatonInput = true
                } else if connectivityManager.pendingInkastContext != nil {
                    showingInkastInput = true
                }
            }) {
                Text("Open Input")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange, lineWidth: 2)
        )
    }
}

#Preview {
    ContentView()
        .environmentObject(WatchConnectivityManager.shared)
}
