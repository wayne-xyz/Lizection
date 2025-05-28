//
//  CalendarSyncService.swift
//  Lizection
//
//  Created by Rongwei Ji on 5/23/25.
//

import Foundation
import EventKit
import SwiftData
import CoreLocation
import os.log


// MARK: - Sync Result Types

struct SyncResult {
    let totalEvents: Int
    let newLocations: Int
    let updatedLocations: Int
    let deletedLocations: Int
    let skippedLocations: Int
    let geocodingFailures: Int
    let errors: [SyncError]
    let syncDate: Date
    let syncDuration: TimeInterval
    let dateRange: (start: Date, end: Date)
    
    var isSuccess: Bool {
        return errors.isEmpty
    }
    
    var summary: String {
        return "Sync completed in \(String(format: "%.2f", syncDuration))s: \(newLocations) new, \(updatedLocations) updated, \(deletedLocations) deleted, \(skippedLocations) skipped, \(geocodingFailures) geocoding failures, \(errors.count) errors"
    }
}

struct SyncProgress {
    let currentStep: String
    let progress: Double // 0.0 to 1.0
    let itemsProcessed: Int
    let totalItems: Int
    let currentItem: String?
}

// MARK: - Sync Service Protocol

protocol CalendarSyncServiceProtocol {
    func syncTodaysEvents() async throws -> SyncResult
    func syncEvents(from startDate: Date, to endDate: Date) async throws -> SyncResult
    func validateSyncRequirements() async throws
}

// MARK: - Calendar Sync Service (Pure Service with Swift Concurrency)

