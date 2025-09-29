#if !os(macOS)
import UIKit
#endif
import SwiftUI
import SwiftData
import PhotosUI
import Charts
import UniformTypeIdentifiers

// MARK: - Time Range Types
enum TimeRange: String, CaseIterable {
    case week = "W"
    case month = "M"
    case sixMonths = "6M"
    case year = "Y"
    
    var days: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .sixMonths: return 180
        case .year: return 365
        }
    }
    
    var title: String { rawValue }
}

// MARK: - Time Range Control
struct TimeRangeControl: View {
    @Binding var selection: TimeRange
    
    var body: some View {
        Picker("", selection: $selection) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Text(range.title)
                    .tag(range)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }
}

// MARK: - Types and Constants
private let plevaType = UTType("com.pleva-tracker.diary-entries") ?? .json

// MARK: - File Document Structure
struct JSONFile: FileDocument {
    static var readableContentTypes: [UTType] { [UTType("com.pleva-tracker.diary-entries")!] }
    
    var text: String
    
    init(initialText: String? = nil) {
        text = initialText ?? ""
    }
    
    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            text = String(decoding: data, as: UTF8.self)
        } else {
            text = ""
        }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = Data(text.utf8)
        return FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - Export/Import Structures
struct ExportData: Codable {
    let version: Int
    let exportDate: Date
    let entries: [DiaryEntryExport]
}

struct DiaryEntryExport: Codable {
    let timestamp: Date
    let notes: String
    let severity: Int
    let location: String
    let weeklySummary: String?
    let summaryDate: Date?
    let papulesFace: Int
    let papulesNeck: Int
    let papulesChest: Int
    let papulesLeftArm: Int
    let papulesRightArm: Int
    let papulesBack: Int
    let papulesButtocks: Int
    let papulesLeftLeg: Int
    let papulesRightLeg: Int
    let photos: [Data]
    
    init(from entry: DiaryEntry) {
        self.timestamp = entry.timestamp
        self.notes = entry.notes
        self.severity = entry.severity
        self.location = entry.location
        self.weeklySummary = entry.weeklySummary
        self.summaryDate = entry.summaryDate
        self.papulesFace = entry.papulesFace
        self.papulesNeck = entry.papulesNeck
        self.papulesChest = entry.papulesChest
        self.papulesLeftArm = entry.papulesLeftArm
        self.papulesRightArm = entry.papulesRightArm
        self.papulesBack = entry.papulesBack
        self.papulesButtocks = entry.papulesButtocks
        self.papulesLeftLeg = entry.papulesLeftLeg
        self.papulesRightLeg = entry.papulesRightLeg
        self.photos = entry.photos
    }
    
    func toDiaryEntry() -> DiaryEntry {
        return DiaryEntry(
            timestamp: self.timestamp,
            notes: self.notes,
            severity: self.severity,
            photos: self.photos,
            location: self.location,
            weeklySummary: self.weeklySummary,
            summaryDate: self.summaryDate,
            papulesFace: self.papulesFace,
            papulesNeck: self.papulesNeck,
            papulesChest: self.papulesChest,
            papulesLeftArm: self.papulesLeftArm,
            papulesRightArm: self.papulesRightArm,
            papulesBack: self.papulesBack,
            papulesButtocks: self.papulesButtocks,
            papulesLeftLeg: self.papulesLeftLeg,
            papulesRightLeg: self.papulesRightLeg
        )
    }
}



// MARK: - Settings View
struct SettingsView: View {
    // MARK: - Properties
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var entries: [DiaryEntry]
    @State private var isTestingConnection = false
    @State private var testResult: String = "Not tested"
    @State private var showingExportSheet = false
    @State private var showingImportPicker = false
    @State private var importError: String?
    @State private var showingImportError = false
    @State private var isProcessing = false
    private let openAIService = OpenAIService()
    
    // MARK: - Computed Properties
    private var plistContents: [String: String] {
        let bundle = Bundle.main
        let keys = ["AZURE_OPENAI_KEY", "AZURE_OPENAI_ENDPOINT", "AZURE_OPENAI_DEPLOYMENT"]
        var contents: [String: String] = [:]
        
        for key in keys {
            if let value = bundle.object(forInfoDictionaryKey: key) as? String {
                // Mask sensitive data
                if key == "AZURE_OPENAI_KEY" {
                    let masked = String(value.prefix(8)) + "..." + String(value.suffix(4))
                    contents[key] = masked
                } else {
                    contents[key] = value
                }
            }
        }
        
        return contents
    }

