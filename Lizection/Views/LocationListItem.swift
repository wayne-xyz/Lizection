//
//  LocationListItem.swift
//  Lizection
//
//  Created by Rongwei Ji on 2/18/25.
//
// This is the  item view in the mainlist
// MARK: - Location List Item
import SwiftUI

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
        isSelected: false,
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
