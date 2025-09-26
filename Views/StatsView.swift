//
//  StatsView.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 9/23/25.
//

import SwiftUI

// MARK: - Data Types
struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let accuracy: Double
    let kubbs: Int
    let batons: Int
}

// MARK: - Main Stats View
struct StatsView: View {
    @StateObject private var historyManager = HistoryManager()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Lifetime Stats Section
                    LifetimeStatsSection()
                        .environmentObject(historyManager)
                    
                    // Recent Trends Section
                    RecentTrendsSection()
                        .environmentObject(historyManager)
                }
                .padding()
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            Task {
                await historyManager.loadSessions()
            }
        }
    }
}

// MARK: - Lifetime Stats
struct LifetimeStatsSection: View {
    @EnvironmentObject private var historyManager: HistoryManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Lifetime Stats")
                .font(.headline)
                .fontWeight(.bold)
            
            // Main stats grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                LifetimeStatCard(
                    title: "Total Sessions",
                    value: "\(historyManager.totalSessions)",
                    icon: "calendar.badge.plus",
                    color: .blue
                )
                
                LifetimeStatCard(
                    title: "Lifetime Kubbs",
                    value: "\(historyManager.totalKubbsKnocked)",
                    icon: "target",
                    color: .green
                )
                
                LifetimeStatCard(
                    title: "Lifetime Accuracy",
                    value: String(format: "%.1f%%", historyManager.overallAccuracy * 100),
                    icon: "scope",
                    color: .orange
                )
                
                LifetimeStatCard(
                    title: "Baseline Clears",
                    value: "\(historyManager.totalBaselineClears)",
                    icon: "crown.fill",
                    color: .yellow
                )
            }
            
            // King Accuracy with detailed stats
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("King Accuracy")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("\(String(format: "%.1f%%", historyManager.overallKingAccuracy * 100)) (\(historyManager.totalKingHits) of \(historyManager.totalKingThrows))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                }
                
                Spacer()
                
                Image(systemName: "star.fill")
                    .font(.title)
                    .foregroundColor(.purple)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Training Streak
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Longest Training Streak")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("\(calculateLongestStreak()) days")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                Image(systemName: "flame.fill")
                    .font(.title)
                    .foregroundColor(.red)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private func calculateLongestStreak() -> Int {
        let sessions = historyManager.sessions.sorted { $0.date < $1.date }
        guard !sessions.isEmpty else { return 0 }
        
        var maxStreak = 0
        var currentStreak = 0
        let calendar = Calendar.current
        
        var currentDate = sessions.first!.date
        
        for session in sessions {
            if calendar.isDate(session.date, inSameDayAs: currentDate) && session.isTargetReached {
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            } else {
                currentStreak = 0
            }
        }
        
        return maxStreak
    }
}

struct LifetimeStatCard: View {
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
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Recent Trends
struct RecentTrendsSection: View {
    @EnvironmentObject private var historyManager: HistoryManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Trends")
                .font(.headline)
                .fontWeight(.bold)
            
