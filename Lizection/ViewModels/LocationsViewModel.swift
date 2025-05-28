//
//  LocationsViewModel.swift
//  Lizection
//
//  Created by Rongwei Ji on 5/23/25.
//

import Foundation
import SwiftData
import SwiftUI
import Combine
import CoreLocation
import os.log

// MARK: - View State Types

enum LocationsViewState:Equatable {
    case idle
    case loading
    case syncing
    case error(String)
    case empty
}

enum LocationFilter {
    case all
    case today
    case upcoming
    case past
    case withNotes
    case archived
    case softDeleted
    case byTag(String)
    case byGeocodingStatus(GeocodingStatus)
    case bySyncStatus(SyncStatus)
}

enum LocationSortOption {
    case startTime
    case name
    case lastModified
    case distance(from: CLLocationCoordinate2D)
    
    var displayName: String {
        switch self {
        case .startTime: return "Start Time"
        case .name: return "Name"
        case .lastModified: return "Last Modified"
        case .distance: return "Distance"
        }
    }
}

// MARK: - Storage Info Type

struct StorageInfo {
    let totalLocations: Int
    let activeLocations: Int
    let softDeletedLocations: Int
    let archivedLocations: Int
    let estimatedSize: String
    let oldestLocationDate: Date?
    let newestLocationDate: Date?
}

// MARK: - Locations ViewModel

@MainActor
@Observable
class LocationsViewModel :ObservableObject{
    
    // MARK: - Published Properties (Observable)
    private(set) var locations: [Location] = []
    private(set) var filteredLocations: [Location] = []
    private(set) var viewState: LocationsViewState = .idle
    private(set) var lastSyncResult: SyncResult?
    private(set) var syncProgress: SyncProgress?
    
    // MARK: - Filter & Sort State
    var currentFilter: LocationFilter = .all {
        didSet { applyFilterAndSort() }
    }
    
    var currentSort: LocationSortOption = .startTime {
        didSet { applyFilterAndSort() }
    }
    
    var isAscending: Bool = true {
        didSet { applyFilterAndSort() }
    }
    
    var searchText: String = "" {
        didSet { applyFilterAndSort() }
    }
    
    // MARK: - Dependencies
    private let modelContainer: ModelContainer
    private let syncService: CalendarSyncService
    private let logger: Logger
    
    // MARK: - Private State
    var modelContext: ModelContext // open to preview access
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var availableTags: [String] {
        let allTags = locations.flatMap { $0.userTags }
        return Array(Set(allTags)).sorted()
    }
    
    var locationCounts: (total: Int, active: Int, synced: Int, pending: Int, errors: Int, softDeleted: Int) {
        let total = locations.count
        let active = locations.filter { $0.syncStatus != .deleted }.count
        let synced = locations.filter { $0.syncStatus == .synced }.count
        let pending = locations.filter { $0.syncStatus == .pending }.count
        let errors = locations.filter { $0.syncStatus == .error }.count
        let softDeleted = locations.filter { $0.syncStatus == .deleted }.count
        return (total, active, synced, pending, errors, softDeleted)
    }
    
    var geocodingCounts: (success: Int, pending: Int, failed: Int, retryLater: Int) {
        let success = locations.filter { $0.geocodingStatus == .success }.count
        let pending = locations.filter { $0.geocodingStatus == .pending }.count
        let failed = locations.filter { $0.geocodingStatus == .failed }.count
        let retryLater = locations.filter { $0.geocodingStatus == .retryLater }.count
        return (success, pending, failed, retryLater)
    }
    
    var isSyncing: Bool {
        return viewState == .syncing
    }
    
    var hasLocations: Bool {
        return !locations.isEmpty
    }
    
    var hasFilteredLocations: Bool {
        return !filteredLocations.isEmpty
    }
    
    var hasActiveLocations: Bool {
        return locations.contains { $0.syncStatus != .deleted }
    }
    
    var hasSoftDeletedLocations: Bool {
        return locations.contains { $0.syncStatus == .deleted }
    }
    
