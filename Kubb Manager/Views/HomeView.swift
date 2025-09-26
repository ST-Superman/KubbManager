//
//  HomeView.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 9/23/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var sessionManager: SessionManager
    @Binding var selectedTab: Int
    @State private var showingTargetSetting = false
    @State private var cloudKitManager = CloudKitManager.shared
    @StateObject private var settingsManager = SettingsManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Welcome Header
                WelcomeHeaderView()
                
                // Current Session Card
                if sessionManager.isSessionActive {
                    CurrentSessionCardView {
                        selectedTab = 1
                    }
                    .environmentObject(sessionManager)
                } else if sessionManager.hasIncompleteSession() {
                    IncompleteSessionCardView()
                        .environmentObject(sessionManager)
                } else {
                    StartSessionCardView(
                        onStartSession: {
                            showingTargetSetting = true
                        },
                        onShowTutorial: {
                            selectedTab = 3 // Tutorial tab
                        }
                    )
                }
                
                // Lifetime Stats
                LifetimeStatsView()
                    .environmentObject(sessionManager)
                
                // Recent Activity
                RecentActivityView()
                
                // Debug Section (conditional)
                if settingsManager.showDebugTools {
                    DebugSectionView()
                        .environmentObject(cloudKitManager)
                }
            }
            .padding()
        }
        .sheet(isPresented: $showingTargetSetting) {
            TargetSettingView()
        }
    }
}

struct WelcomeHeaderView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image("kubb_crosshair")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
            
            Text("8 Meter Training Overview")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Track your progress, view stats, and manage your 8-meter practice sessions")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct CurrentSessionCardView: View {
    @EnvironmentObject private var sessionManager: SessionManager
    let onContinuePractice: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                
                Text("Practice in Progress")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            // Progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Progress")
                    Spacer()
                    Text("\(sessionManager.totalKubbs) / \(sessionManager.target)")
                        .fontWeight(.medium)
                }
                
                ProgressView(value: sessionManager.progressPercentage)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            }
            
            // Quick Stats
            HStack {
                VStack(alignment: .leading) {
                    Text("Accuracy")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f%%", sessionManager.accuracy * 100))
                        .font(.headline)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Batons")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(sessionManager.totalBatons)")
                        .font(.headline)
                        .fontWeight(.bold)
                }
            }
            
            Button("Continue Practice") {
                onContinuePractice()
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct StartSessionCardView: View {
    let onStartSession: () -> Void
    let onShowTutorial: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            Text("Ready to Practice?")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Set your target and start tracking your kubb practice session.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 12) {
                Button("Start New Session") {
                    onStartSession()
                }
                .buttonStyle(PrimaryButtonStyle())
                
                Button(action: onShowTutorial) {
                    Image(systemName: "questionmark.circle")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .buttonStyle(TutorialButtonStyle(isSecondary: true))
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct LifetimeStatsView: View {
    @EnvironmentObject private var sessionManager: SessionManager
    @StateObject private var historyManager = HistoryManager()
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Lifetime Stats")
                    .font(.headline)
                Spacer()
            }
            
            // Tab selector
            Picker("Stats View", selection: $selectedTab) {
                Text("Lifetime Stats").tag(0)
                Text("Recent Trends").tag(1)
            }
            .pickerStyle(.segmented)
            
            if selectedTab == 0 {
                LifetimeStatsContentView(historyManager: historyManager, sessionManager: sessionManager)
            } else {
                RecentTrendsView(historyManager: historyManager)
            }
        }
    }
}

