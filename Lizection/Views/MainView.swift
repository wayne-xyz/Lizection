//
//  MapView.swift
//  Lizection
//
//  Created by Rongwei Ji on 5/24/25.
//

import SwiftUI
import MapKit
import SwiftData

struct MainView: View {
    @State private var cameraPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // San Francisco
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    )
    
    // Define the possible expansion states for the list
    enum ListExpansionState: CaseIterable, Comparable {
        case minimized // Smallest height
        case initial   // Default/medium height
        case maximized // Largest height
    }
    
    // @State for the current height of the list overlay
    @State private var listHeight: CGFloat
    // @State for tracking the current expansion state
    @State private var currentExpansionState: ListExpansionState
    // Add this line within MainView, after your @State currentExpansionState
    @State private var impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    @StateObject private var locationManager = LocationManager()
    
    // MARK: - ViewModel Integration
    @StateObject private var locationsViewModel: LocationsViewModel
    @State private var selectedLocationId: UUID?
    
    // Initialize state properties. listHeight starts at 0 and will be set dynamically
    // in .onAppear based on the screen's geometry.
    init(modelContainer: ModelContainer) {
        _listHeight = State(initialValue: 0) // Placeholder, actual height set in .onAppear
        _currentExpansionState = State(initialValue: .initial)
        _locationsViewModel = StateObject(wrappedValue: LocationsViewModel(modelContainer: modelContainer))
    }
    
    var body: some View {
        GeometryReader { geometry in
            // Define adaptive heights based on the current device's screen geometry
            // These values will scale proportionally across different iPhone sizes
            let adaptiveMinListHeight = geometry.size.height * 0.15 // 15% of screen height
            let adaptiveInitialListHeight = geometry.size.height * 0.4 // 40% of screen height
            let adaptiveMaxListHeight = geometry.size.height * 0.7 // 70% of screen height
            
            ZStack(alignment: .bottom) {
                // MARK: - Map Background
                Map(position: $cameraPosition) {
                    // Map annotations for today's upcoming events
                    ForEach(locationsViewModel.filteredLocations, id: \.id) { location in
                        if location.geocodingStatus == .success {
                            Annotation(
                                location.name,
                                coordinate: location.coordinate,
                                anchor: .bottom
                            ) {
                                LocationPin(
                                    location: location,
                                    isSelected: selectedLocationId == location.id
                                )
                                .onTapGesture {
                                    selectLocation(location)
                                }
                            }
                        }
                    }
                }
                .mapStyle(.standard)
                .ignoresSafeArea(.all)
                .onAppear {
                    // Focus on first location if available
                    if let firstLocation = locationsViewModel.filteredLocations.first,
                       firstLocation.geocodingStatus == .success {
                        centerOnLocation(firstLocation)
                        selectedLocationId = firstLocation.id
                    }
                }
                
                // Custom location button positioned anywhere
                VStack {
                    HStack {
                        Spacer()
                        Button(action: centerOnUserLocation) {
                            Image(systemName: "location.fill")
                                .foregroundColor(.blue)
                                .frame(width: 44, height: 44)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(radius: 2)
                        }
                        .padding(.trailing, 16)
                    }
                    .padding(.top, 28) // Avoid status bar
                    
                    Spacer()
                }
                
                // MARK: - Floating List Overlay
                VStack(spacing: 0) {
                    // Drag Handle
                    DragHandle(
                        locationsCount: locationsViewModel.filteredLocations.count,
                        isSyncing: locationsViewModel.isSyncing
                    )
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            // Cycle through the three states on tap
                            cycleListExpansionState(
                                min: adaptiveMinListHeight,
                                initial: adaptiveInitialListHeight,
                                max: adaptiveMaxListHeight
                            )
                        }
                    }
                    
                    // List Content
                    LocationsListOverlay(
                        locations: locationsViewModel.filteredLocations,
                        selectedLocationId: selectedLocationId,
                        onLocationTap: { location in
                            selectLocation(location)
                            centerOnLocation(location)
                        }
                    )
                    .frame(height: listHeight) // Apply the current dynamic height
                    .clipped() // Ensures content doesn't overflow if height is too small
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 0)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            // Adjust height based on drag, clamped within min and max limits
                            let newHeight = listHeight - value.translation.height
                            listHeight = max(adaptiveMinListHeight, min(adaptiveMaxListHeight, newHeight))
                        }
                        .onEnded { value in
                            withAnimation(.easeOut(duration: 0.3)) {
                                // Snap to the nearest of the three states after drag ends
                                snapToNearestHeight(
                                    velocity: value.velocity.height,
                                    min: adaptiveMinListHeight,
                                    initial: adaptiveInitialListHeight,
                                    max: adaptiveMaxListHeight
                                )
                            }
                        }
                )
            }
            // Set the initial list height when the view first appears,
            // using the adaptive initial height calculated from geometry.
            .onAppear {
                if listHeight == 0 { // Only set if it's the initial placeholder value
                    listHeight = adaptiveInitialListHeight
                }
                setupInitialData()
            }
        }
        .navigationBarHidden(true)


    }
    
    // MARK: - Setup and Data Loading
    
    private func setupInitialData() {
        // Set filter to show today's upcoming events
        locationsViewModel.currentFilter = .today
        
        // Start background sync
        Task {
            await performBackgroundSync()
        }
    }
    
    private func performBackgroundSync() async {
        await locationsViewModel.syncTodaysEvents()
    }
    
    // MARK: - Location Actions
    
    private func selectLocation(_ location: Location) {
        selectedLocationId = location.id
        impactFeedbackGenerator.impactOccurred()
    }
    
    private func centerOnLocation(_ location: Location) {
        guard location.geocodingStatus == .success else { return }
        
        withAnimation(.easeInOut(duration: 0.5)) {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: location.coordinate,
                    latitudinalMeters: 1000,
                    longitudinalMeters: 1000
                )
            )
        }
    }
    
    private func centerOnUserLocation() {
        if let location = locationManager.currentLocation {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: location.coordinate,
                    latitudinalMeters: 1000,
                    longitudinalMeters: 1000
                )
            )
        }
    }
    
    // MARK: - Helper Methods
    
    /// Cycles the list through its three expansion states on tap (min -> initial -> max -> min).
    private func cycleListExpansionState(min: CGFloat, initial: CGFloat, max: CGFloat) {
        switch currentExpansionState {
        case .minimized:
            currentExpansionState = .initial
            listHeight = initial
            impactFeedbackGenerator.impactOccurred()
        case .initial:
            currentExpansionState = .maximized
            listHeight = max
            impactFeedbackGenerator.impactOccurred()
        case .maximized:
            currentExpansionState = .minimized
            listHeight = min
            impactFeedbackGenerator.impactOccurred()
        }
    }
    
    /// Snaps the list to the nearest of the three defined heights after a drag gesture ends.
    /// Also handles fast upward/downward swipes for immediate snapping.
    private func snapToNearestHeight(velocity: CGFloat, min: CGFloat, initial: CGFloat, max: CGFloat) {
        let snapPoints = [min, initial, max].sorted() // Ensure points are sorted for correct logic
        let swipeThreshold: CGFloat = 200 // Velocity threshold for a "fast" swipe
        
        // Prioritize fast swipes for immediate snapping
        if velocity > swipeThreshold { // Fast downward swipe
            currentExpansionState = .minimized
            listHeight = min
            return
        } else if velocity < -swipeThreshold { // Fast upward swipe
            currentExpansionState = .maximized
            listHeight = max
            return
        }
        
        // If not a fast swipe, find the closest snap point
        var nearestHeight = initial // Default to initial if no other is clearly closer
        var minDistance: CGFloat = .greatestFiniteMagnitude // Initialize with a very large value
        
        for height in snapPoints {
            let distance = abs(listHeight - height)
            if distance < minDistance {
                minDistance = distance
                nearestHeight = height
            }
        }
        
        listHeight = nearestHeight // Apply the snapped height
        
        // Update the current state based on the snapped height
        if listHeight == min {
            currentExpansionState = .minimized
        } else if listHeight == initial {
            currentExpansionState = .initial
        } else if listHeight == max {
            currentExpansionState = .maximized
        }
    }
}

