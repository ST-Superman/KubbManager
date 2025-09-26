//
//  HistoryView.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 9/23/25.
//

import SwiftUI

struct HistoryView: View {
    @StateObject private var historyManager = HistoryManager()
    @StateObject private var sessionManager = SessionManager()
    @State private var selectedSession: PracticeSession?
    @State private var showingSessionDetail = false
    @State private var showingExportOptions = false
    @State private var showingDeleteAlert = false
    @State private var sessionToDelete: PracticeSession?
    
    var body: some View {
        NavigationView {
            Group {
                if historyManager.isLoading && historyManager.sessions.isEmpty {
                    LoadingView()
                } else if historyManager.sessions.isEmpty && !sessionManager.hasIncompleteSession() {
                    EmptyHistoryView()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Incomplete Session Section
                            if sessionManager.hasIncompleteSession() {
                                IncompleteSessionSection()
                                    .environmentObject(sessionManager)
                            }
                            
                            // Completed Sessions Section
                            if !historyManager.sessions.isEmpty {
                                CompletedSessionsSection()
                                    .environmentObject(historyManager)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Practice History")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Refresh") {
                            Task {
                                await historyManager.refreshSessions()
                            }
                        }
                        
                        Button("Clean Duplicates") {
                            Task {
                                await CloudKitManager.shared.removeDuplicateCloudKitRecords()
                                await historyManager.refreshSessions()
                            }
                        }
                        
                        Button("Export Data") {
                            showingExportOptions = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .refreshable {
                await historyManager.refreshSessions()
            }
        }
        .sheet(isPresented: $showingSessionDetail) {
            if let session = selectedSession {
                SessionResultsView(session: session)
            }
        }
        .actionSheet(isPresented: $showingExportOptions) {
            ActionSheet(
                title: Text("Export Data"),
                message: Text("Choose export format"),
                buttons: [
                    .default(Text("Export as JSON")) {
                        exportData(format: .json)
                    },
                    .default(Text("Export as CSV")) {
                        exportData(format: .csv)
                    },
                    .cancel()
                ]
            )
        }
        .alert("Delete Session", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let session = sessionToDelete {
                    Task {
                        await historyManager.deleteSession(session)
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this practice session? This action cannot be undone.")
        }
    }
    
    private func exportData(format: ExportFormat) {
        let content: String?
        
        switch format {
        case .json:
            content = historyManager.exportSessionsAsJSON()
        case .csv:
            content = historyManager.exportSessionsAsCSV()
        }
        
        if let content = content {
            let activityVC = UIActivityViewController(
                activityItems: [content],
                applicationActivities: nil
            )
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController?.present(activityVC, animated: true)
            }
        }
    }
    
    enum ExportFormat {
        case json, csv
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading practice history...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            Text("No Practice Sessions")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Start your first practice session to see your history here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SessionListView: View {
    @EnvironmentObject private var historyManager: HistoryManager
    @State private var selectedSession: PracticeSession?
    @State private var showingSessionDetail = false
    @State private var showingDeleteAlert = false
    @State private var sessionToDelete: PracticeSession?
    
    var body: some View {
        VStack(spacing: 0) {
            // Statistics Header
            StatisticsHeaderView()
                .environmentObject(historyManager)
            
            // Sessions List
            List {
                ForEach(historyManager.sessions) { session in
                    SessionRowView(session: session)
                        .onTapGesture {
                            selectedSession = session
                            showingSessionDetail = true
                        }
                        .contextMenu {
                            Button("View Details") {
                                selectedSession = session
                                showingSessionDetail = true
                            }
                            
                            Button("Delete", role: .destructive) {
                                sessionToDelete = session
                                showingDeleteAlert = true
                            }
                        }
                }
            }
            .listStyle(PlainListStyle())
        }
        .sheet(isPresented: $showingSessionDetail) {
            if let session = selectedSession {
                SessionResultsView(session: session)
            }
        }
        .alert("Delete Session", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let session = sessionToDelete {
                    Task {
                        await historyManager.deleteSession(session)
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this practice session? This action cannot be undone.")
        }
    }
}

struct StatisticsHeaderView: View {
    @EnvironmentObject private var historyManager: HistoryManager
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Overall Statistics")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                QuickStatView(
                    title: "Sessions",
                    value: "\(historyManager.totalSessions)",
                    icon: "calendar",
                    color: .blue
                )
                
                QuickStatView(
                    title: "Kubbs",
                    value: "\(historyManager.totalKubbsKnocked)",
                    icon: "target",
                    color: .green
                )
                
                QuickStatView(
                    title: "Accuracy",
                    value: String(format: "%.1f%%", historyManager.overallAccuracy * 100),
                    icon: "scope",
                    color: .orange
                )
                
                QuickStatView(
                    title: "Baseline Clears",
                    value: "\(historyManager.totalBaselineClears)",
                    icon: "crown.fill",
                    color: .yellow
                )
                
                QuickStatView(
                    title: "King Throws",
                    value: "\(historyManager.totalKingThrows)",
                    icon: "crown",
                    color: .purple
                )
                
                QuickStatView(
                    title: "King Accuracy",
                    value: String(format: "%.1f%%", historyManager.overallKingAccuracy * 100),
                    icon: "star.fill",
                    color: .red
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
}

struct QuickStatView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct SessionRowView: View {
    let session: PracticeSession
    
    var body: some View {
        HStack(spacing: 16) {
            // Date and Status
            VStack(alignment: .leading, spacing: 4) {
                Text(formatDate(session.date))
                    .font(.headline)
                    .fontWeight(.medium)
                
                HStack {
                    if session.isTargetReached {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                    
                    Text(formatTime(session.startTime))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Session Stats
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 8) {
                    Text("\(session.totalKubbs)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text("/")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(session.target)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "scope")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Text(String(format: "%.1f%%", session.accuracy * 100))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(accuracyColor)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private var accuracyColor: Color {
        if session.accuracy >= 0.7 {
            return .green
        } else if session.accuracy >= 0.5 {
            return .orange
        } else {
            return .red
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct IncompleteSessionSection: View {
    @EnvironmentObject private var sessionManager: SessionManager
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Incomplete Session")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            if let session = sessionManager.currentSession {
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Started")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(session.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Target")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(session.target) kubbs")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Progress")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(session.totalKubbs) / \(session.target)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Accuracy")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(session.accuracy, specifier: "%.1f")%")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                    
                    HStack(spacing: 12) {
                        Button("Resume") {
                            sessionManager.resumeSession()
                        }
                        .buttonStyle(ResumeButtonStyle())
                        
                        Button("Delete") {
                            showingDeleteAlert = true
                        }
                        .buttonStyle(DeleteButtonStyle())
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
        .alert("Delete Incomplete Session", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await sessionManager.deleteIncompleteSession()
                }
            }
        } message: {
            Text("Are you sure you want to delete this incomplete session? This action cannot be undone.")
        }
    }
}

struct CompletedSessionsSection: View {
    @EnvironmentObject private var historyManager: HistoryManager
    @State private var selectedSession: PracticeSession?
    @State private var showingSessionDetail = false
    @State private var showingDeleteAlert = false
    @State private var sessionToDelete: PracticeSession?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Completed Sessions")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Text("\(historyManager.sessions.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            LazyVStack(spacing: 8) {
                ForEach(historyManager.sessions) { session in
                    SessionRowView(session: session)
                        .onTapGesture {
                            selectedSession = session
                            showingSessionDetail = true
                        }
                }
            }
        }
        .sheet(isPresented: $showingSessionDetail) {
            if let session = selectedSession {
                SessionResultsView(session: session)
            }
        }
        .alert("Delete Session", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let session = sessionToDelete {
                    Task {
                        await historyManager.deleteSession(session)
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this session? This action cannot be undone.")
        }
    }
}

#Preview {
    HistoryView()
}