struct LifetimeStatsContentView: View {
    @ObservedObject var historyManager: HistoryManager
    @ObservedObject var sessionManager: SessionManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Note about completed sessions only
            Text("Data from completed sessions only")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ], spacing: 16) {
                LifetimeStatItem(
                    title: "Total Kubbs",
                    value: "\(historyManager.totalKubbsKnocked)",
                    icon: "target",
                    color: .blue
                )
                
                LifetimeStatItem(
                    title: "Baseline Clears",
                    value: "\(historyManager.totalBaselineClears)",
                    icon: "checkmark.seal",
                    color: .green
                )
                
                LifetimeStatItem(
                    title: "King Accuracy",
                    value: "\(Int(historyManager.overallKingAccuracy * 100))% (\(historyManager.totalKingHits) of \(historyManager.totalKingThrows))",
                    icon: "crown",
                    color: .orange
                )
                
                LifetimeStatItem(
                    title: "Consecutive Days",
                    value: "\(consecutiveDaysCount)",
                    icon: "calendar.badge.clock",
                    color: .red
                )
            }
        }
    }
    
    private var consecutiveDaysCount: Int {
        // Calculate consecutive days including/excluding current day logic
        let calendar = Calendar.current
        let today = Date()
        
        // Get all completed sessions, sorted by date descending
        let completedSessions = historyManager.sessions.sorted { $0.date > $1.date }
        
        guard !completedSessions.isEmpty else { return 0 }
        
        var consecutiveDays = 0
        var currentDate = today
        
        // Check if current day was completed
        let todaySession = completedSessions.first { calendar.isDateInToday($0.date) }
        let hasCompletedToday = todaySession?.isTargetReached == true
        
        // If today is completed, start counting from today, otherwise start from yesterday
        if !hasCompletedToday {
            currentDate = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        }
        
        // Count backwards day by day to find consecutive streak
        while true {
            let dayStart = calendar.startOfDay(for: currentDate)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
            
            let daySession = completedSessions.first { session in
                let sessionDate = calendar.startOfDay(for: session.date)
                return sessionDate >= dayStart && sessionDate < dayEnd && session.isTargetReached
            }
            
            if daySession != nil && daySession!.isTargetReached {
                consecutiveDays += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }
        
        return consecutiveDays
    }
}

struct LifetimeStatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct RecentTrendsView: View {
    @ObservedObject var historyManager: HistoryManager
    @State private var visibleDays = 10
    @State private var startIndex = 0
    @State private var selectedDataPoint: AccuracyDataPoint?
    @State private var showingTooltip = false
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Baton Accuracy by Day")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            if dailyAccuracyData.isEmpty {
                VStack {
                    Image(systemName: "chart.line.downtrend.xyaxis")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("No completed sessions to display")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: 200)
            } else {
                SimpleAccuracyChartView(
                    data: dailyAccuracyData,
                    selectedDataPoint: $selectedDataPoint,
                    showingTooltip: $showingTooltip
                )
                .frame(height: 200)
                .overlay(
                    // Tooltip overlay with boundary detection
                    GeometryReader { overlayGeometry in
                        Group {
                            if showingTooltip, let selectedPoint = selectedDataPoint {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(dateFormatter.string(from: selectedPoint.date))")
                                        .font(.caption).fontWeight(.bold)
                                    Text("Accuracy: \(Int(selectedPoint.accuracy * 100))%")
                                        .font(.caption2)
                                    Text("Kubbs: \(selectedPoint.kubbs) of \(selectedPoint.batons)")
                                        .font(.caption2)
                                }
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .shadow(radius: 4)
                                .position(
                                    x: min(max(selectedPoint.position.x + 60, 80), overlayGeometry.size.width - 80),
                                    y: selectedPoint.position.y
                                )
                                .frame(width: 120, alignment: .leading)
                            }
                        }
                    }
                )
                
                // Navigation controls
                if !dailyAccuracyData.isEmpty {
                    let totalCount = dailyAccuracyData.count
                    let minDays = 1
                    let maxDays = min(30, max(minDays, totalCount))
                    let safeZoomRange: ClosedRange<Int> = maxDays != minDays ? (minDays...maxDays) : (1...1)
                    
                    ChartNavigationControls(
                        visibleDays: $visibleDays,
                        startIndex: $startIndex,
                        maxDataPoints: totalCount,
                        zoomRange: safeZoomRange
                    )
                    .onAppear {
                        // Correct visibleDays on appear to prevent future bounds errors
                        if visibleDays > totalCount {
                            visibleDays = max(1, totalCount)
                        }
                        startIndex = min(startIndex, max(0, totalCount - 1))
                    }
                }
            }
        }
    }
    
    private var dailyAccuracyData: [AccuracyDataPoint] {
        let calendar = Calendar.current
        var dayData: [Date: [PracticeSession]] = [:]
        
        // Group sessions by date
        for session in historyManager.sessions {
            let date = calendar.startOfDay(for: session.date)
            dayData[date, default: []].append(session)
        }
        
        return dayData.compactMap { (date, sessions) in
            let totalKubbs = sessions.reduce(0) { $0 + $1.totalKubbs }
            let totalBatons = sessions.reduce(0) { $0 + $1.totalBatons }
            let accuracy = totalBatons > 0 ? Double(totalKubbs) / Double(totalBatons) : 0.0
            
            return AccuracyDataPoint(
                date: date,
                accuracy: accuracy,
                kubbs: totalKubbs,
                batons: totalBatons,
                position: CGPoint(x: 0, y: 0) // Will be set dynamically
            )
        }.sorted { $0.date < $1.date }
    }
}