// MARK: - Location Pin Component

struct LocationPin: View {
    let location: Location
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 2) {
            Image("lizpin.fill") // Your custom SF symbol
                .font(.title2)
                .foregroundColor(isSelected ? .red : pinColor)
                .background(
                    Circle()
                        .fill(.white)
                        .frame(width: 32, height: 32)
                        .shadow(radius: 2)
                )
                .scaleEffect(isSelected ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
    }
    
    private var pinColor: Color {
        // Different colors based on geocoding status and time
        if location.geocodingStatus != .success {
            return .gray
        }
        
        let now = Date()
        if location.startTime > now {
            return .blue // Upcoming
        } else if location.endTime > now {
            return .green // Current
        } else {
            return .orange // Past
        }
    }
}

// MARK: - Drag Handle Component

struct DragHandle: View {
    let locationsCount: Int
    let isSyncing: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            // Visual drag indicator
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.secondary.opacity(0.5))
                .frame(width: 40, height: 4)
                .padding(.top, 8)
            
            // Header with title and controls
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("Today")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if isSyncing {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    
                    Text("\(locationsCount) upcoming locations")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }
}

// MARK: - Locations List Overlay

struct LocationsListOverlay: View {
    let locations: [Location]
    let selectedLocationId: UUID?
    let onLocationTap: (Location) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            if locations.isEmpty {
                // Empty State
                VStack(spacing: 16) {
                    Image("lizpin.slash") // Your custom SF symbol
                        .font(.system(size: 50))
                        .foregroundColor(.gray.opacity(0.6))
                    
                    VStack(spacing: 8) {
                        Text("No Upcoming Locations")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text("Sync your calendar events to see today's upcoming locations")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, 20)
            } else {
                // Locations List
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(locations, id: \.id) { location in
                            LocationListItem(
                                location: location,
                                isSelected: selectedLocationId == location.id,
                                onTap: { onLocationTap(location) }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
            }
            
            Spacer()
        }
        .background(Color.clear)
    }
}

// MARK: - Location List Item

struct LocationListItem: View {
    let location: Location
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Location Pin Indicator
                VStack {
                    Image("lizpin.fill") // Your custom SF symbol
                        .font(.title3)
                        .foregroundColor(pinColor)
                    Spacer()
                }
                