            // Strategies Chart
            RecentTrendsChart()
                .environmentObject(historyManager)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct RecentTrendsChart: View {
    @EnvironmentObject private var historyManager: HistoryManager
    @State private var selectedPeriod: ChartPeriod = .week
    @State private var chartData: [ChartDataPoint] = []
    @State private var selectedDataPoint: ChartDataPoint?
    @State private var showingTooltip = false
    @State private var tooltipLocation = CGPoint.zero
    @State private var chartBounds = CGRect.zero
    
    private var settingsManager = SettingsManager.shared
    
    private var recentAccuracy: String {
        guard let mostRecent = chartData.last else { return "No data" }
        return "\(String(format: "%.1f%%", mostRecent.accuracy * 100))"
    }
    
    enum ChartPeriod: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case quarter = "Quarter"
        
        var displayName: String {
            return rawValue
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Accuracy Trend")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("Most Recent: \(recentAccuracy)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Picker("Period", selection: $selectedPeriod) {
                    ForEach(ChartPeriod.allCases, id: \.self) { period in
                        Text(period.displayName).tag(period)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(maxWidth: 200)
            }
            
            if chartData.isEmpty {
                VStack {
                    Text("No data available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                        .padding()
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray5))
                .cornerRadius(8)
            } else {
                ZStack {
                    EnhancedChartView(
                        chartData: chartData,
                        selectedDataPoint: $selectedDataPoint,
                        showingTooltip: $showingTooltip,
                        tooltipLocation: $tooltipLocation,
                        chartBounds: $chartBounds,
                        targetAccuracy: settingsManager.chartTargetAccuracy
                    )
                    .frame(height: 200)
                    .padding(.vertical, 8)
                    
                    // Tooltip overlay
                    if showingTooltip, let dataPoint = selectedDataPoint {
                        TooltipView(
                            dataPoint: dataPoint,
                            location: tooltipLocation,
                            chartBounds: chartBounds
                        )
                        .zIndex(1)
                        .onTapGesture {
                            showingTooltip = false
                            selectedDataPoint = nil
                        }
                    }
                }
                .onTapGesture {
                    // Tap outside to dismiss tooltip
                    if showingTooltip {
                        showingTooltip = false
                        selectedDataPoint = nil
                    }
                }
            }
        }
        .onAppear {
            updateChartData()
        }
        .onChange(of: selectedPeriod) { _, _ in
            updateChartData()
        }
    }
    
    private func updateChartData() {
        let endDate = Date()
        let startDate: Date
        
        switch selectedPeriod {
        case .week:
            startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        case .month:
            startDate = Calendar.current.date(byAdding: .month, value: -1, to: endDate) ?? endDate
        case .quarter:
            startDate = Calendar.current.date(byAdding: .month, value: -3, to: endDate) ?? endDate
        }
        
        // Filter and sort sessions
        let relevantSessions = historyManager.sessions
            .filter { $0.date >= startDate && $0.date <= endDate && $0.totalBatons > 0 }
            .sorted(by: { $0.date < $1.date })
        
        chartData = relevantSessions.map { session in
            ChartDataPoint(
                date: session.date,
                accuracy: session.accuracy,
                kubbs: session.totalKubbs,
                batons: session.totalBatons
            )
        }
    }
}

// MARK: - Enhanced Chart
struct EnhancedChartView: View {
    let chartData: [ChartDataPoint]
    @Binding var selectedDataPoint: ChartDataPoint?
    @Binding var showingTooltip: Bool
    @Binding var tooltipLocation: CGPoint
    @Binding var chartBounds: CGRect
    let targetAccuracy: Double
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let chartAreaBounds = CGRect(x: 43, y: 20, width: width - 43, height: height - 35)
            
            VStack(spacing: 4) {
                // Y Axis labels and chart
                HStack(alignment: .top, spacing: 8) {
                    // Y Axis labels
                    VStack(alignment: .trailing, spacing: 0) {
                        Text("100%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("50%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("0%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 35, height: height - 20)
                    
                    // Chart content
                    ZStack(alignment: .bottomLeading) {
                        // Background grid lines
                        backgroundGrid(width: width - 43, height: height - 35)
                        
                        // Target line
                        targetLine(width: width - 43, height: height - 35)
                        
                        // Chart line and points
                        chartLine(width: width - 43, height: height - 35)
                        interactiveDataPoints(width: width - 43, height: height - 35)
                    }
                    
                    Spacer()
                }
                
                // X Axis labels
                HStack {
                    Spacer().frame(width: 35)
                    if !chartData.isEmpty {
                        Text(formattedDate(chartData.first?.date))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formattedDate(chartData.last?.date))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onAppear {
                // Update chart bounds for the main chart area (exclude axis labels)
                chartBounds = chartAreaBounds
            }
            .onChange(of: geometry.size) { _, _ in
                // Update chart bounds when geometry size changes
                let newBounds = CGRect(x: 43, y: 20, width: geometry.size.width - 43, height: geometry.size.height - 35)
                chartBounds = newBounds
            }
        }
    }
    
    private func backgroundGrid(width: CGFloat, height: CGFloat) -> some View {
        Path { path in
            for i in 0..<5 {
                let y = height * CGFloat(i) / 4
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: width, y: y))
            }
            
            // Vertical lines
            for i in 0..<5 {
                let x = width * CGFloat(i) / 4
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: height))
            }
        }
        .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
    }
    
