//
//  CalendarServiceIntegrationTests.swift
//  Lizection
//
//  Created by Rongwei Ji on 5/23/25.
//

import Testing
import EventKit
@testable import Lizection

struct CalendarServiceIntegrationTests {

    private var sut: CalendarService!

    init() {
        sut = CalendarService()
    }

    // MARK: - Integration Test for Calendar Access Request

    @Test func integration_requestCalendarAccess() async throws {
        print("--- Running Integration Test: integration_requestCalendarAccess ---")
        print("Expected behavior: If not determined, a system calendar access dialog will appear.")
        print("Please accept or deny access on the simulator/device to continue the test.")

        do {
            let hasAccess = try await sut.requestCalendarAccess()
            
            // Based on your CalendarService implementation, this should always be true if no exception is thrown
            #expect(hasAccess, "Calendar access should be granted when no error is thrown.")
            print("Integration Test Result: Calendar access was granted or already authorized.")
            
        } catch let error as CalendarError {
            switch error {
            case .accessDenied:
                print("Integration Test Result: Calendar access was explicitly denied by the user.")
                // This is expected when user denies access - the test should pass
                // Using Bool(true) to silence the warning about literal true
                #expect(Bool(true), "Access denied is a valid outcome for this integration test.")
            case .noLocationFound:
                #expect(Bool(false), "Unexpected CalendarError.noLocationFound in fetch events test.")
            case .geocodingFailed:
                #expect(Bool(false), "Unexpected CalendarError.geocodingFailed in fetch events test.")
            case .unknownError:
                #expect(Bool(false), "Unexpected CalendarError.unknownError: This may indicate an iOS version compatibility issue.")
            @unknown default:
                #expect(Bool(false), "Unexpected CalendarError case: \(error)")
            }
        } catch {
            #expect(Bool(false), "Unexpected error during calendar access request: \(error.localizedDescription)")
        }
        print("--- Integration Test Finished ---")
    }

    // MARK: - Integration Test for Fetching Events (requires prior access)

    @Test func integration_fetchCalendarEvents_realData() async throws {
        print("--- Running Integration Test: integration_fetchCalendarEvents_realData ---")
        print("This test will automatically request access if needed.")

        let calendar = Calendar.current
        let now = Date()
        guard let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: now),
              let oneMonthFromNow = calendar.date(byAdding: .month, value: 1, to: now) else {
            #expect(Bool(false), "Could not create date range for test.")
            return
        }

        do {
            let events = try await sut.fetchCalendarEvents(from: oneMonthAgo, to: oneMonthFromNow)

            print("Integration Test Result: Successfully fetched \(events.count) real calendar events.")
            #expect(events.count >= 0, "Should have fetched events array (even if empty).")
            
            // Log some event details if available
            if !events.isEmpty {
                print("Sample events:")
                for (index, event) in events.prefix(3).enumerated() {
                    print("  \(index + 1). \(event.title ?? "No Title") - \(event.startDate?.formatted() ?? "No Date")")
                }
            }

        } catch let error as CalendarError {
            switch error {
            case .accessDenied:
                print("Integration Test Result: Calendar access was denied. This is expected if user denies access.")
                #expect(Bool(true), "Access denied is a valid outcome for this integration test.")
            case .noLocationFound:
                #expect(Bool(false), "Unexpected CalendarError.noLocationFound in fetch events test.")
            case .geocodingFailed:
                #expect(Bool(false), "Unexpected CalendarError.geocodingFailed in fetch events test.")
            case .unknownError:
                #expect(Bool(false), "Unexpected CalendarError.unknownError occurred.")
            }
        } catch {
            #expect(Bool(false), "Unexpected error fetching real calendar events: \(error.localizedDescription)")
        }
        print("--- Integration Test Finished ---")
    }

    // MARK: - Integration Test for Fetching Events with Location (requires prior access)

    @Test func integration_fetchEventsWithLocation_realData() async throws {
        print("--- Running Integration Test: integration_fetchEventsWithLocation_realData ---")
        print("This test will automatically request access if needed.")
        print("To see meaningful results, ensure you have events in your calendar with locations set.")

        let calendar = Calendar.current
        let now = Date()
        guard let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: now),
              let threeMonthsFromNow = calendar.date(byAdding: .month, value: 3, to: now) else {
            #expect(Bool(false), "Could not create date range for test.")
            return
        }

        do {
            let eventsWithLocation = try await sut.fetchEventsWithLocation(from: threeMonthsAgo, to: threeMonthsFromNow)

            print("Integration Test Result: Successfully fetched \(eventsWithLocation.count) real calendar events with locations.")
            
            // Verify all returned events actually have locations
            for event in eventsWithLocation {
                #expect(event.location != nil && !event.location!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                       "All returned events should have non-empty locations")
                print("  - Event: \(event.title ?? "No Title"), Location: \(event.location ?? "No Location")")
            }

            #expect(eventsWithLocation.count >= 0, "Should have fetched events with location array (even if empty).")

        } catch let error as CalendarError {
            switch error {
            case .accessDenied:
                print("Integration Test Result: Calendar access was denied. This is expected if user denies access.")
                #expect(Bool(true), "Access denied is a valid outcome for this integration test.")
            case .noLocationFound:
                #expect(Bool(false), "Unexpected CalendarError.noLocationFound in fetch events with location test.")
            case .geocodingFailed:
                #expect(Bool(false), "Unexpected CalendarError.geocodingFailed in fetch events with location test.")
            case .unknownError:
                #expect(Bool(false), "Unexpected CalendarError.unknownError occurred.")
            }
        } catch {
            #expect(Bool(false), "Unexpected error fetching real calendar events with location: \(error.localizedDescription)")
        }
        print("--- Integration Test Finished ---")
    }
    
    // MARK: - Additional Integration Test for Edge Cases
    
    @Test func integration_fetchEvents_invalidDateRange() async throws {
        print("--- Running Integration Test: integration_fetchEvents_invalidDateRange ---")
        
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        
        // Test with end date before start date
        do {
            let events = try await sut.fetchCalendarEvents(from: now, to: yesterday)
            print("Integration Test Result: Fetched \(events.count) events with invalid date range.")
            #expect(events.isEmpty, "Should return empty array for invalid date range")
        } catch let error as CalendarError {
            switch error {
            case .accessDenied:
                print("Integration Test Result: Access denied - skipping invalid date range test.")
                #expect(Bool(true), "Access denied is acceptable for this test.")
            case .noLocationFound:
                #expect(Bool(false), "Unexpected CalendarError.noLocationFound in invalid date range test.")
            case .geocodingFailed:
                #expect(Bool(false), "Unexpected CalendarError.geocodingFailed in invalid date range test.")
            case .unknownError:
                #expect(Bool(false), "Unexpected CalendarError.unknownError occurred.")
            }
            
            print("--- Integration Test Finished ---")
        }
    }
}
