//
//  MapView.swift
//  Lizection
//
//  Created by Rongwei Ji on 5/24/25.
//

import SwiftUI
import MapKit

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
    
    // Initialize state properties. listHeight starts at 0 and will be set dynamically
    // in .onAppear based on the screen's geometry.
    init() {
        _listHeight = State(initialValue: 0) // Placeholder, actual height set in .onAppear
        _currentExpansionState = State(initialValue: .initial)
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
                    // Map annotations will go here later
                }
                .mapStyle(.standard)
                .ignoresSafeArea(.all)
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
                    DragHandle()
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
                    LocationsListOverlay()
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
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    // Map style toggle action
                }) {
                    Image(systemName: "map")
                }
            }
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

// MARK: - Drag Handle Component
let DRAGHANDLE_TITLE="Today"

struct DragHandle: View {
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
                    Text(DRAGHANDLE_TITLE)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("0 locations found")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
//                HStack(spacing: 12) {
//                    Button(action: {
//                        // Filter action
//                    }) {
//                        Image(systemName: "line.3.horizontal.decrease.circle")
//                            .font(.title2)
//                            .foregroundColor(.blue)
//                    }
//                    
//                    Button(action: {
//                        // Search action
//                    }) {
//                        Image(systemName: "magnifyingglass.circle")
//                            .font(.title2)
//                            .foregroundColor(.blue)
//                    }
//                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }
}

// MARK: - Locations List Overlay

struct LocationsListOverlay: View {
    var body: some View {
        VStack(spacing: 0) {
            
            // Empty State
            VStack(spacing: 16) {
                Image(.lizpinSlash)
                    .font(.system(size: 50))
                    .foregroundColor(.gray.opacity(0.6))
                
                VStack(spacing: 8) {
                    Text("No Locations Found")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("Sync your calendar events to see locations on the map")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                Button(action: {
                    // Sync action
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Sync Calendar")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .cornerRadius(20)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 20)
            
            Spacer()
        }
        .background(Color.clear)
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        MainView()
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
