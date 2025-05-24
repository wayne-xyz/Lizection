//
//  LizectionApp.swift
//  Lizection
//
//  Created by Rongwei Ji on 2/16/25.
//

import SwiftUI
import SwiftData

@main
struct LizectionApp: App {
    // Toggle this flag to start with the test view during development
    private let startWithTestView = true
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            Location.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            if startWithTestView {
                CalendarSyncTestView(modelContainer: sharedModelContainer)  
//                CalendarServiceTestView()
            } else {
                ContentView()
                    .modelContainer(sharedModelContainer)
            }
        }
    }
}
