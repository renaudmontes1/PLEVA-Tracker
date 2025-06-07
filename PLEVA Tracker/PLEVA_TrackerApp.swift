//
//  PLEVA_TrackerApp.swift
//  PLEVA Tracker
//
//  Created by Renaud Montes on 3/27/25.
//

import SwiftUI
import SwiftData

@main
struct PLEVA_TrackerApp: App {
    let container: ModelContainer
        
    init() {
        do {
            let schema = Schema([DiaryEntry.self])
            let modelConfiguration = ModelConfiguration(schema: schema)
            container = try ModelContainer(for: schema, migrationPlan: nil, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not configure SwiftData container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
                .ignoresSafeArea(.keyboard)
                .environment(\.colorScheme, .light)
                .environment(\.defaultMinListRowHeight, 0)
        }
    }
}