actor CalendarSyncService: CalendarSyncServiceProtocol {
    
    // MARK: - Dependencies
    private let calendarService: CalendarServiceProtocol
    private let locationService: LocationService
    private let modelContainer: ModelContainer // create the modelcontext, avoid non-sendable of the modelcontext, thread safety
    private let logger: Logger
    
    // MARK: - Configuration
    private let maxGeocodingAttempts = 3
    private let geocodingRetryDelay: TimeInterval = 2.0
    private let isDebugMode: Bool
    
    // MARK: - Private State (for sync coordination only)
    private var isSyncing = false
    
    // MARK: - Initialization
    init(
        calendarService: CalendarServiceProtocol = CalendarService(),
        locationService: LocationService = LocationService(),
        modelContainer: ModelContainer,
        isDebugMode: Bool = true
    ) {
        self.calendarService = calendarService
        self.locationService = locationService
        self.modelContainer = modelContainer
        self.logger = Logger(subsystem: "com.lizection.app", category: "CalendarSync")
        
        // Automatically detect debug mode in release builds
        #if DEBUG
        self.isDebugMode = isDebugMode
        #else
        self.isDebugMode = false
        #endif
    }
    
    // MARK: - Public Sync Methods
    
    func syncTodaysEvents() async throws -> SyncResult {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? now
        
        return try await syncEvents(from: startOfDay, to: endOfDay)
    }
    
    func syncEvents(from startDate: Date, to endDate: Date) async throws -> SyncResult {
        let syncStartTime = ContinuousClock.now
        
        // Validate inputs
        guard startDate < endDate else {
            throw SyncError.invalidDateRange
        }
        
        // Prevent concurrent syncs
        guard !isSyncing else {
            throw SyncError.syncInProgress
        }
        
        isSyncing = true
        defer { isSyncing = false }
        
        let modelContext = ModelContext(modelContainer)
        
        return try await performSync(
            from: startDate,
            to: endDate,
            modelContext: modelContext,
            startTime: syncStartTime
        )
    }
    
    func validateSyncRequirements() async throws {
        // Test calendar access
        _ = try await calendarService.requestCalendarAccess()
        debugLog("✅ Calendar access validated")
    }
    
    // MARK: - Private Sync Implementation
    
    private func performSync(
        from startDate: Date,
        to endDate: Date,
        modelContext: ModelContext,
        startTime: ContinuousClock.Instant
    ) async throws -> SyncResult {
        
        debugLog("🔄 Starting calendar sync for range: \(formatDateRange(startDate, endDate))")
        
        var errors: [SyncError] = []
        var newLocations = 0
        var updatedLocations = 0
        var deletedLocations = 0
        var skippedLocations = 0
        var geocodingFailures = 0
        
        do {
            // Step 1: Fetch calendar events with locations
            let stepStartTime = ContinuousClock.now
            debugLog("📅 Step 1: Fetching calendar events with locations...")
            
            let calendarEvents = try await calendarService.fetchEventsWithLocation(from: startDate, to: endDate)
            
            let fetchDuration = stepStartTime.duration(to: ContinuousClock.now)
            debugLog("📋 Found \(calendarEvents.count) calendar events with locations (took \(fetchDuration.formatted(.time(pattern: .minuteSecond(padMinuteToLength: 2)))))")
            
            if calendarEvents.isEmpty {
                let totalDuration = startTime.duration(to: ContinuousClock.now)
                debugLog("⚠️ No events found, sync completed in \(totalDuration.formatted(.time(pattern: .minuteSecond(padMinuteToLength: 2))))")
                
                return SyncResult(
                    totalEvents: 0,
                    newLocations: 0,
                    updatedLocations: 0,
                    deletedLocations: 0,
                    skippedLocations: 0,
                    geocodingFailures: 0,
                    errors: [SyncError.noEventsFound],
                    syncDate: Date(),
                    syncDuration: totalDuration.timeInterval,
                    dateRange: (startDate, endDate)
                )
            }
            
            // Step 2: Load existing Locations
            let loadStartTime = ContinuousClock.now
            debugLog("🗃️ Step 2: Loading existing Locations...")
            
            let existingLocations = try fetchExistingLocations(in: startDate...endDate, modelContext: modelContext)
            
            let loadDuration = loadStartTime.duration(to: ContinuousClock.now)
            debugLog("📦 Loaded \(existingLocations.count) existing Locations (took \(loadDuration.formatted(.time(pattern: .minuteSecond(padMinuteToLength: 2)))))")
            
            // Step 3: Process each calendar event
            let processStartTime = ContinuousClock.now
            debugLog("🔄 Step 3: Processing \(calendarEvents.count) calendar events...")
            
            for (index, event) in calendarEvents.enumerated() {
                let eventStartTime = ContinuousClock.now
                debugLog("🔄 Processing event \(index + 1)/\(calendarEvents.count): '\(event.title ?? "Untitled")'")
                
                do {
                    let result = try await processCalendarEvent(event, existingLocations: existingLocations, modelContext: modelContext)
                    
                    let eventDuration = eventStartTime.duration(to: ContinuousClock.now)
                    
                    switch result {
                    case .created:
                        newLocations += 1
                        debugLog("  ➕ Created new location (took \(eventDuration.formatted(.time(pattern: .minuteSecond(padMinuteToLength: 2)))))")
                    case .updated:
                        updatedLocations += 1
                        debugLog("  🔄 Updated existing location (took \(eventDuration.formatted(.time(pattern: .minuteSecond(padMinuteToLength: 2)))))")
                    case .noChange:
                        skippedLocations += 1
                        debugLog("  ⏭️ No changes needed (took \(eventDuration.formatted(.time(pattern: .minuteSecond(padMinuteToLength: 2)))))")
                    case .geocodingFailed:
                        geocodingFailures += 1
                        debugLog("  ❌ Geocoding failed (took \(eventDuration.formatted(.time(pattern: .minuteSecond(padMinuteToLength: 2)))))")
                    }
                    
                } catch let syncError as SyncError {
                    errors.append(syncError)
                    debugLog("  ❌ Error: \(syncError.localizedDescription)")
                } catch {
                    let dbError = SyncError.databaseError(error.localizedDescription)
                    errors.append(dbError)
                    debugLog("  ❌ Unexpected error: \(error.localizedDescription)")
                }
            }
            
            let processDuration = processStartTime.duration(to: ContinuousClock.now)
            debugLog("✅ Event processing completed in \(processDuration.formatted(.time(pattern: .minuteSecond(padMinuteToLength: 2))))")
            
            // Step 4: Handle deleted events
            let deleteStartTime = ContinuousClock.now
            debugLog("🗑️ Step 4: Checking for deleted events...")
            
            let eventIdentifiers = Set(calendarEvents.compactMap { $0.eventIdentifier })
            let locationsToDelete = existingLocations.filter { location in
                guard let eventId = location.eventIdentifier else { return false }
                return !eventIdentifiers.contains(eventId)
            }
            
            for location in locationsToDelete {
                debugLog("🗑️ Marking location as deleted: '\(location.name)'")
                location.syncStatus = .deleted
                location.lastLocalModificationDate = Date()
                deletedLocations += 1
            }
            
            let deleteDuration = deleteStartTime.duration(to: ContinuousClock.now)
            debugLog("🗑️ Deletion check completed in \(deleteDuration.formatted(.time(pattern: .minuteSecond(padMinuteToLength: 2))))")
            
            // Step 5: Save changes
            let saveStartTime = ContinuousClock.now
            debugLog("💾 Step 5: Saving changes to database...")
            
            try modelContext.save()
            
            let saveDuration = saveStartTime.duration(to: ContinuousClock.now)
            debugLog("✅ Database changes saved in \(saveDuration.formatted(.time(pattern: .minuteSecond(padMinuteToLength: 2))))")
            
            // Calculate total duration and create result
            let totalDuration = startTime.duration(to: ContinuousClock.now)
            
            let result = SyncResult(
                totalEvents: calendarEvents.count,
                newLocations: newLocations,
                updatedLocations: updatedLocations,
                deletedLocations: deletedLocations,
                skippedLocations: skippedLocations,
                geocodingFailures: geocodingFailures,
                errors: errors,
                syncDate: Date(),
                syncDuration: totalDuration.timeInterval,
                dateRange: (startDate, endDate)
            )
            
            debugLog("🏁 Sync completed: \(result.summary)")
            
            return result
            
        } catch {
            let totalDuration = startTime.duration(to: ContinuousClock.now)
            debugLog("❌ Sync failed after \(totalDuration.formatted(.time(pattern: .minuteSecond(padMinuteToLength: 2)))): \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Event Processing
    
    private enum ProcessResult {
        case created
        case updated
        case noChange
        case geocodingFailed
    }
    
    private func processCalendarEvent(
        _ event: EKEvent,
        existingLocations: [Location],
        modelContext: ModelContext
    ) async throws -> ProcessResult {
        
        guard let eventIdentifier = event.eventIdentifier else {
            throw SyncError.eventProcessingFailed("Event has no identifier")
        }
        
        // Find existing location
        let existingLocation = existingLocations.first { $0.eventIdentifier == eventIdentifier }
        
        // Create event hash for change detection
        let eventHash = createEventHash(from: event)
        let eventHashData = eventHash.data(using: .utf8)
        
        if let existing = existingLocation {
            // Check if event has changed
            if existing.originalEventData == eventHashData {
                return .noChange
            }
            
            // Update existing location
            let result = try await updateLocation(existing, from: event, eventHash: eventHashData, modelContext: modelContext)
            return result == .geocodingFailed ? .geocodingFailed : .updated
            
        } else {
            // Create new location
            let result = try await createLocation(from: event, eventHash: eventHashData, modelContext: modelContext)
            return result == .geocodingFailed ? .geocodingFailed : .created
        }
    }
    
    private func createLocation(
        from event: EKEvent,
        eventHash: Data?,
        modelContext: ModelContext
    ) async throws -> ProcessResult {
        
        guard let address = event.location,
              !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SyncError.eventProcessingFailed("Event has no valid location")
        }
        
        // Create location with pending geocoding status
        let location = Location(
            name: event.title ?? "Untitled Event",
            address: address,
            latitude: 0.0, // Will be updated by geocoding
            longitude: 0.0, // Will be updated by geocoding
            startTime: event.startDate ?? Date(),
            endTime: event.endDate ?? Date(),
            eventIdentifier: event.eventIdentifier,
            syncStatus: .synced,
            lastLocalModificationDate: Date(),
            lastSyncDate: Date(),
            isUserModified: false,
            originalEventData: eventHash,
            geocodingStatus: .pending,
            geocodingAttempts: 0
        )
        
        // Attempt geocoding
        let geocodeResult = await attemptGeocoding(for: location, address: address)
        
        modelContext.insert(location)
        debugLog("  ✅ Created Location: '\(location.name)'")
        
        return geocodeResult ? .created : .geocodingFailed
    }
    
    private func updateLocation(
        _ location: Location,
        from event: EKEvent,
        eventHash: Data?,
        modelContext: ModelContext
    ) async throws -> ProcessResult {
        
        guard let address = event.location,
              !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SyncError.eventProcessingFailed("Event has no valid location")
        }
        
        // Update basic properties
        location.name = event.title ?? "Untitled Event"
        location.startTime = event.startDate ?? location.startTime
        location.endTime = event.endDate ?? location.endTime
        location.syncStatus = .synced
        location.lastLocalModificationDate = Date()
        location.lastSyncDate = Date()
        location.originalEventData = eventHash
        
        // Check if location changed and needs re-geocoding
        var geocodeResult = true
        if location.address != address {
            debugLog("  📍 Location changed, re-geocoding: '\(address)'")
            location.address = address
            location.geocodingStatus = .pending
            location.geocodingAttempts = 0
            
            geocodeResult = await attemptGeocoding(for: location, address: address)
        }
        
        debugLog("  ✅ Updated Location: '\(location.name)'")
        return geocodeResult ? .updated : .geocodingFailed
    }
    
    // MARK: - Geocoding
    
    private func attemptGeocoding(for location: Location, address: String) async -> Bool {
        let geocodeStartTime = ContinuousClock.now
        
        do {
            let coordinate = try await locationService.geocodeAddress(address)
            location.latitude = coordinate.latitude
            location.longitude = coordinate.longitude
            location.geocodingStatus = .success
            
            let geocodeDuration = geocodeStartTime.duration(to: ContinuousClock.now)
            debugLog("  📍 Geocoded '\(address)' to (\(coordinate.latitude), \(coordinate.longitude)) in \(geocodeDuration.formatted(.time(pattern: .minuteSecond(padMinuteToLength: 2))))")
            
            return true
            
        } catch {
            location.geocodingAttempts += 1
            
            if location.geocodingAttempts >= maxGeocodingAttempts {
                location.geocodingStatus = .failed
                debugLog("  ❌ Geocoding failed permanently for '\(address)' after \(location.geocodingAttempts) attempts")
            } else {
                location.geocodingStatus = .retryLater
                debugLog("  ⚠️ Geocoding failed for '\(address)', will retry later (attempt \(location.geocodingAttempts)/\(maxGeocodingAttempts))")
            }
            
            return false
        }
    }
    
    // MARK: - Helper Methods
    
    private func fetchExistingLocations(
        in dateRange: ClosedRange<Date>,
        modelContext: ModelContext
    ) throws -> [Location] {
        
        let descriptor = FetchDescriptor<Location>(
            predicate: #Predicate<Location> { location in
                location.startTime >= dateRange.lowerBound && 
                location.startTime <= dateRange.upperBound

            }
        )
        
        let allLocations = try modelContext.fetch(descriptor)
        // Filter out deleted status in Swift, not in predicate
        return allLocations.filter { $0.syncStatus != .deleted }
    }
    
    private func createEventHash(from event: EKEvent) -> String {
        let hashString = [
            event.title ?? "",
            event.location ?? "",
            event.startDate?.timeIntervalSince1970.description ?? "",
            event.endDate?.timeIntervalSince1970.description ?? "",
            event.notes ?? ""
        ].joined(separator: "|")
        
        return hashString.sha256
    }
    
    private func formatDateRange(_ start: Date, _ end: Date) -> String {
        return "\(start.formatted(date: .abbreviated, time: .omitted)) to \(end.formatted(date: .abbreviated, time: .omitted))"
    }
    
    // MARK: - Debug Logging
    
    private func debugLog(_ message: String) {
        if isDebugMode {
            let timestamp = Date().formatted(date: .omitted, time: .standard)
            print("[\(timestamp)] CalendarSync: \(message)")
            logger.debug("\(message)")
        }
    }
}

// MARK: - Extensions

extension String {
    var sha256: String {
        let data = Data(self.utf8)
        return data.map { String(format: "%02x", $0) }.joined()
    }
}

extension Duration {
    var timeInterval: TimeInterval {
        return TimeInterval(self.components.seconds) + TimeInterval(self.components.attoseconds) / 1_000_000_000_000_000_000
    }
}

