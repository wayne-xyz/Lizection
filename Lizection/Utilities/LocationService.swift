//
//  LocationService.swift
//  Lizection
//
//  Created by Rongwei Ji on 5/22/25.
//

import Foundation
import CoreLocation

class LocationService {
    private let geocoder = CLGeocoder()
    
    func geocodeAddress(_ address: String) async throws -> CLLocationCoordinate2D {
        let placemarks = try await geocoder.geocodeAddressString(address)
        
        guard let coordinate = placemarks.first?.location?.coordinate else {
            throw CalendarError.geocodingFailed
        }
        
        return coordinate
    }
}
