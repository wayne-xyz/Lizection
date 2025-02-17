//
//  MapItem.swift
//  Lizection
//
//  Created by Rongwei Ji on 2/16/25.
//

import Foundation
import SwiftData
import CoreLocation
import UIKit

@Model
final class MapItem {
    var id: UUID
    var name: String // location's name, Starbucks
    var address: String //  5331 E Mockingbird Ln Dallas, TX  75206 United States
    var longitude: Double
    var latitude: Double
    var eventName: String
    var imageData: Data?
    
    
    init(id: UUID, name: String, address: String,  coordinates: CLLocationCoordinate2D, eventName: String, image:UIImage? ) {
        self.id = id
        self.name = name
        self.address = address
        self.latitude=coordinates.latitude
        self.longitude=coordinates.longitude
        self.eventName=eventName
        self.imageData=image?.jpegData(compressionQuality: 1.0)
        
    }
    
    var coordinates:CLLocationCoordinate2D{
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var image:UIImage?{
        guard let data=imageData else{
            return nil
        }
        return UIImage(data: data)
    }


}
