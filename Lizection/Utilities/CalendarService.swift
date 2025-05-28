//
//  CalendarService.swift
//  Lizection
//
//  Created by Rongwei Ji on 5/22/25.
//

import Foundation
import EventKit

class CalendarService: CalendarServiceProtocol {
    private let eventStore = EKEventStore()
    
    func requestCalendarAccess() async throws -> Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        
        switch status {
        case .notDetermined:
            return try await eventStore.requestFullAccessToEvents()
        case .authorized, .fullAccess:
            return true
        case .denied, .restricted, .writeOnly:
            throw CalendarError.accessDenied
        @unknown default:
            throw CalendarError.unknownError
        }
    }
    
    func fetchCalendarEvents(from startDate: Date, to endDate: Date) async throws -> [EKEvent] {
        guard try await requestCalendarAccess() else {
            throw CalendarError.accessDenied
        }
        
        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: nil
        )
        
        return eventStore.events(matching: predicate)
    }
    
    func fetchEventsWithLocation(from startDate: Date, to endDate: Date) async throws -> [EKEvent] {
        let allEvents = try await fetchCalendarEvents(from: startDate, to: endDate)
        return allEvents.filter { event in
            guard let location = event.location,
                  !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return false
            }
            return true
        }
    }
}
