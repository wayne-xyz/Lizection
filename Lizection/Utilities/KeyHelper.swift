//
//  KeyHelper.swift
//  Lizection
//
//  Created by Rongwei Ji on 2/18/25.
//


import Foundation

struct KeyHelper {
    private static var keyDictionary: [String: Any] {
        guard let url = Bundle.main.url(forResource: "Key", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            fatalError("Key.plist not found or invalid format")
        }
        return dict
    }
    
    static var arcGISKey: String {
        guard let key = keyDictionary["ArcGIS_Dev_API_key"] as? String, !key.isEmpty else {
            fatalError("ArcGIS API Key is missing or empty in Key.plist")
        }
        return key
    }
    
    static var arcGISLicense: String {
        guard let license = keyDictionary["ArcGIS_Runtime_license_string"] as? String, !license.isEmpty else {
            fatalError("ArcGIS License String is missing or empty in Key.plist")
        }
        return license
    }
}

