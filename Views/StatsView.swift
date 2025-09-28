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
    
    private var settingsManager = SettingsManager.shared
    
    private var recentAccuracy: String {
        guard let mostRecent = chartData.last else { return "No data" }
        return "\(String(format: "%.1f%%", mostRecent.accuracy * 100))"
    }
    
    private var changeFromLastSession: String {
        guard chartData.count >= 2 else { return "No comparison" }
        let current = chartData.last!.accuracy
        let previous = chartData[chartData.count - 2].accuracy
        let change = current - previous
        let changePercent = change * 100
        
        if change > 0 {
            return "+\(String(format: "%.1f%%", changePercent))"
        } else if change < 0 {
            return "\(String(format: "%.1f%%", changePercent))"
        } else {
            return "0.0%"
        }
    }
    
    private var comparisonToTarget: String {
        guard let mostRecent = chartData.last else { return "No data" }
        let current = mostRecent.accuracy
        let target = settingsManager.chartTargetAccuracy
        let difference = current - target
        let differencePercent = difference * 100
        
        if difference > 0 {
            return "+\(String(format: "%.1f%%", differencePercent))"
        } else if difference < 0 {
            return "\(String(format: "%.1f%%", differencePercent))"
        } else {
            return "On target"
        }
    }
    
    private var changeFromLastSessionColor: Color {
        guard chartData.count >= 2 else { return .secondary }
        let current = chartData.last!.accuracy
        let previous = chartData[chartData.count - 2].accuracy
        let change = current - previous
        
        if change > 0 {
            return .green
        } else if change < 0 {
            return .red
        } else {
            return .blue
        }
    }
    
    private var comparisonToTargetColor: Color {
        guard let mostRecent = chartData.last else { return .secondary }
        let current = mostRecent.accuracy
        let target = settingsManager.chartTargetAccuracy
        let difference = current - target
        
        if difference > 0 {
            return .green
        } else if difference < 0 {
            return .red
        } else {
            return .blue
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
                VStack(alignment: .leading, spacing: 4) {
                    Text("Accuracy Trend")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    // Three summary values
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Most Recent")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(recentAccuracy)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("vs Last Session")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(changeFromLastSession)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(changeFromLastSessionColor)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("vs Target")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(comparisonToTarget)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(comparisonToTargetColor)
                        }
                    }
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
                VStack(spacing: 8) {
                    SparkLineChartView(
                        chartData: chartData,
                        targetAccuracy: settingsManager.chartTargetAccuracy
                    )
                    .frame(height: 120)
                    
                    // Date labels
                    if !chartData.isEmpty {
                        HStack {
                            Text(formattedDate(chartData.first?.date))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            if chartData.count > 2 {
                                Text(formattedDate(chartData[chartData.count / 2].date))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(formattedDate(chartData.last?.date))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 8)
                    }
                    
                    // Legend
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                            Text("Improving")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 6, height: 6)
                            Text("Declining")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 6, height: 6)
                            Text("Stable")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Rectangle()
                                .fill(Color.green)
                                .frame(width: 12, height: 2)
                            Text("Trend")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 8)
                }
                .padding(.vertical, 8)
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

// MARK: - Spark Line Chart
struct SparkLineChartView: View {
    let chartData: [ChartDataPoint]
    let targetAccuracy: Double
    @State private var animationProgress: CGFloat = 0
    
    // Dynamic Y-axis scaling based on data range
    private var dataMin: Double {
        guard !chartData.isEmpty else { return 0.0 }
        let minValue = chartData.map { $0.accuracy }.min() ?? 0.0
        // Add 5% padding below minimum
        return max(0.0, minValue - (minValue * 0.05))
    }
    
    private var dataMax: Double {
        guard !chartData.isEmpty else { return 1.0 }
        let maxValue = chartData.map { $0.accuracy }.max() ?? 1.0
        // Add 5% padding above maximum
        return min(1.0, maxValue + (maxValue * 0.05))
    }
    
    private var dataRange: Double {
        return dataMax - dataMin
    }
    
