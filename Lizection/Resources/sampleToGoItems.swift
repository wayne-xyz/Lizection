//
//  toGoExamples.swift
//  Lizection
//
//  Created by Rongwei Ji on 5/19/25.
//

import Foundation

let sampleToGoItems: [Location] = [
    Location(
        id: UUID(uuidString: "550e8400-e29b-41d4-a716-446655440000")!,
        name: "Perot Museum of Nature and Science",
        address: "2201 N Field St, Dallas, TX 75201",
        latitude: 32.7867,
        longitude: -96.8035,
        startTime: Date(),
        endTime: Calendar.current.date(byAdding: .hour, value: 1, to: Date())!,
        eventIdentifier: "Perot Tour"
    ),
    Location(
        id: UUID(uuidString: "6ba7b810-9dad-11d1-80b4-00c04fd430c8")!,
        name: "Reunion Tower",
        address: "300 Reunion Blvd E, Dallas, TX 75207",
        latitude: 32.7757,
        longitude: -96.8095,
        startTime: Date(),
        endTime: Calendar.current.date(byAdding: .hour, value: 1, to: Date())!,
        eventIdentifier: "Reunion Tower Visit"
    ),
    Location(
        id: UUID(uuidString: "7ba7b810-9dad-11d1-80b4-00c04fd430c9")!,
        name: "Dallas Arboretum and Botanical Garden",
        address: "8525 Garland Rd, Dallas, TX 75218",
        latitude: 32.8231,
        longitude: -96.7162,
        startTime: Date(),
        endTime: Calendar.current.date(byAdding: .hour, value: 1, to: Date())!,
        eventIdentifier: "Arboretum Walk"
    ),
    Location(
        id: UUID(uuidString: "8ba7b810-9dad-11d1-80b4-00c04fd430c0")!,
        name: "The Sixth Floor Museum at Dealey Plaza",
        address: "411 Elm St, Dallas, TX 75202",
        latitude: 32.7792,
        longitude: -96.8089,
        startTime: Date(),
        endTime: Calendar.current.date(byAdding: .hour, value: 1, to: Date())!,
        eventIdentifier: "JFK History Tour"
    ),
    Location(
        id: UUID(uuidString: "9ba7b810-9dad-11d1-80b4-00c04fd430c1")!,
        name: "Klyde Warren Park",
        address: "2012 Woodall Rodgers Fwy, Dallas, TX 75201",
        latitude: 32.7891,
        longitude: -96.8017,
        startTime: Date(),
        endTime: Calendar.current.date(byAdding: .hour, value: 1, to: Date())!,
        eventIdentifier: "Lunch in the Park"
    )
]
