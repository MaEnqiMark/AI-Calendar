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

@Observable class CalendarEventViewModel {
    
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
    
    private let service = GTLRCalendarService()
    
    private var maxWeeksOffset = 2

    func checkIfMustFetchEvents(offset: Int, user: GIDGoogleUser) async {
        if abs(offset) > maxWeeksOffset - 1 {
            do {
                maxWeeksOffset = abs(offset) + 3
                try await listEvents(user: user, offset: abs(offset) + 3)
            } catch {
                return
            }
        }
    }
    
    func listEvents(user: GIDGoogleUser, offset: Int) async throws {
        self.service.authorizer = user.fetcherAuthorizer
        
        let query = GTLRCalendarQuery_EventsList.query(withCalendarId: "primary")
        query.timeMin = GTLRDateTime(date: Calendar.current.date(byAdding: .day, value: -offset * 7, to: Date())!)
        query.timeMax = GTLRDateTime(date: Calendar.current.date(byAdding: .day, value: offset * 7, to: Date())!)
        query.singleEvents = true
        query.orderBy = kGTLRCalendarOrderByStartTime
        
        return try await withCheckedThrowingContinuation { continuation in
            service.executeQuery(query) { _, result, error in
                if error != nil {
                    return
                }

                guard let events = (result as? GTLRCalendar_Events)?.items else {
                    return
                }

                // Definitely O(1) runtime trust
                for event in self.convertToCalendarEvents(events) {
                    if !self.events.contains(event) {
                        self.events.append(event)
                    }
                }
            }
        }
    }
    

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