    // Calculate moving average for smoother trend visualization
    private var movingAverageData: [Double] {
        guard chartData.count >= 3 else { return chartData.map { $0.accuracy } }
        
        var smoothed: [Double] = []
        for i in 0..<chartData.count {
            let start = max(0, i - 1)
            let end = min(chartData.count - 1, i + 1)
            let window = chartData[start...end]
            let average = window.map { $0.accuracy }.reduce(0, +) / Double(window.count)
            smoothed.append(average)
        }
        return smoothed
    }
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            
            ZStack {
                // Background with subtle grid
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
                
                if chartData.count > 1 {
                    // Target line (subtle)
                    targetLine(width: width, height: height)
                    
                    // Area fill under the curve for better trend visualization
                    areaFill(width: width, height: height)
                    
                    // Moving average line (smooth trend)
                    movingAverageLine(width: width, height: height)
                    
                    // Main data points with trend indicators
                    dataPoints(width: width, height: height)
                    
                    // Current value indicator
                    currentValueIndicator(width: width, height: height)
                    
                    // Y-axis labels showing data range
                    yAxisLabels(width: width, height: height)
                } else if chartData.count == 1 {
                    // Single data point - show as a dot
                    singleDataPoint(width: width, height: height)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2)) {
                animationProgress = 1.0
            }
        }
    }
    
    private func targetLine(width: CGFloat, height: CGFloat) -> some View {
        Path { path in
            // Scale target line to fit within data range
            let normalizedTarget = (targetAccuracy - dataMin) / dataRange
            let y = height * (1 - CGFloat(normalizedTarget))
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: width, y: y))
        }
        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
    }
    
    private func areaFill(width: CGFloat, height: CGFloat) -> some View {
        Path { path in
            guard !chartData.isEmpty else { return }
            
            // Start from bottom of data range
            let firstX = 0.0
            let bottomY = height * (1 - CGFloat((0 - dataMin) / dataRange))
            path.move(to: CGPoint(x: firstX, y: bottomY))
            
            // Draw line to first data point
            let firstDataPoint = chartData[0]
            let firstDataX = width * CGFloat(0) / CGFloat(max(chartData.count - 1, 1)) * animationProgress
            let normalizedFirstY = (firstDataPoint.accuracy - dataMin) / dataRange
            let firstDataY = height * (1 - CGFloat(normalizedFirstY))
            path.addLine(to: CGPoint(x: firstDataX, y: firstDataY))
            
            // Draw curve through all data points
            for (index, dataPoint) in chartData.enumerated() {
                let x = width * CGFloat(index) / CGFloat(max(chartData.count - 1, 1)) * animationProgress
                let normalizedY = (dataPoint.accuracy - dataMin) / dataRange
                let y = height * (1 - CGFloat(normalizedY))
                path.addLine(to: CGPoint(x: x, y: y))
            }
            
            // Close the path back to bottom
            let lastX = width * animationProgress
            path.addLine(to: CGPoint(x: lastX, y: bottomY))
            path.closeSubpath()
        }
        .fill(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.3),
                    Color.blue.opacity(0.1),
                    Color.clear
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private func movingAverageLine(width: CGFloat, height: CGFloat) -> some View {
        Path { path in
            guard movingAverageData.count > 1 else { return }
            
            var isFirst = true
            for (index, accuracy) in movingAverageData.enumerated() {
                let x = width * CGFloat(index) / CGFloat(max(movingAverageData.count - 1, 1)) * animationProgress
                let normalizedY = (accuracy - dataMin) / dataRange
                let y = height * (1 - CGFloat(normalizedY))
                
                if isFirst {
                    path.move(to: CGPoint(x: x, y: y))
                    isFirst = false
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
        }
        .stroke(
            LinearGradient(
                gradient: Gradient(colors: [.green, .green.opacity(0.7)]),
                startPoint: .leading,
                endPoint: .trailing
            ),
            lineWidth: 2
        )
        .shadow(color: .green.opacity(0.3), radius: 1, x: 0, y: 0)
    }
    
    private func dataPoints(width: CGFloat, height: CGFloat) -> some View {
        ForEach(Array(chartData.enumerated()), id: \.offset) { index, dataPoint in
            let x = width * CGFloat(index) / CGFloat(max(chartData.count - 1, 1)) * animationProgress
            let normalizedY = (dataPoint.accuracy - dataMin) / dataRange
            let y = height * (1 - CGFloat(normalizedY))
            
            // Determine color based on trend
            let color = getTrendColor(for: index)
            
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [color, color.opacity(0.7)]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 3
                    )
                )
                .frame(width: 6, height: 6)
                .position(x: x, y: y)
                .shadow(color: color.opacity(0.4), radius: 2, x: 0, y: 0)
                .scaleEffect(animationProgress)
                .opacity(animationProgress)
        }
    }
    
    private func getTrendColor(for index: Int) -> Color {
        guard index > 0 else { return .blue }
        
        let current = chartData[index].accuracy
        let previous = chartData[index - 1].accuracy
        
        if current > previous {
            return .green // Improving
        } else if current < previous {
            return .red // Declining
        } else {
            return .blue // Stable
        }
    }
    
    private func currentValueIndicator(width: CGFloat, height: CGFloat) -> some View {
        guard let lastDataPoint = chartData.last else { return AnyView(EmptyView()) }
        
        let x = width * animationProgress
        let normalizedY = (lastDataPoint.accuracy - dataMin) / dataRange
        let y = height * (1 - CGFloat(normalizedY))
        
        return AnyView(
            ZStack {
                // Outer ring
                Circle()
                    .stroke(Color.blue, lineWidth: 2)
                    .frame(width: 12, height: 12)
                    .position(x: x, y: y)
                    .scaleEffect(animationProgress)
                    .opacity(animationProgress)
                
                // Inner dot
                Circle()
                    .fill(Color.blue)
                    .frame(width: 6, height: 6)
                    .position(x: x, y: y)
                    .scaleEffect(animationProgress)
                    .opacity(animationProgress)
            }
            .shadow(color: .blue.opacity(0.6), radius: 4, x: 0, y: 0)
        )
    }
    
    private func yAxisLabels(width: CGFloat, height: CGFloat) -> some View {
        VStack {
            // Top label (max value)
            HStack {
                Spacer()
                Text("\(String(format: "%.1f%%", dataMax * 100))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.trailing, 8)
            }
            
            Spacer()
            
            // Bottom label (min value)
            HStack {
                Spacer()
                Text("\(String(format: "%.1f%%", dataMin * 100))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.trailing, 8)
            }
        }
        .frame(width: width, height: height)
    }
    
    private func singleDataPoint(width: CGFloat, height: CGFloat) -> some View {
        let dataPoint = chartData[0]
        let x = width / 2
        let normalizedY = (dataPoint.accuracy - dataMin) / dataRange
        let y = height * (1 - CGFloat(normalizedY))
        
        return Circle()
            .fill(
                RadialGradient(
                    gradient: Gradient(colors: [.blue, .blue.opacity(0.7)]),
                    center: .center,
                    startRadius: 0,
                    endRadius: 4
                )
            )
            .frame(width: 8, height: 8)
            .position(x: x, y: y)
            .shadow(color: .blue.opacity(0.4), radius: 2, x: 0, y: 0)
            .scaleEffect(animationProgress)
            .opacity(animationProgress)
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