                // Location Info
                VStack(alignment: .leading, spacing: 4) {
                    // Location Name
                    Text(location.name)
                        .font(isOnMap ? .subheadline : .caption)
                        .fontWeight(isOnMap ? .semibold : .medium)
                        .foregroundColor(isOnMap ? .primary : .secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    // Address
                    if let address = location.address {
                        Text(address)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    
                    // Start Time
                    Text(location.startTime.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                // Status Indicators
                VStack(alignment: .trailing, spacing: 4) {
                    // Geocoding Status
                    Image(systemName: geocodingIcon)
                        .font(.caption)
                        .foregroundColor(geocodingColor)
                    
                    // Time Status
                    timeStatusView
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemBackground))
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Computed Properties
    
    private var isOnMap: Bool {
        location.geocodingStatus == .success
    }
    
    private var pinColor: Color {
        if !isOnMap {
            return .gray
        }
        
        let now = Date()
        if location.startTime > now {
            return .blue // Upcoming
        } else if location.endTime > now {
            return .green // Current
        } else {
            return .orange // Past
        }
    }
    
    private var geocodingIcon: String {
        switch location.geocodingStatus {
        case .success: return "checkmark.circle.fill"
        case .pending: return "clock.circle"
        case .failed: return "xmark.circle.fill"
        case .retryLater: return "arrow.clockwise.circle"
        case .notNeeded: return "minus.circle"
        }
    }
    
    private var geocodingColor: Color {
        switch location.geocodingStatus {
        case .success: return .green
        case .pending: return .orange
        case .failed: return .red
        case .retryLater: return .yellow
        case .notNeeded: return .gray
        }
    }
    
    @ViewBuilder
    private var timeStatusView: some View {
        let now = Date()
        let timeUntilStart = location.startTime.timeIntervalSince(now)
        
        if timeUntilStart > 0 {
            // Upcoming event
            VStack(alignment: .trailing, spacing: 2) {
                Text("in")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(formatTimeInterval(timeUntilStart))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }
        } else if location.endTime > now {
            // Current event
            Text("Now")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.green)
        } else {
            // Past event
            Text("Past")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        MainView(modelContainer: {
            let container = try! ModelContainer(for: Location.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            return container
        }())
    }
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var currentLocation: CLLocation?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }
}
