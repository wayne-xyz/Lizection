//
//  Location.swift
//  Lizection
//
//  Created by Rongwei Ji on 5/22/25.
//

import Foundation
import SwiftData
import CoreLocation

@Model
class Location {
    // MARK: - Core Event Data (from Calendar or User Input)
    var id: UUID // Unique identifier for the ToGoItem instance
    var name: String
    var address: String?
    var latitude: Double
    var longitude: Double
    var startTime: Date
    var endTime: Date
    var eventIdentifier: String? // Identifier from EventKit (EKEvent.eventIdentifier)

    // MARK: - Sync & Local Modification Metadata
    var syncStatus: SyncStatus         // Tracks the item's sync state (synced, modified, deleted, etc.)
    var lastLocalModificationDate: Date // Timestamp of the last time this ToGoItem was modified locally by the user or sync process
    var lastSyncDate: Date?           // Timestamp of the last successful calendar sync that processed this item
    var isUserModified: Bool          // Flag to indicate if the user has made local changes that conflict with calendar
    var originalEventData: Data?      // SHA256 hash (as Data) of the calendar event data at the last sync, for change detection

    // MARK: - User Enhancements (App-specific features)
    var userNotes: String?            // User-added notes specific to this ToGoItem
    var userTags: [String]            // User-defined tags for categorization
    var isArchived: Bool              // Flag to hide/archive the item without deleting it

    // MARK: - Geocoding Status
    var geocodingStatus: GeocodingStatus // Current status of address geocoding for this item
    var geocodingAttempts: Int        // Number of attempts made to geocode this item's address

    // MARK: - Initialization
    init(
        id: UUID = UUID(),
        name: String,
        address: String? = nil,
        latitude: Double = 0.0, // Default to 0.0, to be updated by geocoding
        longitude: Double = 0.0, // Default to 0.0, to be updated by geocoding
        startTime: Date,
        endTime: Date,
        eventIdentifier: String? = nil,
        // Sync & Local Modification Metadata defaults
        syncStatus: SyncStatus = .pending, // Default for newly created items (needs initial processing)
        lastLocalModificationDate: Date = Date(),
        lastSyncDate: Date? = nil,
        isUserModified: Bool = false,
        originalEventData: Data? = nil,
        // User Enhancements defaults
        userNotes: String? = nil,
        userTags: [String] = [],
        isArchived: Bool = false,
        // Geocoding Status defaults
        geocodingStatus: GeocodingStatus = .pending, // Default for newly created items (needs geocoding)
        geocodingAttempts: Int = 0
    ) {
        self.id = id
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.startTime = startTime
        self.endTime = endTime
        self.eventIdentifier = eventIdentifier
        self.syncStatus = syncStatus
        self.lastLocalModificationDate = lastLocalModificationDate
        self.lastSyncDate = lastSyncDate
        self.isUserModified = isUserModified
        self.originalEventData = originalEventData
        self.userNotes = userNotes
        self.userTags = userTags
        self.isArchived = isArchived
        self.geocodingStatus = geocodingStatus
        self.geocodingAttempts = geocodingAttempts
    }

    // MARK: - Computed Properties
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}


