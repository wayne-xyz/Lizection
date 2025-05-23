//
//  MockEventStore.swift
//  Lizection
//
//  Created by Rongwei Ji on 5/23/25.
//

import Foundation
import EventKit

protocol EventStoreProtocol {
    func authorizationStatus(for entityType: EKEntityType) -> EKAuthorizationStatus
    func requestFullAccessToEvents() async throws -> Bool
    func predicateForEvents(withStart startDate: Date, end endDate: Date, calendars: [EKCalendar]?) -> NSPredicate
    func events(matching predicate: NSPredicate) -> [EKEvent]
}


class MockEventStore: EventStoreProtocol {
    var mockAuthorizationStatus: EKAuthorizationStatus = .notDetermined
    var mockRequestFullAccessResult: Bool = true
    var mockRequestFullAccessError: Error?
    var mockEvents: [EKEvent] = []
    var predicateStart: Date?
    var predicateEnd: Date?
    var requestAccessCallCount = 0

    func authorizationStatus(for entityType: EKEntityType) -> EKAuthorizationStatus {
        return mockAuthorizationStatus
    }

    func requestFullAccessToEvents() async throws -> Bool {
        requestAccessCallCount += 1
        if let error = mockRequestFullAccessError {
            throw error
        }
        return mockRequestFullAccessResult
    }

    func predicateForEvents(withStart startDate: Date, end endDate: Date, calendars: [EKCalendar]?) -> NSPredicate {
        self.predicateStart = startDate
        self.predicateEnd = endDate
        return NSPredicate(value: true)
    }

    func events(matching predicate: NSPredicate) -> [EKEvent] {
        return mockEvents
    }

    static func createMockEvent(
        title: String,
        startDate: Date,
        endDate: Date,
        location: String? = nil,
        hasLocation: Bool = false
    ) -> EKEvent {
        let event = EKEvent(eventStore: EKEventStore())
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        if hasLocation {
            event.location = location ?? "Some Location"
        }
        return event
    }
}