    // MARK: - Methods
    private func exportEntries() {
        isProcessing = true
        
        Task {
            do {
                // Get unique entries by timestamp
                var uniqueEntries: [DiaryEntry] = []
                var seenTimestamps = Set<Date>()
                
                for entry in entries {
                    if !seenTimestamps.contains(entry.timestamp) {
                        uniqueEntries.append(entry)
                        seenTimestamps.insert(entry.timestamp)
                    }
                }
                
                // Convert unique entries to exportable format
                let exportEntries = uniqueEntries.map { DiaryEntryExport(from: $0) }
                
                let exportData = ExportData(
                    version: 1,
                    exportDate: Date(),
                    entries: exportEntries
                )
                
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                encoder.outputFormatting = .prettyPrinted
                let data = try encoder.encode(exportData)
                
                // Create a temporary file
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("PLEVA-Tracker-Export")
                    .appendingPathExtension("plevadiary")
                
                try data.write(to: tempURL)
                let totalPhotos = entries.reduce(0) { $0 + $1.photos.count }
                print("Export successful: \(entries.count) entries with \(totalPhotos) photos")
                
                await MainActor.run {
                    showingExportSheet = true
                    isProcessing = false
                    testResult = "Successfully exported \(entries.count) entries with \(totalPhotos) photos"
                }
            } catch {
                print("Export error: \(error)")
                await MainActor.run {
                    isProcessing = false
                    testResult = "Export failed: \(error.localizedDescription)"
                    showingImportError = true
                    importError = error.localizedDescription
                }
            }
        }
    }
    
    private func importEntries(from url: URL) {
        isProcessing = true
        
        Task {
            do {
                // Request file access permission
                guard url.startAccessingSecurityScopedResource() else {
                    throw NSError(domain: "com.pleva-tracker", 
                                code: 1, 
                                userInfo: [NSLocalizedDescriptionKey: "Permission denied to access file"])
                }
                
                defer {
                    // Ensure we release the security-scoped resource access
                    url.stopAccessingSecurityScopedResource()
                }
                
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                
                let importData = try decoder.decode(ExportData.self, from: data)
                
                // Get existing entries timestamps for duplicate checking
                let existingTimestamps = Set(entries.map { $0.timestamp })
                var importedCount = 0
                var duplicateCount = 0
                
                // Convert and import entries, skipping duplicates
                for exportEntry in importData.entries {
                    if !existingTimestamps.contains(exportEntry.timestamp) {
                        let entry = exportEntry.toDiaryEntry()
                        modelContext.insert(entry)
                        importedCount += 1
                    } else {
                        duplicateCount += 1
                    }
                }
            
                try modelContext.save()
            
                // Show success message with entry and photo counts
                let totalPhotos = importData.entries.reduce(0) { $0 + $1.photos.count }
                let statusMessage = "Imported \(importedCount) new entries" + 
                                  (duplicateCount > 0 ? " (skipped \(duplicateCount) duplicates)" : "")
                await MainActor.run {
                    testResult = statusMessage
                    isProcessing = false
                }
                print("\(statusMessage) with \(totalPhotos) photos")
            } catch {
                await MainActor.run {
                    importError = error.localizedDescription
                    showingImportError = true
                    isProcessing = false
                    testResult = "Import failed: \(error.localizedDescription)"
                }
                print("Import error: \(error)")
            }
        }
    }
    
