//
//  CalendarServiceProtocol.swift
//  Lizection
//
//  Created by Rongwei Ji on 5/22/25.
//

import Foundation
import EventKit

protocol CalendarServiceProtocol {
    func requestCalendarAccess() async throws -> Bool
    func fetchCalendarEvents(from startDate: Date, to endDate: Date) async throws -> [EKEvent]
    func fetchEventsWithLocation(from startDate: Date, to endDate: Date) async throws -> [EKEvent]
}
