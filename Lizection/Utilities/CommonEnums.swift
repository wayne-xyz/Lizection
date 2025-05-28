//
//  Untitled.swift
//  Lizection
//
//  Created by Rongwei Ji on 5/23/25.
//

// CommonEnums.swift

import Foundation // For Codable

enum SyncStatus: String, Codable, CaseIterable,Equatable {
    case synced = "synced"
    case modified = "modified"
    case deleted = "deleted"
    case pending = "pending"
    case error = "error"
}

enum GeocodingStatus: String, Codable, CaseIterable,Equatable {
    case notNeeded = "not_needed"
    case pending = "pending"
    case success = "success"
    case failed = "failed"
    case retryLater = "retry_later"
}


// MARK: - Date Range Helper (if you still need it outside of sync service)
enum DateRange {
    case today
    case week
    case month

    func dateRange(from baseDate: Date = Date()) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        switch self {
        case .today:
            let startOfDay = calendar.startOfDay(for: baseDate)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? baseDate
            return (startOfDay, endOfDay)
        case .week:
            let start = calendar.date(byAdding: .weekOfYear, value: -1, to: baseDate) ?? baseDate
            let end = calendar.date(byAdding: .weekOfYear, value: 1, to: baseDate) ?? baseDate
            return (start, end)
        case .month:
            let start = calendar.date(byAdding: .month, value: -1, to: baseDate) ?? baseDate
            let end = calendar.date(byAdding: .month, value: 1, to: baseDate) ?? baseDate
            return (start, end)
        }
    }
}