    private func testConnection() {
        isTestingConnection = true
        testResult = "Testing..."
        
        Task {
            do {
                try await openAIService.testConnection()
                await MainActor.run {
                    testResult = "Connection successful"
                }
            } catch {
                await MainActor.run {
                    testResult = "Connection failed: \(error.localizedDescription)"
                }
            }
            
            await MainActor.run {
                isTestingConnection = false
            }
        }
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            Form {
                Section("Data Management") {
                    Button(action: exportEntries) {
                        HStack {
                            Label("Export All Entries", systemImage: "square.and.arrow.up")
                            if isProcessing {
                                Spacer()
                                ProgressView()
                                    .controlSize(.small)
                            }
                        }
                    }
                    .disabled(isProcessing)
                    
                    Button(action: { showingImportPicker = true }) {
                        HStack {
                            Label("Import Entries", systemImage: "square.and.arrow.down")
                            if isProcessing {
                                Spacer()
                                ProgressView()
                                    .controlSize(.small)
                            }
                        }
                    }
                    .disabled(isProcessing)
                    
                    if !testResult.isEmpty && testResult != "Not tested" && !testResult.contains("Connection") {
                        Text(testResult)
                            .foregroundStyle(
                                testResult.starts(with: "Successfully") ? .green : .red
                            )
                    }
                    
                    if let error = importError {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
                
                Section("Azure OpenAI Configuration") {
                    VStack(spacing: 8) {
                        Button(action: testConnection) {
                            HStack {
                                Text("Test Connection")
                                if isTestingConnection {
                                    Spacer()
                                    ProgressView()
                                }
                            }
                        }
                        .disabled(isTestingConnection)
                        
                        if testResult.contains("Connection") {
                            Text(testResult)
                                .foregroundStyle(
                                    testResult == "Connection successful" ? .green :
                                    testResult == "Testing..." ? .secondary : .red
                                )
                        }
                    }
                }
                
                Section("Changelog") {
                    VStack(alignment: .leading, spacing: 8) {
                        Group {
                            Text("Version 1.0.5")
                                .font(.headline)
                            
                            Text("September 13, 2025")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Latest Updates:")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    ForEach([
                                        "Enhanced entry date/time editing",
                                        "Improved import/export handling",
                                        "Code optimization and cleanup",
                                        "Fixed various UI issues"
                                    ], id: \.self) { feature in
                                        HStack(alignment: .top, spacing: 4) {
                                            Text("•")
                                            Text(feature)
                                        }
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.top, 4)
                            }
                        }
                        .padding(.bottom, 16)
                        
                        Group {
                            Text("Version 1.0.1")
                                .font(.headline)
                            
                            Text("March 24, 2025")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("New Features:")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    ForEach([
                                        "Detailed papule count tracking by body region",
                                        "Total papule count in entry list",
                                        "Keyboard-optimized numeric inputs"
                                    ], id: \.self) { feature in
                                        HStack(alignment: .top, spacing: 4) {
                                            Text("•")
                                            Text(feature)
                                        }
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.top, 4)
                            }
                        }
                        .padding(.bottom, 16)
                        
                        Group {
                            Text("Version 1.0.0")
                                .font(.headline)
                            
                            Text("Initial Release - March 7, 2025")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Initial Features:")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    ForEach([
                                        "Weekly calendar view",
                                        "Entry creation and editing",
                                        "Photo attachments",
                                        "Severity tracking (1-5)",
                                        "Weekly AI summaries",
                                        "Location tracking"
                                    ], id: \.self) { feature in
                                        HStack(alignment: .top, spacing: 4) {
                                            Text("•")
                                            Text(feature)
                                        }
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.top, 4)
                            }
                        }
                    }
                }
                
                Section("Configuration Values") {
                    ForEach(Array(plistContents.keys.sorted()), id: \.self) { key in
                        if let value = plistContents[key] {
                            VStack(alignment: .leading) {
                                Text(key)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(value)
                                    .font(.callout)
                            }
                        }
                    }
                }
                
                Section("About") {
                    Text("PLEVA Diary")
                        .foregroundStyle(.secondary)
                    Text("Version 1.0")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .fileExporter(
                isPresented: $showingExportSheet,
                document: JSONFile(
                    initialText: try? String(
                        contentsOf: FileManager.default.temporaryDirectory
                            .appendingPathComponent("PLEVA-Tracker-Export")
                            .appendingPathExtension("plevadiary")
                    )
                ),
                contentType: plevaType,
                defaultFilename: "PLEVA-Tracker-Export-\(Date().formatted(.iso8601))"
            ) { result in
                if case .failure(let error) = result {
                    print("Export error: \(error)")
                }
            }
            .fileImporter(
                isPresented: $showingImportPicker,
                allowedContentTypes: [plevaType],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        importEntries(from: url)
                    }
                case .failure(let error):
                    importError = error.localizedDescription
                    showingImportError = true
                }
            }
            .alert("Import Error", isPresented: $showingImportError, actions: {
                Button("OK", role: .cancel) { }
            }, message: {
                Text(importError ?? "Unknown error")
            })
        }
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DiaryEntry.timestamp, order: .reverse) private var entries: [DiaryEntry]
    @State private var selectedItem: PhotosPickerItem?
    @State private var timeRange: TimeRange = .week
    @State private var showingEntrySheet = false
    @State private var showingImageViewer = false
    @State private var selectedEntry: DiaryEntry?
    @State private var weeklySummary: String = "Tap 'Generate Summary' to analyze this entries"
    @State private var isGeneratingSummary = false
    @State private var showingSettings = false
    @State private var currentWeek: Date
    @State private var isWeeklySummaryExpanded = false
    @State private var selectedDate: Date
    private let openAIService = OpenAIService()
    
    init() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        _selectedDate = State(initialValue: today)
        _currentWeek = State(initialValue: today)
    }
    
    private var filteredEntries: [DiaryEntry] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -timeRange.days, to: Date())!
        let filtered = entries.filter { $0.timestamp >= startDate }
        print("Total entries: \(entries.count), Filtered entries for \(timeRange.title): \(filtered.count)")
        return filtered
    }
    
    private func handleTimeRangeChange(_ newRange: TimeRange) {
        timeRange = newRange
        generateWeeklySummary() // Regenerate summary for the new time range
    }
    
    private func handleDaySelected(_ date: Date) {
        selectedDate = date
        // Look for an entry on the exact date
        selectedEntry = entries.first { Calendar.current.isDate($0.timestamp, inSameDayAs: date) }
        showingEntrySheet = true
    }
    
    private func handleWeekChange(_ newDate: Date) {
        withAnimation {
            currentWeek = newDate
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Time Range Control
                            TimeRangeControl(selection: $timeRange)
                                .padding(.top)
                            
                            // Weekly Summary Section
                            WeeklySummaryView(
                                isExpanded: $isWeeklySummaryExpanded,
                                summary: weeklySummary,
                                isGenerating: isGeneratingSummary,
                                hasEntries: !filteredEntries.isEmpty,
                                onGenerate: generateWeeklySummary
                            )
                            
                            // Trend Chart
                            TrendChart(entries: entries, timeRange: timeRange)
                                .padding(.horizontal)
                        }
                    }
                    .frame(maxHeight: 500)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
                
                // Entries section
                ForEach(entries) { entry in
                    EntryRowView(entry: entry)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .onTapGesture {
                            selectedDate = entry.timestamp // Use the tapped entry's timestamp
                            selectedEntry = entry // Directly use the tapped entry
                            showingEntrySheet = true
                        }
                }
                .onDelete(perform: deleteEntries)
            }
            .listStyle(.insetGrouped)
            .navigationTitle("PLEVA Diary")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gear")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Get the start of today
                        let calendar = Calendar.current
                        let today = calendar.startOfDay(for: Date())
                        
                        selectedEntry = nil
                        selectedDate = today
                        showingEntrySheet = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.blue)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background {
                Color(uiColor: .systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
            }
            .edgesIgnoringSafeArea(.bottom)
            .sheet(isPresented: $showingEntrySheet) {
                NavigationStack {
                    EntryFormView(entry: selectedEntry, selectedDate: selectedDate)
                        .navigationTitle(selectedEntry == nil ? "New Entry" : "Edit Entry")
                        .navigationBarTitleDisplayMode(.inline)
                        .background(Color(uiColor: .systemGroupedBackground))
                }
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
    
    private func generateWeeklySummary() {
        guard !filteredEntries.isEmpty else {
            print("No entries found for selected time range")
            return
        }
        
        print("Generating summary for \(filteredEntries.count) entries")
        isGeneratingSummary = true
        Task {
            do {
                let summary = try await openAIService.generateWeeklySummary(from: filteredEntries)
                await MainActor.run {
                    weeklySummary = summary
                    isGeneratingSummary = false
                    
                    // Store the summary in the latest entry
                    if let latestEntry = filteredEntries.first {
                        print("Storing summary in latest entry from \(latestEntry.timestamp)")
                        latestEntry.weeklySummary = summary
                        latestEntry.summaryDate = Date()
                    }
                }
            } catch {
                await MainActor.run {
                    print("Error generating summary: \(error)")
                    weeklySummary = "Error generating summary: \(error.localizedDescription)"
                    isGeneratingSummary = false
                }
            }
        }
    }
    
    private func deleteEntries(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(entries[index])
            }
        }
    }
}

