import SwiftUI
import Charts

// Custom axis content
private struct CustomDateLabel: View {
    let date: Date
    let timeRange: TimeRange
    
    var body: some View {
        let text = timeRange == .week || timeRange == .month ?
            date.formatted(.dateTime.month().day()) :
            date.formatted(.dateTime.month().year())
        
        Text(text)
            .foregroundStyle(.secondary)
            .font(.caption2)
    }
}

struct TrendChart: View {
    let entries: [DiaryEntry]
    let timeRange: TimeRange
    
    private struct ChartData: Identifiable {
        let date: Date
        let averageCount: Double
        var id: Date { date }
    }
    
    private var chartData: [ChartData] {
        let calendar = Calendar.current
        let today = Date()
        let startDate = calendar.date(byAdding: .day, value: -timeRange.days, to: today) ?? today
        
        print("TrendChart: Total number of entries: \(entries.count)")
        print("TrendChart: Date range - From: \(startDate.formatted()) To: \(today.formatted())")
        
        var datePeriods: [Date] = []
        var currentDate = startDate
        
        // Create date periods based on the selected time range
        let periodInterval: Calendar.Component
        let periodValue: Int
        
        switch timeRange {
        case .week:
            periodInterval = .day
            periodValue = 1
        case .month:
            periodInterval = .day
            periodValue = 1
        case .sixMonths:
            periodInterval = .weekOfYear
            periodValue = 1
        case .year:
            periodInterval = .month
            periodValue = 1
        }
        
        while currentDate <= today {
            datePeriods.append(currentDate)
            currentDate = calendar.date(byAdding: periodInterval, value: periodValue, to: currentDate) ?? currentDate
        }
        
        // Group entries by period
        var periodGroups: [Date: [Int]] = [:]
        
        // Initialize all periods with empty arrays
        for periodStart in datePeriods {
            periodGroups[periodStart] = []
        }
        
        // Count entries within the time window
        let entriesInTimeWindow = entries.filter { $0.timestamp >= startDate }
        print("TrendChart: Entries in time window: \(entriesInTimeWindow.count)")
        
        // Process entries and group them by period
        for entry in entries {
            if entry.timestamp < startDate {
                print("TrendChart: Skipping entry from \(entry.timestamp.formatted()) - outside time window")
                continue
            }
            
            // Find the appropriate period for this entry
            let periodStart = datePeriods.last { date in
                entry.timestamp >= date
            } ?? startDate
            
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
            
            if periodGroups[periodStart] != nil {
                periodGroups[periodStart]?.append(totalCount)
            } else {
                periodGroups[periodStart] = [totalCount]
            }
        }
        
        // Calculate period averages
        return datePeriods.map { periodStart in
            let counts = periodGroups[periodStart] ?? []
            let sum = counts.reduce(0, +)
            let average = counts.isEmpty ? 0.0 : Double(sum) / Double(counts.count)
            print("TrendChart: Period of \(periodStart.formatted()): Count=\(counts.count), Average=\(average)")
            return ChartData(date: periodStart, averageCount: average)
        }.sorted { $0.date < $1.date } // Sort in chronological order (oldest to newest)
    }
    
    private var chartContent: some View {
        Chart(chartData) { data in
            LineMark(
                x: .value("Date", data.date),
                y: .value("Average Count", max(0.1, data.averageCount))
            )
            .foregroundStyle(.blue)
            .interpolationMethod(.catmullRom)
            
            PointMark(
                x: .value("Date", data.date),
                y: .value("Average Count", max(0.1, data.averageCount))
            )
            .foregroundStyle(.blue)
            
            if data.averageCount > 0 {
                RuleMark(
                    x: .value("Date", data.date),
                    yStart: .value("Start", max(0.1, data.averageCount)),
                    yEnd: .value("End", max(0.1, data.averageCount))
                )
                .annotation(position: .top) {
                    Text(String(format: "%.1f", data.averageCount))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .chartXAxis {
            let format = timeRange == .week || timeRange == .month ?
                Date.FormatStyle().month().day() :
                Date.FormatStyle().month().year()
                
            AxisMarks { value in
                if let date = value.as(Date.self) {
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        Text(date.formatted(format))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
    
    private var chartView: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: true) {
                HStack(spacing: 0) {
                    chartContent
                        .frame(width: max(UIScreen.main.bounds.width, CGFloat(chartData.count) * 80))
                        .frame(height: 200)
                        .padding()
                    
                    // Add an invisible anchor at the end to scroll to
                    Color.clear
                        .frame(width: 1, height: 1)
                        .id("trailingEdge")
                }
            }
            .onAppear {
                // Scroll to the trailing edge (latest data) when the view appears
                scrollToLatest(proxy: proxy)
            }
            .onChange(of: timeRange) { oldValue, newValue in
                // Scroll to the trailing edge when time range changes
                scrollToLatest(proxy: proxy)
            }
            .onChange(of: chartData.count) { oldValue, newValue in
                // Scroll to the trailing edge when data changes
                scrollToLatest(proxy: proxy)
            }
        }
    }
    
    private func scrollToLatest(proxy: ScrollViewProxy) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeOut(duration: 0.3)) {
                proxy.scrollTo("trailingEdge", anchor: .trailing)
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(timeRange.rawValue) Papule Count Trends")
                .font(.headline)
                .padding(.horizontal)
            
            if chartData.isEmpty {
                Text("No data for the selected time range")
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
