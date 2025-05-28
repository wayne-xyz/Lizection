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


// MARK: - Sync Error Types

enum SyncError: Error, LocalizedError {
    case calendarAccessDenied
    case geocodingFailed(String)
    case databaseError(String)
    case noEventsFound
    case syncInProgress
    case invalidDateRange
    case eventProcessingFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .calendarAccessDenied:
            return "Calendar access is required for syncing events"
        case .geocodingFailed(let address):
            return "Failed to geocode address: \(address)"
        case .databaseError(let message):
            return "Database error: \(message)"
        case .noEventsFound:
            return "No events with location found for specified date range"
        case .syncInProgress:
            return "Sync is already in progress"
        case .invalidDateRange:
            return "Invalid date range provided"
        case .eventProcessingFailed(let message):
            return "Failed to process event: \(message)"
        }
    }
}