struct WeeklySummaryView: View {
    @Binding var isExpanded: Bool
    let summary: String
    let isGenerating: Bool
    let hasEntries: Bool
    let onGenerate: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Weekly Summary")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }) {
                    Label(
                        isExpanded ? "Collapse" : "Expand",
                        systemImage: isExpanded ? "chevron.up" : "chevron.down"
                    )
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.blue)
                }
            }
            .padding(.horizontal)
            
            if isExpanded || summary == "Tap 'Generate Summary' to analyze this week's entries" {
                Text(summary)
                    .font(.subheadline)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                
                Button(action: onGenerate) {
                    HStack {
                        Text("Generate Summary")
                        if isGenerating {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                }
                .disabled(isGenerating || !hasEntries)
                .buttonStyle(.bordered)
                .padding(.horizontal)
            }
        }
    }
}

struct SeverityBadgeView: View {
    let severity: Int
    
    var color: Color {
        switch severity {
        case 1: return .green
        case 2: return .mint
        case 3: return .yellow
        case 4: return .orange
        case 5: return .red
        default: return .gray
        }
    }
    
    var body: some View {
        Text("\(severity)")
            .font(.caption.bold())
            .padding(6)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .clipShape(Circle())
    }
}

struct EntryRowView: View {
    let entry: DiaryEntry
    
