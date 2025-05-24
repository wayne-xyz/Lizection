//
//  LocationsMapView.swift
//  Lizection
//
//  Created by Rongwei Ji on 5/23/25.
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
    
    @State private var isListExpanded = false
    @State private var listHeight: CGFloat = 200
    
    private let minListHeight: CGFloat = 120
    private let maxListHeight: CGFloat = 500
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                
                // MARK: - Map Background
                Map(position: $cameraPosition) {
                    // Map annotations will go here later
                }
                .mapStyle(.standard)
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                    MapScaleView()
                }
                .ignoresSafeArea(.all)
                
                // MARK: - Floating List Overlay
                VStack(spacing: 0) {
                    
                    // Drag Handle
                    DragHandle()
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                toggleListExpansion()
                            }
                        }
                    
                    // List Content
                    LocationsListOverlay()
                        .frame(height: listHeight)
                        .clipped()
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
                            let newHeight = listHeight - value.translation.height
                            listHeight = max(minListHeight, min(maxListHeight, newHeight))
                        }
                        .onEnded { value in
                            withAnimation(.easeOut(duration: 0.3)) {
                                snapToNearestHeight(velocity: value.velocity.height)
                            }
                        }
                )
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
    
    // MARK: - Helper Methods
    
    private func toggleListExpansion() {
        if listHeight <= minListHeight + 50 {
            listHeight = maxListHeight
            isListExpanded = true
        } else {
            listHeight = minListHeight
            isListExpanded = false
        }
    }
    
    private func snapToNearestHeight(velocity: CGFloat) {
        let midPoint = (minListHeight + maxListHeight) / 2
        
        if velocity > 500 { // Fast downward swipe
            listHeight = minListHeight
            isListExpanded = false
        } else if velocity < -500 { // Fast upward swipe
            listHeight = maxListHeight
            isListExpanded = true
        } else if listHeight < midPoint {
            listHeight = minListHeight
            isListExpanded = false
        } else {
            listHeight = maxListHeight
            isListExpanded = true
        }
    }
}

// MARK: - Drag Handle Component

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
                    Text("Locations")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("0 locations found")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: {
                        // Filter action
                    }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: {
                        // Search action
                    }) {
                        Image(systemName: "magnifyingglass.circle")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
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
                Image(systemName: "location.slash")
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
