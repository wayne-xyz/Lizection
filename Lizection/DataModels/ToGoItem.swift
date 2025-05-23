import Foundation
import SwiftData
import CoreLocation

@Model
class ToGoItem {
    var id: UUID
    var name: String
    var address: String?
    var latitude: Double
    var longitude: Double
    var startTime: Date
    var endTime: Date
    var eventIdentifier: String? // from the calendar

    init(
        id: UUID = UUID(),
        name: String,
        address: String? = nil,
        latitude: Double,
        longitude: Double,
        startTime: Date,
        endTime: Date,
        eventIdentifier: String? = nil
    ) {
        self.id = id
        self.name=name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.startTime = startTime
        self.endTime = endTime
        self.eventIdentifier = eventIdentifier
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
