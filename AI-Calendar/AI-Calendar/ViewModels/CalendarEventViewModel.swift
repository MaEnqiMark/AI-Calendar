//
//  CalendarEventViewModel.swift
//  AI-Calendar
//
//  Created by 马恩奇 on 11/30/25.
//

import Foundation
import SwiftUI
import Observation

@Observable
class CalendarEventViewModel {
    
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
    
    init() {}

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
            if let startSlot = findNextAvailableSlot(duration: task.duration, after: searchLocation, startHour: workDayStartHour, endHour: workDayEndHour) {
                
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
    private func findNextAvailableSlot(duration: TimeInterval, after date: Date, startHour: Int, endHour: Int) -> Date? {
        var checkDate = date
        let calendar = Calendar.current
        
        for _ in 0..<3 { // Look 3 days ahead max
            let morning = calendar.date(bySettingHour: startHour, minute: 0, second: 0, of: checkDate)!
            let evening = calendar.date(bySettingHour: endHour, minute: 0, second: 0, of: checkDate)!
            
            var candidate = checkDate < morning ? morning : checkDate
            
            if candidate >= evening {
                checkDate = calendar.date(byAdding: .day, value: 1, to: checkDate)!
                checkDate = calendar.date(bySettingHour: startHour, minute: 0, second: 0, of: checkDate)!
                candidate = checkDate
            }
            
            let dayEvents = events(on: candidate).sorted { $0.start < $1.start }
            
            if let first = dayEvents.first {
                if first.start.timeIntervalSince(candidate) >= duration { return candidate }
            } else {
                if evening.timeIntervalSince(candidate) >= duration { return candidate }
            }
            
            for i in 0..<(dayEvents.count - 1) {
                let curr = dayEvents[i]
                let next = dayEvents[i+1]
                if next.start.timeIntervalSince(curr.end) >= duration {
                    if curr.end < evening { return curr.end }
                }
            }
            
            if let last = dayEvents.last {
                if evening.timeIntervalSince(last.end) >= duration { return last.end }
            }
            
            checkDate = calendar.date(byAdding: .day, value: 1, to: checkDate)!
            checkDate = calendar.date(bySettingHour: startHour, minute: 0, second: 0, of: checkDate)!
        }
        return nil
    }
    
    private func colorForPriority(_ p: TaskPriority) -> Color {
        switch p {
        case .high: return .red
        case .medium: return .blue
        case .low: return .gray
        }
    }
}
