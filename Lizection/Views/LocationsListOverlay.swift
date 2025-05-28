//
//  LocationsListOverlay.swift
//  Lizection
//
//  Created by Rongwei Ji on 5/27/25.
//


// MARK: - Locations List Overlay
import SwiftUI

let noLocationsText: String = "No Upcoming Locations"
let noLocationsSubtitle: String = "Add events with locations to your calendar; we'll sync them here."

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
                        Text(noLocationsText)
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text(noLocationsSubtitle)
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


#Preview("Not Empty") {
    LocationsListOverlay(
        locations: [
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
        ],
        selectedLocationId: nil,
        onLocationTap: { _ in }
    )
}


#Preview("Empty List") {
    LocationsListOverlay(
        locations: [        ],
        selectedLocationId: nil,
        onLocationTap: { _ in }
    )
}
