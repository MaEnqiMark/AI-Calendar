//
//  CalendarEventViewModel.swift
//  AI-Calendar
//
//  Created by 马恩奇 on 11/30/25.
//

import Foundation
import SwiftUI
import GoogleSignIn
import GoogleSignInSwift
import GoogleAPIClientForREST_Calendar
import Observation

@Observable
class CalendarEventViewModel {

    // MARK: - Stored Events

    var events: [CalendarEvent] = [
        CalendarEvent(
            title: "David Tao",
            start: todayAt(hour: 3),
            end:   todayAt(hour: 9),
            color: .blue
        ),
        CalendarEvent(
            title: "Reservation at Kraam Thai",
            start: todayAt(hour: 17),
            end:   todayAt(hour: 18),
            color: .green
        ),
        CalendarEvent(
            title: "Gym",
            start: todayAt(hour: 20),
            end:   todayAt(hour: 21),
            color: .orange
        )
    ]

    // MARK: - Google Calendar

    private let service = GTLRCalendarService()
    private var maxWeeksOffset = 2

    func checkIfMustFetchEvents(offset: Int, user: GIDGoogleUser) async {
        if abs(offset) > maxWeeksOffset - 1 {
            do {
                maxWeeksOffset = abs(offset) + 3
                try await listEvents(user: user, offset: abs(offset) + 3)
            } catch {
                // You might want better error handling here
                return
            }
        }
    }

    func listEvents(user: GIDGoogleUser, offset: Int) async throws {
        self.service.authorizer = user.fetcherAuthorizer

        let query = GTLRCalendarQuery_EventsList.query(withCalendarId: "primary")
        query.timeMin = GTLRDateTime(
            date: Calendar.current.date(byAdding: .day, value: -offset * 7, to: Date())!
        )
        query.timeMax = GTLRDateTime(
            date: Calendar.current.date(byAdding: .day, value: offset * 7, to: Date())!
        )
        query.singleEvents = true
        query.orderBy = kGTLRCalendarOrderByStartTime

        service.executeQuery(query) { _, result, error in
            if let error = error {
                return
            }

            guard let events = (result as? GTLRCalendar_Events)?.items else {
                return
            }

            // Convert and append unique events
            let converted = self.convertToCalendarEvents(events)
            for event in converted {
                if !self.events.contains(event) {
                    self.events.append(event)
                }
            }
        }
    }

    // MARK: - Local Event CRUD

    func addEvent(_ event: CalendarEvent) {
        events.append(event)
    }

    func deleteEvent(_ event: CalendarEvent) {
        events.removeAll { $0.id == event.id }
    }

    func events(on day: Date) -> [CalendarEvent] {
        events.filter {
            appCalendar.isDate($0.start, equalTo: day, toGranularity: .day)
        }
    }

    // MARK: - Auto Schedule Logic

    func autoSchedule(tasks: [TaskItem]) {
        // Remove old auto-scheduled tasks
        events.removeAll { $0.isTask }

        // Schedule tasks according to array order
        let workDayStartHour = 8
        let workDayEndHour = 22
        var searchLocation = Date()
        let buffer: TimeInterval = 900 // 15 min buffer

        for task in tasks {
            if let startSlot = findNextAvailableSlot(
                duration: task.duration,
                after: searchLocation,
                startHour: workDayStartHour,
                endHour: workDayEndHour
            ) {

                let newEvent = CalendarEvent(
                    title: "Task: \(task.title)",
                    start: startSlot,
                    end: startSlot.addingTimeInterval(task.duration),
                    color: colorForPriority(task.priority),
                    isTask: true
                )

                events.append(newEvent)
                searchLocation = newEvent.end.addingTimeInterval(buffer)
            }
        }
    }

    // Find when the events can be placed, within the working hours of the day and next
    private func findNextAvailableSlot(
        duration: TimeInterval,
        after date: Date,
        startHour: Int,
        endHour: Int
    ) -> Date? {
        var checkDate = date
        let calendar = Calendar.current

        // Look 3 days ahead max
        for _ in 0..<3 {
            let morning = calendar.date(
                bySettingHour: startHour,
                minute: 0,
                second: 0,
                of: checkDate
            )!
            let evening = calendar.date(
                bySettingHour: endHour,
                minute: 0,
                second: 0,
                of: checkDate
            )!

            var candidate = checkDate < morning ? morning : checkDate

            // If we're already past the workday, move to next day
            if candidate >= evening {
                checkDate = calendar.date(byAdding: .day, value: 1, to: checkDate)!
                checkDate = calendar.date(
                    bySettingHour: startHour,
                    minute: 0,
                    second: 0,
                    of: checkDate
                )!
                candidate = checkDate
            }

            let dayEvents = events(on: candidate).sorted { $0.start < $1.start }

            // Case 1: free before first event
            if let first = dayEvents.first {
                if first.start.timeIntervalSince(candidate) >= duration {
                    return candidate
                }
            } else {
                // No events at all this day
                if evening.timeIntervalSince(candidate) >= duration {
                    return candidate
                }
            }

            // Case 2: free between events
            if dayEvents.count >= 2 {
                for i in 0..<(dayEvents.count - 1) {
                    let curr = dayEvents[i]
                    let next = dayEvents[i + 1]
                    if next.start.timeIntervalSince(curr.end) >= duration,
                       curr.end < evening {
                        return curr.end
                    }
                }
            }

            // Case 3: free after last event
            if let last = dayEvents.last {
                if evening.timeIntervalSince(last.end) >= duration {
                    return last.end
                }
            }

            // Move to next day
            checkDate = calendar.date(byAdding: .day, value: 1, to: checkDate)!
            checkDate = calendar.date(
                bySettingHour: startHour,
                minute: 0,
                second: 0,
                of: checkDate
            )!
        }

        return nil
    }

    private func colorForPriority(_ p: TaskPriority) -> Color {
        switch p {
        case .high:   return .red
        case .medium: return .blue
        case .low:    return .gray
        }
    }

    // MARK: - Google → Local Conversion

    func convertToCalendarEvents(_ events: [GTLRCalendar_Event]) -> [CalendarEvent] {
        return events.compactMap { event in
            let title = event.summary ?? "(No Title)"

            let startDate: Date? = {
                if let dt = event.start?.dateTime?.date {
                    return dt
                } else if let d = event.start?.date?.date {
                    // All-day events use .date
                    return d
                }
                return nil
            }()

            let endDate: Date? = {
                if let dt = event.end?.dateTime?.date {
                    return dt
                } else if let d = event.end?.date?.date {
                    return d
                }
                return nil
            }()

            guard let start = startDate, let end = endDate else {
                return nil
            }

            return CalendarEvent(
                title: title,
                start: start,
                end: end,
                color: .blue
            )
        }
    }
}
