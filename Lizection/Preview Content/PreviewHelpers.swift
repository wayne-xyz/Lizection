//
//  PreviewHelpers.swift
//  Lizection
//
//  Created by Rongwei Ji on 5/27/25.
//
// PreviewHelpers.swift
import SwiftUI
import SwiftData

// In PreviewHelpers.swift
extension ModelContainer {
    @MainActor
    static var preview: ModelContainer {
        let container = try! ModelContainer(
            for: Location.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        
        print("📦 Creating preview container...")
        
        // Create and insert sample data directly into the container's mainContext
        let locations = [
            Location(
                name: "Apple Park",
                address: "1 Apple Park Way, Cupertino, CA",
                latitude: 37.3349,
                longitude: -122.0090,
                startTime: Date().addingTimeInterval(3600),
                endTime: Date().addingTimeInterval(7200),
                geocodingStatus: .success
            ),
            Location(
                name: "WWDC Event",
                address: "San Jose Convention Center",
                latitude: 37.3300,
                longitude: -121.8889,
                startTime: Date().addingTimeInterval(1800),
                endTime: Date().addingTimeInterval(5400),
                geocodingStatus: .success
            )
        ]
        
        print("📍 Sample locations created:")
        for (index, location) in locations.enumerated() {
            print("  \(index + 1). \(location.name)")
            print("     - Address: \(location.address ?? "No address")")
            print("     - Time: \(location.startTime.formatted(date: .omitted, time: .shortened))")
            print("     - Status: \(location.geocodingStatus)")
        }
        
        // Insert the sample data into the container's mainContext
        for location in locations {
            container.mainContext.insert(location)
        }
        
        print("✅ Sample data inserted into container")
        print("📊 Total locations: \(locations.count)")
        print("🔍 Container mainContext address: \(ObjectIdentifier(container.mainContext))")
        
        return container
    }
}