    private var totalPapuleCount: Int {
        entry.papulesFace +
        entry.papulesNeck +
        entry.papulesChest +
        entry.papulesLeftArm +
        entry.papulesRightArm +
        entry.papulesBack +
        entry.papulesButtocks +
        entry.papulesLeftLeg +
        entry.papulesRightLeg
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.headline)
                Text(entry.location)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if (!entry.notes.isEmpty) {
                    Text(entry.notes)
                        .lineLimit(2)
                        .font(.subheadline)
                }
            }
            
            Spacer()
            
            if totalPapuleCount > 0 {
                Text("\(totalPapuleCount) papules")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.trailing, 8)
            }
            
            SeverityBadgeView(severity: entry.severity)
            
            if !entry.photos.isEmpty {
                HStack(spacing: 2) {
                    Image(systemName: "photo.fill")
                    Text("\(entry.photos.count)")
                        .font(.caption)
                }
                .foregroundStyle(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}

struct PhotoGalleryView: View {
    let photos: [Data]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                ForEach(photos.indices, id: \.self) { index in
                    if let uiImage = UIImage(data: photos[index]) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct EntryFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let entry: DiaryEntry?
    let selectedDate: Date
    
    @State private var notes: String = ""
    @State private var severity: Int = 1
    @State private var location: String = ""
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var photosData: [Data] = []
    @State private var showingDeleteConfirmation = false
    @State private var papulesFace: Int = 0
    @State private var papulesNeck: Int = 0
    @State private var papulesChest: Int = 0
    @State private var papulesLeftArm: Int = 0
    @State private var papulesRightArm: Int = 0
    @State private var papulesBack: Int = 0
    @State private var papulesButtocks: Int = 0
    @State private var papulesLeftLeg: Int = 0
    @State private var papulesRightLeg: Int = 0
    @State private var entryDate: Date
    @FocusState private var focusedField: String?
    
    init(entry: DiaryEntry?, selectedDate: Date) {
        self.entry = entry
        self.selectedDate = selectedDate
        // Initialize the date state with either the entry's timestamp or selected date
        _entryDate = State(initialValue: entry?.timestamp ?? selectedDate)
    }
    
    var body: some View {
        Form {
            Section("Date and Time") {
                DatePicker(
                    "Entry Date",
                    selection: $entryDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
            }
            
            Section("Notes") {
                TextEditor(text: $notes)
                    .frame(height: 100)
            }
            
            Section("Location") {
                TextField("Body location", text: $location)
            }
            
            Section("Severity (1-5)") {
                Picker("Severity", selection: $severity) {
                    ForEach(1...5, id: \.self) { level in
                        Text("\(level)").tag(level)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            Section("Photos") {
                PhotosPicker(selection: $selectedPhotos,
                           maxSelectionCount: 30,
                           matching: .images) {
                    HStack {
                        Image(systemName: "photo.badge.plus")
                        Text(photosData.isEmpty ? "Add Photos" : "Add More Photos")
                    }
                }
                
                if !photosData.isEmpty {
                    PhotoGalleryView(photos: photosData)
                        .frame(height: 120)
                }
            }
            
            Section("Papule Count") {
                PapuleCountView(title: "Face", count: $papulesFace, id: "face", focusedField: _focusedField.projectedValue)
                PapuleCountView(title: "Neck", count: $papulesNeck, id: "neck", focusedField: _focusedField.projectedValue)
                PapuleCountView(title: "Chest", count: $papulesChest, id: "chest", focusedField: _focusedField.projectedValue)
                PapuleCountView(title: "Left Arm", count: $papulesLeftArm, id: "leftArm", focusedField: _focusedField.projectedValue)
                PapuleCountView(title: "Right Arm", count: $papulesRightArm, id: "rightArm", focusedField: _focusedField.projectedValue)
                PapuleCountView(title: "Back", count: $papulesBack, id: "back", focusedField: _focusedField.projectedValue)
                PapuleCountView(title: "Buttocks", count: $papulesButtocks, id: "buttocks", focusedField: _focusedField.projectedValue)
                PapuleCountView(title: "Left Leg", count: $papulesLeftLeg, id: "leftLeg", focusedField: _focusedField.projectedValue)
                PapuleCountView(title: "Right Leg", count: $papulesRightLeg, id: "rightLeg", focusedField: _focusedField.projectedValue)
            }
            
            if entry != nil {
                Section {
                    Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                        Text("Delete Entry")
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveEntry()
                    dismiss()
                }
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
            }
        }
        .onAppear {
            if let entry = entry {
                notes = entry.notes
                severity = entry.severity
                location = entry.location
                photosData = entry.photos
                papulesFace = entry.papulesFace
                papulesNeck = entry.papulesNeck
                papulesChest = entry.papulesChest
                papulesLeftArm = entry.papulesLeftArm
                papulesRightArm = entry.papulesRightArm
                papulesBack = entry.papulesBack
                papulesButtocks = entry.papulesButtocks
                papulesLeftLeg = entry.papulesLeftLeg
                papulesRightLeg = entry.papulesRightLeg
            }
        }
        .onChange(of: selectedPhotos) { oldValue, newValue in
            Task {
                var newPhotosData: [Data] = []
                for item in selectedPhotos {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        newPhotosData.append(data)
                    }
                }
                photosData.append(contentsOf: newPhotosData)
            }
        }
        .alert("Delete Entry", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let entry = entry {
                    modelContext.delete(entry)
                    dismiss()
                }
            }
        }
    }
    
    func saveEntry() {
        if let entry = entry {
            // Update existing entry
            entry.timestamp = entryDate
            entry.notes = notes
            entry.severity = severity
            entry.location = location
            entry.photos = photosData
            entry.papulesFace = papulesFace
            entry.papulesNeck = papulesNeck
            entry.papulesChest = papulesChest
            entry.papulesLeftArm = papulesLeftArm
            entry.papulesRightArm = papulesRightArm
            entry.papulesBack = papulesBack
            entry.papulesButtocks = papulesButtocks
            entry.papulesLeftLeg = papulesLeftLeg
            entry.papulesRightLeg = papulesRightLeg
        } else {
            // Create new entry using the date picker's selected date and time
            let timestamp = entryDate
            
            let newEntry = DiaryEntry(
                timestamp: timestamp,
                notes: notes,
                severity: severity,
                photos: photosData,
                location: location,
                papulesFace: papulesFace,
                papulesNeck: papulesNeck,
                papulesChest: papulesChest,
                papulesLeftArm: papulesLeftArm,
                papulesRightArm: papulesRightArm,
                papulesBack: papulesBack,
                papulesButtocks: papulesButtocks,
                papulesLeftLeg: papulesLeftLeg,
                papulesRightLeg: papulesRightLeg
            )
            modelContext.insert(newEntry)
        }
    }
}

struct PapuleCountView: View {
    let title: String
    @Binding var count: Int
    let id: String
    var focusedField: FocusState<String?>.Binding
    
    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.zeroSymbol = ""
        return formatter
    }()
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            TextField("", value: $count, formatter: Self.numberFormatter)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 60)
                .textFieldStyle(.roundedBorder)
                .focused(focusedField, equals: id)
                .tag(id)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: DiaryEntry.self, inMemory: true)
}
