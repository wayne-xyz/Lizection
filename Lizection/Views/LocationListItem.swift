//
//  LocationListItem.swift
//  Lizection
//
//  Created by Rongwei Ji on 2/18/25.
//
// This is the  item view in the mainlist
// MARK: - Location List Item
import SwiftUI
import MapKit

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
                            .foregroundColor(Color("MainColor"))
                            .opacity(isSelected ? 1.0 : 0.0)
                            .animation(.easeInOut(duration: 0.3), value: isSelected)
                    
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
                
                // Add Navigation Button
                if isOnMap {
                    Button(action: openInMaps) {
                        Image(systemName: "arrow.turn.up.right")
                            .font(.title3)
                            .foregroundColor(Color("MainColor"))
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .opacity(0.9) 
                .shadow(color: isSelected ? .black.opacity(0.1) : .clear, radius: 2, x: 0, y: 1)
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
    
    // Add this function to handle opening Maps
    private func openInMaps() {
        let mapItem = MKMapItem(placemark: MKPlacemark(
            coordinate: CLLocationCoordinate2D(
                latitude: location.latitude,
                longitude: location.longitude
            )
        ))
        mapItem.name = location.name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}




#Preview("Light Mode") { // Provide the name directly to the macro
    LocationListItem(
        location: Location(
            name: "WWDC Event (Light)",
            address: "San Jose Convention Center",
            latitude: 37.3300,
            longitude: -121.8889,
            startTime: Date().addingTimeInterval(1800),
            endTime: Date().addingTimeInterval(5400),
            geocodingStatus: .success
        ),
        isSelected: true,
        onTap: {}
    )
    .preferredColorScheme(.light) // Set the color scheme for this specific preview
}

#Preview("Dark Mode") { // Provide the name directly to the macro
    LocationListItem(
        location: Location(
            name: "WWDC Event (Dark)",
            address: "San Jose Convention Center",
            latitude: 37.3300,
            longitude: -121.8889,
            startTime: Date().addingTimeInterval(1800),
            endTime: Date().addingTimeInterval(5400),
            geocodingStatus: .success
        ),
        isSelected: false,
        onTap: {}
    )
    .preferredColorScheme(.dark) // This is the key for Dark Mode!
}
#Preview("Dark Mode") { // Provide the name directly to the macro
    LocationListItem(
        location: Location(
            name: "WWDC Event (Dark)",
            address: "San Jose Convention Center",
            latitude: 37.3300,
            longitude: -121.8889,
            startTime: Date().addingTimeInterval(1800),
            endTime: Date().addingTimeInterval(5400),
            geocodingStatus: .success
        ),
        isSelected: true,
        onTap: {}
    )
    .preferredColorScheme(.dark) // This is the key for Dark Mode!
}
