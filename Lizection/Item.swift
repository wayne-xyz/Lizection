//
//  Item.swift
//  Lizection
//
//  Created by Rongwei Ji on 2/16/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
