import SwiftUI
import Charts

struct WeeklyTrendChart: View {
    let entries: [DiaryEntry]
    
    private struct WeeklyData: Identifiable {
        let weekStart: Date
        let averageCount: Double
        var id: Date { weekStart }
    }
    
    private var weeklyAverages: [WeeklyData] {
        let calendar = Calendar.current
        let today = Date()
        let twelveWeeksAgo = calendar.date(byAdding: .weekOfYear, value: -12, to: today) ?? today
        
        print("WeeklyTrendChart: Total number of entries: \(entries.count)")
        print("WeeklyTrendChart: Date range - From: \(twelveWeeksAgo.formatted()) To: \(today.formatted())")
        
        // Create an array of all week starts
        var allWeekStarts: [Date] = []
        var currentDate = twelveWeeksAgo
        
        while currentDate <= today {
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: currentDate)) ?? currentDate
            let alreadyExists = allWeekStarts.contains {
                calendar.isDate($0, equalTo: weekStart, toGranularity: .weekOfYear)
            }
            if !alreadyExists {
                allWeekStarts.append(weekStart)
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        // Group entries by week
        var weeklyGroups: [Date: [Int]] = [:]
        
        // Initialize all weeks with empty arrays
        for weekStart in allWeekStarts {
            weeklyGroups[weekStart] = []
        }
        
        // Count entries within the time window
        let entriesInTimeWindow = entries.filter { $0.timestamp >= twelveWeeksAgo }
        print("WeeklyTrendChart: Entries in 12-week window: \(entriesInTimeWindow.count)")
        
        // Process entries and group them by week
        for entry in entries {
            if entry.timestamp < twelveWeeksAgo {
                print("WeeklyTrendChart: Skipping entry from \(entry.timestamp.formatted()) - outside time window")
                continue
            }
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: entry.timestamp)) ?? entry.timestamp
            
            // Calculate total papules for different body regions
            let upperBodyCount = entry.papulesFace +
                               entry.papulesNeck +
                               entry.papulesChest +
                               entry.papulesLeftArm +
                               entry.papulesRightArm +
                               entry.papulesBack
            
            let lowerBodyCount = entry.papulesButtocks +
                               entry.papulesLeftLeg +
                               entry.papulesRightLeg
            
            let totalCount = upperBodyCount + lowerBodyCount
            
            if weeklyGroups[weekStart] != nil {
                weeklyGroups[weekStart]?.append(totalCount)
            } else {
                weeklyGroups[weekStart] = [totalCount]
            }
        }
        
        // Calculate weekly averages
        let weeklyData = allWeekStarts.map { weekStart in
            let counts = weeklyGroups[weekStart] ?? []
            let sum = counts.reduce(0, +)
            let average = counts.isEmpty ? 0.0 : Double(sum) / Double(counts.count)
            print("WeeklyTrendChart: Week of \(weekStart.formatted()): Count=\(counts.count), Average=\(average)")
            return WeeklyData(weekStart: weekStart, averageCount: average)
        }.sorted { $0.weekStart > $1.weekStart } // Sort in reverse chronological order
        
        print("WeeklyTrendChart: Generated \(weeklyData.count) weekly data points")
        return weeklyData
    }
    
    private var chartContent: some View {
        Chart(weeklyAverages) { weekData in
            LineMark(
                x: .value("Week", weekData.weekStart),
                y: .value("Average Count", max(0.1, weekData.averageCount))
            )
            .interpolationMethod(.catmullRom)
            
            PointMark(
                x: .value("Week", weekData.weekStart),
                y: .value("Average Count", max(0.1, weekData.averageCount))
            )
            
            RuleMark(
                x: .value("Week", weekData.weekStart),
                yStart: .value("Start", max(0.1, weekData.averageCount)),
                yEnd: .value("End", max(0.1, weekData.averageCount))
            )
            .annotation(position: .top) {
                Text(String(format: "%.1f", weekData.averageCount))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .weekOfYear)) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(date.formatted(.dateTime.month().day()))
                            .font(.caption2)
                    }
                }
            }
        }
    }
    
    private var chartView: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            chartContent
                .frame(width: max(UIScreen.main.bounds.width, CGFloat(weeklyAverages.count) * 80))
                .frame(height: 200)
                .padding()
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Weekly Papule Count Trends")
                .font(.headline)
                .padding(.horizontal)
            
            if weeklyAverages.isEmpty {
                Text("No data for the last 12 weeks")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                Text("Scroll horizontally to view historical data")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                
                chartView
            }
        }
        .background(Color.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