    // MARK: - Initialization
    
    init(modelContainer: ModelContainer, useMainContext: Bool = false) {
        self.modelContainer = modelContainer
        // Use mainContext if flag is true, otherwise create new context
        self.modelContext = useMainContext ? modelContainer.mainContext : ModelContext(modelContainer)
        self.syncService = CalendarSyncService(modelContainer: modelContainer)
        self.logger = Logger(subsystem: "com.lizection.app", category: "LocationsViewModel")
        
        // Load initial data
        loadLocations()

    }
    
    // MARK: - Data Loading
    
    func loadLocations() {
        viewState = .loading
        
        do {
            // Load ALL locations including soft-deleted ones for complete management
            let descriptor = FetchDescriptor<Location>(
                sortBy: [SortDescriptor(\.startTime, order: .forward)]
            )
            
            locations = try modelContext.fetch(descriptor)
            applyFilterAndSort()
            
            // Determine view state based on active locations
            if hasActiveLocations {
                viewState = .idle
            } else if hasLocations {
                // Only soft-deleted locations exist
                viewState = .empty
            } else {
                // No locations at all
                viewState = .empty
            }
            
            logger.info("Loaded \(self.locations.count) total locations (\(self.locationCounts.active) active, \(self.locationCounts.softDeleted) soft-deleted)")
            
        } catch {
            viewState = .error("Failed to load locations: \(error.localizedDescription)")
            logger.error("Failed to load locations: \(error.localizedDescription)")
        }
    }
    
    func refreshLocations() {
        loadLocations()
    }
    
    // MARK: - Sync Operations
    
    func syncTodaysEvents() async {
        await performSync {
            try await self.syncService.syncTodaysEvents()
        }
    }
    
    func syncEvents(from startDate: Date, to endDate: Date) async {
        await performSync {
            try await self.syncService.syncEvents(from: startDate, to: endDate)
        }
    }
    
    func syncEventsForDateRange(_ dateRange: DateRange) async {
        let range = dateRange.dateRange()
        await syncEvents(from: range.start, to: range.end)
    }
    
    private func performSync(_ syncOperation: @escaping () async throws -> SyncResult) async {
        viewState = .syncing
        syncProgress = SyncProgress(
            currentStep: "Preparing sync...",
            progress: 0.0,
            itemsProcessed: 0,
            totalItems: 0,
            currentItem: nil
        )
        
        do {
            let result = try await syncOperation()
            lastSyncResult = result
            
            // Reload data after sync
            loadLocations()
            
            if result.isSuccess {
                viewState = hasActiveLocations ? .idle : .empty
                logger.info("Sync completed successfully: \(result.summary)")
            } else {
                viewState = .error("Sync completed with errors: \(result.errors.map { $0.localizedDescription }.joined(separator: ", "))")
                logger.warning("Sync completed with errors: \(result.summary)")
            }
            
        } catch {
            viewState = .error("Sync failed: \(error.localizedDescription)")
            logger.error("Sync failed: \(error.localizedDescription)")
        }
        
        syncProgress = nil
    }
    
    // MARK: - Location Management (Soft Operations)
    
    func updateLocation(_ location: Location) {
        do {
            location.lastLocalModificationDate = Date()
            location.isUserModified = true
            
            // If user modifies a synced location, mark it as modified
            if location.syncStatus == .synced {
                location.syncStatus = .modified
            }
            
            try modelContext.save()
            loadLocations() // Refresh to reflect changes
            logger.info("Updated location: \(location.name)")
            
        } catch {
            viewState = .error("Failed to update location: \(error.localizedDescription)")
            logger.error("Failed to update location: \(error.localizedDescription)")
        }
    }
    
    func deleteLocation(_ location: Location) {
        do {
            // Soft delete - mark as deleted instead of removing from database
            location.syncStatus = .deleted
            location.lastLocalModificationDate = Date()
            
            try modelContext.save()
            loadLocations() // Refresh to reflect changes
            logger.info("Soft deleted location: \(location.name)")
            
        } catch {
            viewState = .error("Failed to delete location: \(error.localizedDescription)")
            logger.error("Failed to delete location: \(error.localizedDescription)")
        }
    }
    
