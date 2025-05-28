//
//  CalendarServiceTestView.swift
//  Lizection
//
//  Created by Rongwei Ji on 5/23/25.
//

import SwiftUI
import EventKit

struct CalendarServiceTestView: View {
    @StateObject private var testRunner = CalendarServiceTestRunner()
    @State private var selectedDateRange = DateRange.oneMonth
    @State private var customStartDate = Date()
    @State private var customEndDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    
    enum DateRange: String, CaseIterable {
        case today = "Today"
        case oneWeek = "1 Week"
        case oneMonth = "1 Month"
        case threeMonths = "3 Months"
        case custom = "Custom"
        
        func dateRange(from baseDate: Date = Date()) -> (start: Date, end: Date) {
            let calendar = Calendar.current
            switch self {
            case .today:
                let startOfDay = calendar.startOfDay(for: baseDate)
                let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? baseDate
                return (startOfDay, endOfDay)
            case .oneWeek:
                let start = calendar.date(byAdding: .weekOfYear, value: -1, to: baseDate) ?? baseDate
                let end = calendar.date(byAdding: .weekOfYear, value: 1, to: baseDate) ?? baseDate
                return (start, end)
            case .oneMonth:
                let start = calendar.date(byAdding: .month, value: -1, to: baseDate) ?? baseDate
                let end = calendar.date(byAdding: .month, value: 1, to: baseDate) ?? baseDate
                return (start, end)
            case .threeMonths:
                let start = calendar.date(byAdding: .month, value: -3, to: baseDate) ?? baseDate
                let end = calendar.date(byAdding: .month, value: 3, to: baseDate) ?? baseDate
                return (start, end)
            case .custom:
                return (Date(), Date()) // Will be overridden by custom dates
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("CalendarService Integration Test")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Test the CalendarService functionality with real calendar data")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Test Controls
                    VStack(spacing: 16) {
                        // Calendar Access Test
                        TestSectionView(
                            title: "Calendar Access",
                            description: "Test requesting calendar access permissions",
                            isLoading: testRunner.isTestingAccess,
                            lastResult: testRunner.accessTestResult
                        ) {
                            Button("Test Calendar Access") {
                                Task {
                                    await testRunner.testCalendarAccess()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(testRunner.isTestingAccess)
                        }
                        
                        // Today's Events Test - New Feature
                        TestSectionView(
                            title: "Today's Events",
                            description: "Quick test to fetch and display today's calendar events",
                            isLoading: testRunner.isTestingTodayEvents,
                            lastResult: testRunner.todayEventsTestResult
                        ) {
                            Button("Get Today's Events") {
                                Task {
                                    await testRunner.testTodayEvents()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(testRunner.isTestingTodayEvents)
                        }
                        
                        // Date Range Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Date Range for Event Tests")
                                .font(.headline)
                            
                            Picker("Date Range", selection: $selectedDateRange) {
                                ForEach(DateRange.allCases, id: \.self) { range in
                                    Text(range.rawValue).tag(range)
                                }
                            }
                            .pickerStyle(.segmented)
                            
                            if selectedDateRange == .custom {
                                VStack(spacing: 8) {
                                    DatePicker("Start Date", selection: $customStartDate, displayedComponents: .date)
                                    DatePicker("End Date", selection: $customEndDate, displayedComponents: .date)
                                }
                                .padding(.top, 8)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        // Fetch Events Test
                        TestSectionView(
                            title: "Fetch Calendar Events",
                            description: "Fetch all calendar events in the selected date range",
                            isLoading: testRunner.isTestingEvents,
                            lastResult: testRunner.eventsTestResult
                        ) {
                            Button("Fetch Events") {
                                let dateRange = getSelectedDateRange()
                                Task {
                                    await testRunner.testFetchEvents(from: dateRange.start, to: dateRange.end)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(testRunner.isTestingEvents)
                        }
                        
                        // Fetch Events with Location Test
                        TestSectionView(
                            title: "Fetch Events with Location",
                            description: "Fetch calendar events that have location information",
                            isLoading: testRunner.isTestingEventsWithLocation,
                            lastResult: testRunner.eventsWithLocationTestResult
                        ) {
                            Button("Fetch Events with Location") {
                                let dateRange = getSelectedDateRange()
                                Task {
                                    await testRunner.testFetchEventsWithLocation(from: dateRange.start, to: dateRange.end)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(testRunner.isTestingEventsWithLocation)
                        }
                        
                        // Run All Tests
                        Button("Run All Tests") {
                            let dateRange = getSelectedDateRange()
                            Task {
                                await testRunner.runAllTests(from: dateRange.start, to: dateRange.end)
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(testRunner.isAnyTestRunning)
                        .padding(.top)
                    }
                    .padding()
                    
                    // Test Results
                    if !testRunner.testLogs.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Test Logs")
                                .font(.headline)
                            
                            ScrollView {
                                LazyVStack(alignment: .leading, spacing: 8) {
                                    ForEach(Array(testRunner.testLogs.enumerated()), id: \.offset) { index, log in
                                        TestLogView(log: log)
                                    }
                                }
                            }
                            .frame(maxHeight: 300)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            
                            Button("Clear Logs") {
                                testRunner.clearLogs()
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding()
                    }
                    
                    // Events Display
                    if !testRunner.fetchedEvents.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Fetched Events (\(testRunner.fetchedEvents.count))")
                                .font(.headline)
                            
                            LazyVStack(spacing: 8) {
                                ForEach(Array(testRunner.fetchedEvents.enumerated()), id: \.offset) { index, event in
                                    EventRowView(event: event)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Calendar Test")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func getSelectedDateRange() -> (start: Date, end: Date) {
        if selectedDateRange == .custom {
            return (customStartDate, customEndDate)
        } else {
            return selectedDateRange.dateRange()
        }
    }
}

// MARK: - Supporting Views

struct TestSectionView<Content: View>: View {
    let title: String
    let description: String
    let isLoading: Bool
    let lastResult: TestResult?
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                content
                
                Spacer()
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else if let result = lastResult {
                    Image(systemName: result.isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(result.isSuccess ? .green : .red)
                }
            }
            
            if let result = lastResult {
                Text(result.message)
                    .font(.caption)
                    .foregroundColor(result.isSuccess ? .green : .red)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct TestLogView: View {
    let log: TestLog
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(log.timestamp.formatted(date: .omitted, time: .standard))
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(log.message)
                    .font(.caption)
                    .foregroundColor(log.level.color)
                
                if let details = log.details {
                    Text(details)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}

struct EventRowView: View {
    let event: EKEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(event.title ?? "No Title")
                .font(.subheadline)
                .fontWeight(.medium)
            
            if let startDate = event.startDate {
                Text(startDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let location = event.location, !location.isEmpty {
                Label(location, systemImage: "location")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Test Runner

@MainActor
class CalendarServiceTestRunner: ObservableObject {
    @Published var isTestingAccess = false
    @Published var isTestingEvents = false
    @Published var isTestingEventsWithLocation = false
    @Published var isTestingTodayEvents = false
    
    @Published var accessTestResult: TestResult?
    @Published var eventsTestResult: TestResult?
    @Published var eventsWithLocationTestResult: TestResult?
    @Published var todayEventsTestResult: TestResult?
    
    @Published var testLogs: [TestLog] = []
    @Published var fetchedEvents: [EKEvent] = []
    
    private let calendarService = CalendarService()
    
    var isAnyTestRunning: Bool {
        isTestingAccess || isTestingEvents || isTestingEventsWithLocation || isTestingTodayEvents
    }
    
    func testCalendarAccess() async {
        isTestingAccess = true
        addLog("Starting calendar access test...", level: .info)
        
        do {
            let hasAccess = try await calendarService.requestCalendarAccess()
            let message = hasAccess ? "Calendar access granted successfully" : "Calendar access denied"
            accessTestResult = TestResult(isSuccess: hasAccess, message: message)
            addLog(message, level: hasAccess ? .success : .warning)
        } catch let error as CalendarError {
            let message = "Calendar access failed: \(error.localizedDescription)"
            accessTestResult = TestResult(isSuccess: false, message: message)
            addLog(message, level: .error, details: error.localizedDescription)
        } catch {
            let message = "Unexpected error: \(error.localizedDescription)"
            accessTestResult = TestResult(isSuccess: false, message: message)
            addLog(message, level: .error, details: error.localizedDescription)
        }
        
        isTestingAccess = false
    }
    
    func testTodayEvents() async {
        isTestingTodayEvents = true
        
        let now = Date()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? now
        
        // Command line logging
        print("🗓️ ========== TODAY'S EVENTS TEST ==========")
        print("📅 Date: \(now.formatted(date: .complete, time: .omitted))")
        print("⏰ Time Range: \(startOfDay.formatted(date: .omitted, time: .shortened)) - \(endOfDay.formatted(date: .omitted,time: .shortened))")
        print("🔍 Starting calendar events fetch for today...")
        
        addLog("🗓️ Testing Today's Events", level: .info)
        addLog("📅 Date: \(now.formatted(date: .complete, time: .omitted))", level: .info)
        
        do {
            let todayEvents = try await calendarService.fetchCalendarEvents(from: startOfDay, to: endOfDay)
            
            let message = "📱 Found \(todayEvents.count) event(s) for today"
            todayEventsTestResult = TestResult(isSuccess: true, message: message)
            addLog(message, level: .success)
            
            // Command line detailed logging
            print("✅ SUCCESS: Found \(todayEvents.count) event(s) for today")
            print("📋 Today's Events Details:")
            
            if todayEvents.isEmpty {
                print("   📭 No events scheduled for today")
                addLog("📭 No events scheduled for today", level: .warning)
            } else {
                // Update the fetched events for UI display
                fetchedEvents = todayEvents
                
                // Detailed command line output
                for (index, event) in todayEvents.enumerated() {
                    let eventNumber = index + 1
                    let title = event.title ?? "❓ Untitled Event"
                    let startTime = event.startDate?.formatted(date: .omitted, time: .shortened) ?? "No time"
                    let endTime = event.endDate?.formatted(date: .omitted,time: .shortened) ?? "No time"
                    let location = event.location?.isEmpty == false ? event.location! : "📍 No location"
                    let isAllDay = event.isAllDay
                    
                    print("   \(eventNumber). 📅 \(title)")
                    print("      ⏰ Time: \(isAllDay ? "All Day" : "\(startTime) - \(endTime)")")
                    print("      📍 Location: \(location)")
                    
                    if let notes = event.notes, !notes.isEmpty {
                        print("      📝 Notes: \(notes.prefix(100))...")
                    }
                    
                    if let calendar = event.calendar {
                        print("      🗂️ Calendar: \(calendar.title)")
                    }
                    
                    if event.hasAlarms {
                        print("      🔔 Has alarms/reminders")
                    }
                    
                    print("      🆔 Event ID: \(event.eventIdentifier ?? "N/A")")
                    print("") // Empty line for readability
                    
                    // Add to UI logs
                    addLog("📅 \(eventNumber). \(title)", level: .info)
                    addLog("   ⏰ \(isAllDay ? "All Day" : "\(startTime) - \(endTime)")", level: .info)
                    if location != "📍 No location" {
                        addLog("   📍 \(location)", level: .info)
                    }
                }
                
                // Summary statistics
                let eventsWithLocation = todayEvents.filter { $0.location?.isEmpty == false }.count
                let allDayEvents = todayEvents.filter { $0.isAllDay }.count
                let eventsWithAlarms = todayEvents.filter { $0.hasAlarms }.count
                
                print("📊 Today's Events Summary:")
                print("   📅 Total events: \(todayEvents.count)")
                print("   📍 Events with location: \(eventsWithLocation)")
                print("   🌅 All-day events: \(allDayEvents)")
                print("   🔔 Events with alarms: \(eventsWithAlarms)")
                
                addLog("📊 Summary: \(todayEvents.count) total, \(eventsWithLocation) with location, \(allDayEvents) all-day", level: .info)
            }
            
        } catch let error as CalendarError {
            let message = "❌ Failed to fetch today's events: \(error.localizedDescription)"
            todayEventsTestResult = TestResult(isSuccess: false, message: message)
            addLog(message, level: .error, details: error.localizedDescription)
            
            // Command line error logging
            print("❌ ERROR: Failed to fetch today's events")
            print("🚨 Error Type: \(error)")
            print("📄 Description: \(error.localizedDescription)")
            
            fetchedEvents = []
        } catch {
            let message = "❌ Unexpected error: \(error.localizedDescription)"
            todayEventsTestResult = TestResult(isSuccess: false, message: message)
            addLog(message, level: .error, details: error.localizedDescription)
            
            // Command line error logging
            print("❌ UNEXPECTED ERROR: \(error)")
            print("📄 Description: \(error.localizedDescription)")
            
            fetchedEvents = []
        }
        
        print("🏁 ========== TODAY'S EVENTS TEST COMPLETED ==========")
        print("") // Empty line for separation
        
        isTestingTodayEvents = false
    }
    
    func testFetchEvents(from startDate: Date, to endDate: Date) async {
        isTestingEvents = true
        addLog("Starting fetch events test...", level: .info)
        addLog("Date range: \(startDate.formatted(date: .abbreviated, time: .omitted)) to \(endDate.formatted(date: .abbreviated, time: .omitted))", level: .info)
        
        do {
            let events = try await calendarService.fetchCalendarEvents(from: startDate, to: endDate)
            let message = "Successfully fetched \(events.count) events"
            eventsTestResult = TestResult(isSuccess: true, message: message)
            addLog(message, level: .success)
            
            fetchedEvents = events
            
            if events.isEmpty {
                addLog("No events found in the specified date range", level: .warning)
            } else {
                addLog("Sample events:", level: .info)
                for (index, event) in events.prefix(3).enumerated() {
                    addLog("  \(index + 1). \(event.title ?? "No Title") - \(event.startDate?.formatted() ?? "No Date")", level: .info)
                }
            }
        } catch let error as CalendarError {
            let message = "Failed to fetch events: \(error.localizedDescription)"
            eventsTestResult = TestResult(isSuccess: false, message: message)
            addLog(message, level: .error, details: error.localizedDescription)
            fetchedEvents = []
        } catch {
            let message = "Unexpected error: \(error.localizedDescription)"
            eventsTestResult = TestResult(isSuccess: false, message: message)
            addLog(message, level: .error, details: error.localizedDescription)
            fetchedEvents = []
        }
        
        isTestingEvents = false
    }
    
    func testFetchEventsWithLocation(from startDate: Date, to endDate: Date) async {
        isTestingEventsWithLocation = true
        addLog("Starting fetch events with location test...", level: .info)
        addLog("Date range: \(startDate.formatted(date: .abbreviated, time: .omitted)) to \(endDate.formatted(date: .abbreviated, time: .omitted))", level: .info)
        
        do {
            let eventsWithLocation = try await calendarService.fetchEventsWithLocation(from: startDate, to: endDate)
            let message = "Successfully fetched \(eventsWithLocation.count) events with location"
            eventsWithLocationTestResult = TestResult(isSuccess: true, message: message)
            addLog(message, level: .success)
            
            if eventsWithLocation.isEmpty {
                addLog("No events with location found in the specified date range", level: .warning)
                addLog("Tip: Add some events with location information to your calendar for better testing", level: .info)
            } else {
                addLog("Events with location:", level: .info)
                for event in eventsWithLocation.prefix(5) {
                    addLog("  - \(event.title ?? "No Title"): \(event.location ?? "No Location")", level: .info)
                }
            }
        } catch let error as CalendarError {
            let message = "Failed to fetch events with location: \(error.localizedDescription)"
            eventsWithLocationTestResult = TestResult(isSuccess: false, message: message)
            addLog(message, level: .error, details: error.localizedDescription)
        } catch {
            let message = "Unexpected error: \(error.localizedDescription)"
            eventsWithLocationTestResult = TestResult(isSuccess: false, message: message)
            addLog(message, level: .error, details: error.localizedDescription)
        }
        
        isTestingEventsWithLocation = false
    }
    
    func runAllTests(from startDate: Date, to endDate: Date) async {
        addLog("=== Running All Tests ===", level: .info)
        print("🚀 ========== RUNNING ALL CALENDAR TESTS ==========")
        
        await testCalendarAccess()
        await testTodayEvents()
        
        // Only proceed with other tests if calendar access was granted
        if accessTestResult?.isSuccess == true {
            await testFetchEvents(from: startDate, to: endDate)
            await testFetchEventsWithLocation(from: startDate, to: endDate)
        } else {
            addLog("Skipping event tests due to calendar access denial", level: .warning)
            print("⚠️ Skipping remaining tests due to calendar access denial")
        }
        
        addLog("=== All Tests Completed ===", level: .info)
        print("🏁 ========== ALL CALENDAR TESTS COMPLETED ==========")
    }
    
    func clearLogs() {
        testLogs.removeAll()
        fetchedEvents.removeAll()
    }
    
    private func addLog(_ message: String, level: LogLevel, details: String? = nil) {
        let log = TestLog(
            timestamp: Date(),
            message: message,
            level: level,
            details: details
        )
        testLogs.append(log)
    }
}

// MARK: - Supporting Types

struct TestResult {
    let isSuccess: Bool
    let message: String
}

struct TestLog {
    let timestamp: Date
    let message: String
    let level: LogLevel
    let details: String?
}

enum LogLevel {
    case info
    case success
    case warning
    case error
    
    var color: Color {
        switch self {
        case .info: return .primary
        case .success: return .green
        case .warning: return .orange
        case .error: return .red
        }
    }
}

#Preview {
    CalendarServiceTestView()
}
