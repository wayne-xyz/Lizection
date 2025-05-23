//
//  Errors.swift
//  Lizection
//
//  Created by Rongwei Ji on 5/22/25.
//

import Foundation

enum CalendarError: Error, LocalizedError {
    case accessDenied
    case noLocationFound
    case geocodingFailed
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Calendar access denied. Please enable calendar access in Settings."
        case .noLocationFound:
            return "No location information found in the event."
        case .geocodingFailed:
            return "Failed to convert address to coordinates."
        case .unknownError:
            return "An unknown error occurred."
        }
    }
}