    func restoreLocation(_ location: Location) {
        guard location.syncStatus == .deleted else {
            logger.warning("Attempted to restore location that is not soft-deleted: \(location.name)")
            return
        }
        
        do {
            // Restore from soft delete
            location.syncStatus = location.isUserModified ? .modified : .synced
            location.lastLocalModificationDate = Date()
            
            try modelContext.save()
            loadLocations() // Refresh to reflect changes
            logger.info("Restored location: \(location.name)")
            
        } catch {
            viewState = .error("Failed to restore location: \(error.localizedDescription)")
            logger.error("Failed to restore location: \(error.localizedDescription)")
        }
    }
    
    func archiveLocation(_ location: Location) {
        location.isArchived = true
        updateLocation(location)
    }
    
    func unarchiveLocation(_ location: Location) {
        location.isArchived = false
        updateLocation(location)
    }
    
    func addUserNote(to location: Location, note: String) {
        location.userNotes = note.isEmpty ? nil : note
        updateLocation(location)
    }
    
    func addTag(to location: Location, tag: String) {
        if !location.userTags.contains(tag) {
            location.userTags.append(tag)
            updateLocation(location)
        }
    }
    
    func removeTag(from location: Location, tag: String) {
        location.userTags.removeAll { $0 == tag }
        updateLocation(location)
    }
    
    // MARK: - Hard Delete Operations
    
    func hardDeleteLocation(_ location: Location) {
        do {
            let locationName = location.name // Store name before deletion for logging
            
            // Remove from SwiftData context (this is the actual hard delete)
            modelContext.delete(location)
            try modelContext.save()
            
            // Refresh the view
            loadLocations()
            logger.info("Hard deleted location: \(locationName)")
            
        } catch {
            viewState = .error("Failed to permanently delete location: \(error.localizedDescription)")
            logger.error("Failed to hard delete location: \(error.localizedDescription)")
        }
    }
    
