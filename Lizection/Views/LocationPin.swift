//
//  LocationPin.swift
//  Lizection
//
//  Created by Rongwei Ji on 5/27/25.
//

// MARK: - Location Pin Component
import SwiftUI

struct LocationPin: View {
    let location: Location
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 2) {
            Image("lizpin.fill") // Your custom SF symbol
                .font(.largeTitle)
                .foregroundColor(isSelected ? Color("MainColor") : pinColor)
                .shadow(radius: 10)
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

#Preview("Unselected") {
    LocationPin(
        location:Location(
            name: "WWDC Event (Light)",
            address: "San Jose Convention Center",
            latitude: 37.3300,
            longitude: -121.8889,
            startTime: Date().addingTimeInterval(1800),
            endTime: Date().addingTimeInterval(5400),
            geocodingStatus: .success
        ),
        isSelected: false
    )
}

#Preview("Selected") {
    LocationPin(
        location:Location(
            name: "WWDC Event (Light)",
            address: "San Jose Convention Center",
            latitude: 37.3300,
            longitude: -121.8889,
            startTime: Date().addingTimeInterval(1800),
            endTime: Date().addingTimeInterval(5400),
            geocodingStatus: .success
        ),
        isSelected: true
    )
}

#Preview("Dark Selected") {
    LocationPin(
        location:Location(
            name: "WWDC Event (Light)",
            address: "San Jose Convention Center",
            latitude: 37.3300,
            longitude: -121.8889,
            startTime: Date().addingTimeInterval(1800),
            endTime: Date().addingTimeInterval(5400),
            geocodingStatus: .success
        ),
        isSelected: true
    )
    .preferredColorScheme(.dark)
}