    private func targetLine(width: CGFloat, height: CGFloat) -> some View {
        Path { path in
            let y = height * (1 - CGFloat(targetAccuracy))
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: width, y: y))
        }
        .stroke(Color.orange.opacity(0.7), lineWidth: 2)
        .clipShape(Rectangle())
    }
    
    private func chartLine(width: CGFloat, height: CGFloat) -> some View {
        Path { path in
            guard chartData.count > 1 else { return }
            
            var isFirst = true
            for (index, dataPoint) in chartData.enumerated() {
                let x = width * CGFloat(index) / CGFloat(max(chartData.count - 1, 1))
                let y = height * (1 - CGFloat(dataPoint.accuracy))
                
                if isFirst {
                    path.move(to: CGPoint(x: x, y: y))
                    isFirst = false
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
        }
        .stroke(Color.blue, lineWidth: 2)
    }
    
    private func interactiveDataPoints(width: CGFloat, height: CGFloat) -> some View {
        ForEach(Array(chartData.enumerated()), id: \.offset) { index, dataPoint in
            let x = width * CGFloat(index) / CGFloat(max(chartData.count - 1, 1))
            let y = height * (1 - CGFloat(dataPoint.accuracy))
            
            Circle()
                .fill(Color.blue)
                .frame(width: 12, height: 12)
                .position(x: x, y: y)
                .onTapGesture {
                    selectedDataPoint = dataPoint
                    showingTooltip = true
                    tooltipLocation = CGPoint(x: x, y: y)
                }
        }
    }
    
    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        if Calendar.current.isDate(date, equalTo: Date(), toGranularity: .day) {
            return "Today"
        } else {
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
}

// MARK: - Tooltip
struct TooltipView: View {
    let dataPoint: ChartDataPoint
    let location: CGPoint
    let chartBounds: CGRect
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(String(format: "%.1f%%", dataPoint.accuracy * 100))")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text("\(dataPoint.kubbs)/\(dataPoint.batons)")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.9))
            
            Text("\(dataPoint.kubbs) kubbs, \(dataPoint.batons) batons")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.85))
        .cornerRadius(10)
        .position(x: calculateTooltipX(), y: calculateTooltipY())
        .onTapGesture {
            // Allow dismissing by tapping other data points
        }
    }
    
    private func calculateTooltipX() -> CGFloat {
        // Tooltip size estimation
        let tooltipWidth: CGFloat = 160
        let chartLeft = chartBounds.minX
        let chartRight = chartBounds.maxX
        
        // Try centering on the data point
        let centerX = location.x
        
        // Check if tooltip would go outside right edge
        if centerX + tooltipWidth/2 > chartRight {
            return chartRight - tooltipWidth/2 - 10 // Pull it back from edge
        }
        
        // Check if tooltip would go outside left edge  
        if centerX - tooltipWidth/2 < chartLeft {
            return chartLeft + tooltipWidth/2 + 10 // Push it out from edge
        }
        
        // Center it
        return centerX
    }
    
    private func calculateTooltipY() -> CGFloat {
        let tooltipHeight: CGFloat = 60
        let chartTop = chartBounds.minY
        let chartBottom = chartBounds.maxY
        
        // Prefer positioning above the data point
        let aboveY = location.y - tooltipHeight/2 - 10
        
        // If above fits within bounds, use it
        if aboveY >= chartTop {
            return aboveY
        }
        
        // Otherwise position below
        let belowY = location.y + tooltipHeight/2 + 10
        
        // Make sure below also fits
        let finalY = min(belowY, chartBottom - tooltipHeight/2 - 10)
        
        return max(finalY, chartTop + tooltipHeight/2 + 10)
    }
}

// MARK: - Preview
#Preview {
    StatsView()
}