struct AccuracyDataPoint {
    let date: Date
    let accuracy: Double
    let kubbs: Int
    let batons: Int
    var position: CGPoint
}

struct SimpleAccuracyChartView: View {
    let data: [AccuracyDataPoint]
    @Binding var selectedDataPoint: AccuracyDataPoint?
    @Binding var showingTooltip: Bool
    
    var body: some View {
        if data.isEmpty {
            VStack {
                Image(systemName: "chart.line.downtrend.xyaxis")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
                Text("No data to display")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        } else {
            GeometryReader { geometry in
                let maxAccuracy = data.map { $0.accuracy }.max() ?? 1.0
                let minAccuracy = max(0, min(data.map { $0.accuracy }.min() ?? 0, maxAccuracy - 0.1))
                
                VStack {
                    // Simple y-axis labels
                    HStack {
                        VStack {
                            Text("\(Int(maxAccuracy * 100))%").font(.caption2).foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(minAccuracy * 100))%").font(.caption2).foregroundColor(.secondary)
                        }
                        .frame(width: 30)
                        
                        // Chart with points
                        ZStack {
                            // Background
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray6))
                            
                            // Chart content
                            ForEach(Array(data.enumerated()), id: \.offset) { index, dataPoint in
                                let normalizedAccuracy = maxAccuracy != minAccuracy ? 
                                    (dataPoint.accuracy - minAccuracy) / (maxAccuracy - minAccuracy) : 0.5
                                let x = data.count > 1 ? 
                                    geometry.size.width * CGFloat(index) / CGFloat(data.count - 1) : 
                                    geometry.size.width / 2
                                let y = geometry.size.height * (1.0 - CGFloat(normalizedAccuracy))
                                
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 8, height: 8)
                                    .position(x: x + 30, y: y + 10) // Offset for padding
                                    .onTapGesture {
                                        var mutableData = dataPoint
                                        mutableData.position = CGPoint(x: x + 30, y: y + 10) // Match exact positioning
                                        selectedDataPoint = mutableData
                                        showingTooltip = true
                                        
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                            showingTooltip = false
                                            selectedDataPoint = nil
                                        }
                                    }
                            }
                            
                            // Draw line connecting points if more than one data point
                            if data.count > 1 {
                                GeometryReader { lineGeometry in
                                    Path { path in
                                        for (index, dataPoint) in data.enumerated() {
                                            let normalizedAccuracy = maxAccuracy != minAccuracy ? 
                                                (dataPoint.accuracy - minAccuracy) / (maxAccuracy - minAccuracy) : 0.5
                                            let x = lineGeometry.size.width * CGFloat(index) / CGFloat(data.count - 1)
                                            let y = lineGeometry.size.height * (1.0 - CGFloat(normalizedAccuracy))
                                            
                                            if index == 0 {
                                                path.move(to: CGPoint(x: x + 30, y: y + 10))
                                            } else {
                                                path.addLine(to: CGPoint(x: x + 30, y: y + 10))
                                            }
                                        }
                                    }
                                    .stroke(Color.blue, lineWidth: 2)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

struct AccuracyChartView: View {
    let data: [AccuracyDataPoint]
    @Binding var selectedDataPoint: AccuracyDataPoint?
    @Binding var showingTooltip: Bool
    
    var body: some View {
        GeometryReader { geometry in
            let maxAccuracy = data.map { $0.accuracy }.max() ?? 1.0
            let minAccuracy = max(0, min(data.map { $0.accuracy }.min() ?? 0, maxAccuracy - 0.1))
            let accuracyRange = maxAccuracy - minAccuracy
            
            ZStack {
                // Grid background
                chartGridView(minValue: minAccuracy, maxValue: maxAccuracy)
                
                // Chart line and points
                if !data.isEmpty {
                    GeometryReader { geometry in
                        let xStep = data.count > 1 ? geometry.size.width / CGFloat(data.count - 1) : 0
                        let normalisedDataPoints = data.enumerated().compactMap { (index, dataPoint) -> CGPoint in
                            let normalizedAccuracy = accuracyRange > 0 ? (dataPoint.accuracy - minAccuracy) / accuracyRange : 0.5
                            let x = xStep * CGFloat(index)
                            let y = geometry.size.height * (1.0 - CGFloat(normalizedAccuracy))
                            return CGPoint(x: x, y: y)
                        }
                        
                        // Line Chart
                        LineChartLine(points: normalisedDataPoints)
                            .stroke(Color.blue, lineWidth: 2)
                        
                        // Data Points
                        ForEach(Array(data.enumerated()), id: \.offset) { index, dataPoint in
                            let normalizedAccuracy = accuracyRange > 0 ? (dataPoint.accuracy - minAccuracy) / accuracyRange : 0.5
                            let x = xStep * CGFloat(index)
                            let y = geometry.size.height * (1.0 - CGFloat(normalizedAccuracy))
                            
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 6, height: 6)
                                .position(x: x, y: y)
                                .onTapGesture {
                                    var mutableData = dataPoint
                                    mutableData.position = CGPoint(x: x, y: y - 10)
                                    selectedDataPoint = mutableData
                                    showingTooltip = true
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                        showingTooltip = false
                                        selectedDataPoint = nil
                                    }
                                }
                        }
                    }
                    .background(Color.white.opacity(0.001))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
    
    private func chartGridView(minValue: Double, maxValue: Double) -> some View {
        let gridLines = 5
        
        return VStack(spacing: 0) {
            HStack(spacing: 0) {
                VStack {
                    ForEach(0..<gridLines, id: \.self) { i in
                        let value = minValue + (maxValue - minValue) * Double(i) / Double(gridLines - 1)
                        Text("\(Int(value * 100))%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.leading, 4)
                        if i < gridLines - 1 {
                            Divider()
                        }
                    }
                }
                
                Divider()
                    .frame(height: 20 * CGFloat(gridLines))
            }
        }
    }
}

struct LineChartLine: Shape {
    let points: [CGPoint]
    
    func path(in rect: CGRect) -> Path {
        guard !points.isEmpty else { return Path() }
        
        var path = Path()
        path.move(to: points.first!)
        
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        
        return path
    }
}

struct ChartNavigationControls: View {
    @Binding var visibleDays: Int
    @Binding var startIndex: Int
    let maxDataPoints: Int
    let zoomRange: ClosedRange<Int>
    
    var body: some View {
        HStack {
            // Zoom slider
            VStack(alignment: .leading, spacing: 4) {
                Text("Zoom (\(visibleDays) days)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                if min(zoomRange.lowerBound, zoomRange.upperBound) < max(zoomRange.lowerBound, zoomRange.upperBound) {
                    Slider(
                        value: Binding(
                            get: { 
                                let lowerBoundValue = min(zoomRange.lowerBound, zoomRange.upperBound)
                                let upperBoundValue = max(zoomRange.lowerBound, zoomRange.upperBound)
                                return Double(max(lowerBoundValue, min(upperBoundValue, visibleDays))) 
                            },
                            set: { newValue in 
                                let lowerBoundValue = min(zoomRange.lowerBound, zoomRange.upperBound)
                                let upperBoundValue = max(zoomRange.lowerBound, zoomRange.upperBound)
                                visibleDays = max(lowerBoundValue, min(upperBoundValue, Int(newValue))) 
                            }
                        ),
                        in: Double(min(zoomRange.lowerBound, zoomRange.upperBound))...Double(max(zoomRange.lowerBound, zoomRange.upperBound)),
                        step: 1
                    )
                    .accentColor(.blue)
                } else {
                    // Fallback for single-value range (like 1...1)
                    Text("\(zoomRange.lowerBound) days")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Navigation buttons
            HStack(spacing: 8) {
                Button(action: { 
                    startIndex = max(0, startIndex - visibleDays/2)
                }) {
                    Image(systemName: "chevron.left")
                        .font(.caption)
                }
                .disabled(startIndex <= 0)
                
                Button(action: { 
                    startIndex = min(maxDataPoints - visibleDays, startIndex + visibleDays/2)
                }) {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .disabled(startIndex >= maxDataPoints - visibleDays)
            }
        }
        .padding(.horizontal)
    }
}

struct QuickStatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let isCustomImage: Bool
    
    init(title: String, value: String, icon: String, color: Color, isCustomImage: Bool = false) {
        self.title = title
        self.value = value
        self.icon = icon
        self.color = color
        self.isCustomImage = isCustomImage
    }
    
    var body: some View {
        VStack(spacing: 8) {
            if isCustomImage {
                Image(icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
            } else {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
            }
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct RecentActivityView: View {
    @StateObject private var historyManager = HistoryManager()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.headline)
            
            if historyManager.sessions.isEmpty {
                Text("No recent sessions")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(historyManager.sessions.prefix(3)) { session in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(formatDate(session.date))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text("\(session.totalKubbs)/\(session.target) kubbs • \(String(format: "%.1f%%", session.accuracy * 100))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if session.isTargetReached {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

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
                            
                            Button("Clear CloudKit Data") {
                                Task {
                                    await cloudKitManager.clearAllCloudKitData()
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

struct IncompleteSessionCardView: View {
    @EnvironmentObject private var sessionManager: SessionManager
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Incomplete Session")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let session = sessionManager.currentSession {
                        Text("Started \(session.date.formatted(date: .abbreviated, time: .shortened))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            if let session = sessionManager.currentSession {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Progress")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(session.totalKubbs) / \(session.target) kubbs")
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
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color(.systemGray5))
                .cornerRadius(8)
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
        .cornerRadius(16)
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

struct ResumeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct DeleteButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.red)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct IncompleteSessionPracticeView: View {
    @EnvironmentObject private var sessionManager: SessionManager
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                // Incomplete Session Icon
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.orange)
                
                VStack(spacing: 16) {
                    Text("Incomplete Session")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    if let session = sessionManager.currentSession {
                        Text("Started \(session.date.formatted(date: .abbreviated, time: .shortened))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        // Progress Info
                        VStack(spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Progress")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(session.totalKubbs) / \(session.target) kubbs")
                                        .font(.headline)
                                        .fontWeight(.medium)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Accuracy")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(session.accuracy, specifier: "%.1f")%")
                                        .font(.headline)
                                        .fontWeight(.medium)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button("Resume Session") {
                        sessionManager.resumeSession()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    
                    Button("Delete Session") {
                        showingDeleteAlert = true
                    }
                    .buttonStyle(DeleteButtonStyle())
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Practice")
            .navigationBarTitleDisplayMode(.inline)
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

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}


#Preview {
    HomeView(selectedTab: .constant(0))
        .environmentObject(SessionManager())
}