    func hardDeleteAllSoftDeletedLocations() async {
        do {
            // Fetch all soft-deleted locations
            let descriptor = FetchDescriptor<Location>(
                predicate: #Predicate<Location> { location in
                    location.syncStatus.rawValue == "deleted"
                }
            )
            
            let softDeletedLocations = try modelContext.fetch(descriptor)
            let count = softDeletedLocations.count
            
            guard count > 0 else {
                logger.info("No soft-deleted locations to clean up")
                return
            }
            
            // Hard delete each one
            for location in softDeletedLocations {
                modelContext.delete(location)
            }
            
            try modelContext.save()
            loadLocations()
            
            logger.info("Hard deleted \(count) soft-deleted locations")
            
        } catch {
            viewState = .error("Failed to clean up deleted locations: \(error.localizedDescription)")
            logger.error("Failed to hard delete soft-deleted locations: \(error.localizedDescription)")
        }
    }
    
    func hardDeleteOldLocations(olderThan days: Int) async {
        do {
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
            
            let descriptor = FetchDescriptor<Location>(
                predicate: #Predicate<Location> { location in
                    location.endTime < cutoffDate && 
                    (location.syncStatus.rawValue == "deleted" || location.isArchived)
                }
            )
            
            let oldLocations = try modelContext.fetch(descriptor)
            let count = oldLocations.count
            
            guard count > 0 else {
                logger.info("No old locations to clean up (older than \(days) days)")
                return
            }
            
            for location in oldLocations {
                modelContext.delete(location)
            }
            
            try modelContext.save()
            loadLocations()
            
            logger.info("Hard deleted \(count) old locations (older than \(days) days)")
            
        } catch {
            viewState = .error("Failed to clean up old locations: \(error.localizedDescription)")
            logger.error("Failed to hard delete old locations: \(error.localizedDescription)")
        }
    }
    
    func hardDeleteArchivedLocations(olderThan days: Int) async {
        do {
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
            
            let descriptor = FetchDescriptor<Location>(
                predicate: #Predicate<Location> { location in
                    location.isArchived && location.lastLocalModificationDate < cutoffDate
                }
            )
            
            let archivedLocations = try modelContext.fetch(descriptor)
            let count = archivedLocations.count
            
            guard count > 0 else {
                logger.info("No old archived locations to clean up (older than \(days) days)")
                return
            }
            
            for location in archivedLocations {
                modelContext.delete(location)
            }
            
            try modelContext.save()
            loadLocations()
            
            logger.info("Hard deleted \(count) old archived locations (older than \(days) days)")
            
        } catch {
            viewState = .error("Failed to clean up old archived locations: \(error.localizedDescription)")
            logger.error("Failed to hard delete old archived locations: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Storage Management
    
    func getStorageInfo() -> StorageInfo {
        do {
            let allDescriptor = FetchDescriptor<Location>()
            let allLocations = try modelContext.fetch(allDescriptor)
            
            let activeLocations = allLocations.filter { $0.syncStatus != .deleted }.count
            let softDeletedLocations = allLocations.filter { $0.syncStatus == .deleted }.count
            let archivedLocations = allLocations.filter { $0.isArchived }.count
            
            // Rough estimation of storage (this is approximate)
            let estimatedBytesPerLocation = 500 // Rough estimate including strings, dates, etc.
            let totalBytes = allLocations.count * estimatedBytesPerLocation
            let estimatedSize = ByteCountFormatter.string(fromByteCount: Int64(totalBytes), countStyle: .file)
            
            // Find date range
            let sortedByDate = allLocations.sorted { $0.startTime < $1.startTime }
            let oldestDate = sortedByDate.first?.startTime
            let newestDate = sortedByDate.last?.startTime
            
            return StorageInfo(
                totalLocations: allLocations.count,
                activeLocations: activeLocations,
                softDeletedLocations: softDeletedLocations,
                archivedLocations: archivedLocations,
                estimatedSize: estimatedSize,
                oldestLocationDate: oldestDate,
                newestLocationDate: newestDate
            )
            
        } catch {
            logger.error("Failed to get storage info: \(error.localizedDescription)")
            return StorageInfo(
                totalLocations: 0,
                activeLocations: 0,
                softDeletedLocations: 0,
                archivedLocations: 0,
                estimatedSize: "Unknown",
                oldestLocationDate: nil,
                newestLocationDate: nil
            )
        }
    }
    
    func getCleanupRecommendations() -> [String] {
        let storageInfo = getStorageInfo()
        var recommendations: [String] = []
        
        if storageInfo.softDeletedLocations > 0 {
            recommendations.append("Clean up \(storageInfo.softDeletedLocations) deleted locations")
        }
        
        if storageInfo.archivedLocations > 10 {
            recommendations.append("Consider cleaning old archived locations")
        }
        
        if storageInfo.totalLocations > 1000 {
            recommendations.append("Large number of locations - consider cleanup")
        }
        
        // Check for very old locations
        if let oldestDate = storageInfo.oldestLocationDate {
            let daysSinceOldest = Calendar.current.dateComponents([.day], from: oldestDate, to: Date()).day ?? 0
            if daysSinceOldest > 365 {
                recommendations.append("Locations older than 1 year found")
            }
        }
        
        return recommendations
    }
    
    // MARK: - Filtering & Sorting
    
    private func applyFilterAndSort() {
        var filtered = locations
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { location in
                location.name.localizedCaseInsensitiveContains(searchText) ||
                location.address?.localizedCaseInsensitiveContains(searchText) == true ||
                location.userNotes?.localizedCaseInsensitiveContains(searchText) == true ||
                location.userTags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Apply current filter
        filtered = applyFilter(filtered, filter: currentFilter)
        
        // Apply sorting
        filtered = applySorting(filtered, sort: currentSort, ascending: isAscending)
        
        filteredLocations = filtered
    }
    
    private func applyFilter(_ locations: [Location], filter: LocationFilter) -> [Location] {
        switch filter {
        case .all:
            // Show only active locations by default
            return locations.filter { $0.syncStatus != .deleted }
            
        case .today:
            let calendar = Calendar.current
            let now = Date()
            let today = calendar.startOfDay(for: Date())
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
            return locations.filter { location in
                location.syncStatus != .deleted &&
                location.startTime >= now && // Only upcoming events (not past)
                location.startTime >= today && location.startTime < tomorrow
            }
            
        case .upcoming:
            let now = Date()
            return locations.filter { 
                $0.syncStatus != .deleted && $0.startTime > now 
            }
            
        case .past:
            let now = Date()
            return locations.filter { 
                $0.syncStatus != .deleted && $0.endTime < now 
            }
            
        case .withNotes:
            return locations.filter { 
                $0.syncStatus != .deleted && 
                $0.userNotes != nil && !$0.userNotes!.isEmpty 
            }
            
        case .archived:
            return locations.filter { 
                $0.syncStatus != .deleted && $0.isArchived 
            }
            
        case .softDeleted:
            return locations.filter { $0.syncStatus == .deleted }
            
        case .byTag(let tag):
            return locations.filter { 
                $0.syncStatus != .deleted && $0.userTags.contains(tag) 
            }
            
        case .byGeocodingStatus(let status):
            return locations.filter { 
                $0.syncStatus != .deleted && $0.geocodingStatus == status 
            }
            
        case .bySyncStatus(let status):
            return locations.filter { $0.syncStatus == status }
        }
    }
    
    private func applySorting(_ locations: [Location], sort: LocationSortOption, ascending: Bool) -> [Location] {
        let sorted: [Location]
        
        switch sort {
        case .startTime:
            sorted = locations.sorted { ascending ? $0.startTime < $1.startTime : $0.startTime > $1.startTime }
            
        case .name:
            sorted = locations.sorted { ascending ? $0.name < $1.name : $0.name > $1.name }
            
        case .lastModified:
            sorted = locations.sorted { ascending ? $0.lastLocalModificationDate < $1.lastLocalModificationDate : $0.lastLocalModificationDate > $1.lastLocalModificationDate }
            
        case .distance(let fromCoordinate):
            sorted = locations.sorted { location1, location2 in
                let distance1 = calculateDistance(from: fromCoordinate, to: location1.coordinate)
                let distance2 = calculateDistance(from: fromCoordinate, to: location2.coordinate)
                return ascending ? distance1 < distance2 : distance1 > distance2
            }
        }
        
        return sorted
    }
    
    private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation)
    }
    
    // MARK: - Quick Filters
    
    func showTodaysLocations() {
        currentFilter = .today
    }
    
    func showUpcomingLocations() {
        currentFilter = .upcoming
    }
    
    func showPastLocations() {
        currentFilter = .past
    }
    
    func showArchivedLocations() {
        currentFilter = .archived
    }
    
    func showSoftDeletedLocations() {
        currentFilter = .softDeleted
    }
    
    func showLocationsWithTag(_ tag: String) {
        currentFilter = .byTag(tag)
    }
    
    func showAllLocations() {
        currentFilter = .all
    }
    
    // MARK: - Utility Methods
    
    func clearError() {
        if case .error = viewState {
            viewState = hasActiveLocations ? .idle : .empty
        }
    }
    
    func getLocationById(_ id: UUID) -> Location? {
        return locations.first { $0.id == id }
    }
    
    func getLocationsByEventIdentifier(_ eventIdentifier: String) -> [Location] {
        return locations.filter { $0.eventIdentifier == eventIdentifier }
    }
}

// MARK: - Extensions

extension LocationsViewModel {
    
    // Convenience methods for SwiftUI views
    func binding(for location: Location) -> Binding<Location> {
        Binding(
            get: { location },
            set: { _ in
                // Location is a reference type (@Model), changes are automatically tracked
                // Just trigger a save when the binding is set
                self.updateLocation(location)
            }
        )
    }
}
