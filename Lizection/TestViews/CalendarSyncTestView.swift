//
//  CalendarSyncTestView.swift
//  Lizection
//
//  Created by Rongwei Ji on 5/23/25.
//

import SwiftUI
import SwiftData

struct CalendarSyncTestView: View {
    @State private var viewModel: LocationsViewModel
    @State private var showingHardDeleteConfirmation = false
    @State private var showingClearAllConfirmation = false
    @State private var isRefreshing = false
    
    private let modelContainer: ModelContainer
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        self._viewModel = State(initialValue: LocationsViewModel(modelContainer: modelContainer))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // MARK: - Database Info Section
                    DatabaseInfoSection(viewModel: viewModel)
                    
                    // MARK: - Sync Actions Section
                    SyncActionsSection(viewModel: viewModel)
                    
                    // MARK: - Sync Results Section
                    SyncResultsSection(viewModel: viewModel)
                    
                    // MARK: - Today's Locations List
                    TodaysLocationsSection(viewModel: viewModel)
                    
                    // MARK: - Danger Zone
                    DangerZoneSection(
                        viewModel: viewModel,
                        showingHardDeleteConfirmation: $showingHardDeleteConfirmation,
                        showingClearAllConfirmation: $showingClearAllConfirmation
                    )
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationTitle("Calendar Sync Test")
            .refreshable {
                await refreshData()
            }
            .onAppear {
                
//                viewModel.refreshLocations() 
            }
            .confirmationDialog(
                "Clear All Data",
                isPresented: $showingClearAllConfirmation,
                titleVisibility: .visible
            ) {
                Button("Clear All Locations", role: .destructive) {
                    Task {
                        await clearAllLocations()
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will permanently delete ALL locations from the database. This action cannot be undone.")
            }
            .confirmationDialog(
                "Clean Up Deleted Items",
                isPresented: $showingHardDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Permanently", role: .destructive) {
                    Task {
                        await viewModel.hardDeleteAllSoftDeletedLocations()
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will permanently delete all soft-deleted locations. This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func refreshData() async {
        isRefreshing = true
        viewModel.refreshLocations()
        try? await Task.sleep(nanoseconds: 500_000_000) // Small delay for visual feedback
        isRefreshing = false
    }
    
    private func clearAllLocations() async {
        do {
            let modelContext = ModelContext(modelContainer)
            
            // Fetch all locations
            let descriptor = FetchDescriptor<Location>()
            let allLocations = try modelContext.fetch(descriptor)
            
            // Delete all locations
            for location in allLocations {
                modelContext.delete(location)
            }
            
            try modelContext.save()
            
            // Refresh the view
            await MainActor.run {
                viewModel.refreshLocations()
            }
            
        } catch {
            print("Failed to clear all locations: \(error)")
        }
    }
}

// MARK: - Database Info Section

struct DatabaseInfoSection: View {
    let viewModel: LocationsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "cylinder.fill")
                    .foregroundColor(.blue)
                Text("Database Information")
                    .font(.headline)
                Spacer()
            }
            
            let storageInfo = viewModel.getStorageInfo()
            
            InfoRow(label: "Total Locations", value: "\(storageInfo.totalLocations)")
            InfoRow(label: "Active Locations", value: "\(storageInfo.activeLocations)")
            InfoRow(label: "Soft Deleted", value: "\(storageInfo.softDeletedLocations)")
            InfoRow(label: "Archived", value: "\(storageInfo.archivedLocations)")
            InfoRow(label: "Estimated Size", value: storageInfo.estimatedSize)
            
            if let oldestDate = storageInfo.oldestLocationDate {
                InfoRow(label: "Oldest Event", value: oldestDate.formatted(date: .abbreviated, time: .omitted))
            }
            
            if let newestDate = storageInfo.newestLocationDate {
                InfoRow(label: "Newest Event", value: newestDate.formatted(date: .abbreviated, time: .omitted))
            }
            
            // Today's count
            let todaysCount = getTodaysLocationCount()
            InfoRow(label: "Today's Locations", value: "\(todaysCount)", highlight: todaysCount > 0)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func getTodaysLocationCount() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        return viewModel.locations.filter { location in
            location.syncStatus != .deleted &&
            location.startTime >= today && location.startTime < tomorrow
        }.count
    }
}

// MARK: - Sync Actions Section

struct SyncActionsSection: View {
    let viewModel: LocationsViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "arrow.clockwise")
                    .foregroundColor(.green)
                Text("Sync Actions")
                    .font(.headline)
                Spacer()
            }
            
            Button(action: {
                Task {
                    await viewModel.syncTodaysEvents()
                }
            }) {
                HStack {
                    if viewModel.isSyncing {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "calendar.badge.plus")
                    }
                    Text("Sync Today's Events")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.isSyncing ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(viewModel.isSyncing)
            
            if viewModel.isSyncing, let progress = viewModel.syncProgress {
                VStack(alignment: .leading, spacing: 4) {
                    Text(progress.currentStep)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ProgressView(value: progress.progress)
                        .progressViewStyle(LinearProgressViewStyle())
                    
                    if progress.totalItems > 0 {
                        Text("\(progress.itemsProcessed) of \(progress.totalItems) items processed")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Sync Results Section

struct SyncResultsSection: View {
    let viewModel: LocationsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.orange)
                Text("Last Sync Results")
                    .font(.headline)
                Spacer()
            }
            
            if let syncResult = viewModel.lastSyncResult {
                VStack(spacing: 8) {
                    InfoRow(label: "Sync Date", value: syncResult.syncDate.formatted(date: .abbreviated, time: .shortened))
                    InfoRow(label: "Duration", value: String(format: "%.2f seconds", syncResult.syncDuration))
                    InfoRow(label: "Total Events", value: "\(syncResult.totalEvents)")
                    InfoRow(label: "New Locations", value: "\(syncResult.newLocations)", highlight: syncResult.newLocations > 0)
                    InfoRow(label: "Updated", value: "\(syncResult.updatedLocations)", highlight: syncResult.updatedLocations > 0)
                    InfoRow(label: "Deleted", value: "\(syncResult.deletedLocations)", highlight: syncResult.deletedLocations > 0)
                    InfoRow(label: "Skipped", value: "\(syncResult.skippedLocations)")
                    InfoRow(label: "Geocoding Failures", value: "\(syncResult.geocodingFailures)", highlight: syncResult.geocodingFailures > 0)
                    InfoRow(label: "Errors", value: "\(syncResult.errors.count)", highlight: !syncResult.errors.isEmpty)
                    
                    if !syncResult.errors.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Errors:")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.red)
                            
                            ForEach(Array(syncResult.errors.enumerated()), id: \.offset) { index, error in
                                Text("• \(error.localizedDescription)")
                                    .font(.caption2)
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.top, 4)
                    }
                    
                    // Status indicator
                    HStack {
                        Image(systemName: syncResult.isSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundColor(syncResult.isSuccess ? .green : .orange)
                        Text(syncResult.isSuccess ? "Sync Successful" : "Sync Completed with Issues")
                            .font(.caption)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    .padding(.top, 8)
                }
            } else {
                Text("No sync performed yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Today's Locations Section

struct TodaysLocationsSection: View {
    let viewModel: LocationsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.purple)
                Text("Today's Locations")
                    .font(.headline)
                Spacer()
            }
            
            let todaysLocations = getTodaysLocations()
            
            if todaysLocations.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text("No locations found for today")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Try syncing your calendar events to see today's locations with addresses.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(todaysLocations) { location in
                        LocationRowView(location: location)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func getTodaysLocations() -> [Location] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        return viewModel.locations.filter { location in
            location.syncStatus != .deleted &&
            location.startTime >= today && location.startTime < tomorrow
        }.sorted { $0.startTime < $1.startTime }
    }
}

// MARK: - Danger Zone Section

struct DangerZoneSection: View {
    let viewModel: LocationsViewModel
    @Binding var showingHardDeleteConfirmation: Bool
    @Binding var showingClearAllConfirmation: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text("Danger Zone")
                    .font(.headline)
                    .foregroundColor(.red)
                Spacer()
            }
            
            VStack(spacing: 8) {
                if viewModel.hasSoftDeletedLocations {
                    Button(action: {
                        showingHardDeleteConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Clean Up Deleted Items (\(viewModel.locationCounts.softDeleted))")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                
                Button(action: {
                    showingClearAllConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "trash.circle.fill")
                        Text("Clear All Database (\(viewModel.locationCounts.total) items)")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
            
            Text("⚠️ These actions cannot be undone. Use with caution.")
                .font(.caption)
                .foregroundColor(.red)
                .padding(.top, 4)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Supporting Views

struct InfoRow: View {
    let label: String
    let value: String
    var highlight: Bool = false
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(highlight ? .semibold : .regular)
                .foregroundColor(highlight ? .primary : .secondary)
        }
    }
}

struct LocationRowView: View {
    let location: Location
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(location.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    if let address = location.address {
                        Text(address)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(location.startTime.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    StatusBadge(syncStatus: location.syncStatus, geocodingStatus: location.geocodingStatus)
                }
            }
            
            // Additional info row
            HStack {
                if location.isUserModified {
                    Label("Modified", systemImage: "pencil")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
                
                if location.isArchived {
                    Label("Archived", systemImage: "archivebox")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                if !location.userTags.isEmpty {
                    Label("\(location.userTags.count) tags", systemImage: "tag")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                if location.geocodingStatus == .success {
                    Text("📍 \(String(format: "%.4f", location.latitude)), \(String(format: "%.4f", location.longitude))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
    }
}

struct StatusBadge: View {
    let syncStatus: SyncStatus
    let geocodingStatus: GeocodingStatus
    
    var body: some View {
        HStack(spacing: 4) {
            // Sync status
            Circle()
                .fill(syncStatusColor)
                .frame(width: 8, height: 8)
            
            // Geocoding status
            Image(systemName: geocodingIcon)
                .font(.caption2)
                .foregroundColor(geocodingColor)
        }
    }
    
    private var syncStatusColor: Color {
        switch syncStatus {
        case .synced: return .green
        case .modified: return .orange
        case .deleted: return .red
        case .pending: return .yellow
        case .error: return .red
        }
    }
    
    private var geocodingIcon: String {
        switch geocodingStatus {
        case .success: return "location.fill"
        case .pending: return "location.circle"
        case .failed: return "location.slash"
        case .retryLater: return "location.circle.fill"
        case .notNeeded: return "location"
        }
    }
    
    private var geocodingColor: Color {
        switch geocodingStatus {
        case .success: return .green
        case .pending: return .orange
        case .failed: return .red
        case .retryLater: return .yellow
        case .notNeeded: return .gray
        }
    }
}

// MARK: - Preview

#Preview {
    CalendarSyncTestView(modelContainer: {
        let container = try! ModelContainer(for: Location.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        return container
    }())
}
