//
//  CalendarEventViewModel.swift
//  AI-Calendar
//
//  Created by 马恩奇 on 11/30/25.
//

import Foundation
import Combine
import SwiftUI

final class CalendarEventViewModel: ObservableObject {
    @Published var events: [CalendarEvent] = [
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
    
    // MARK: - Auto Scheduler Logic
    
    func autoSchedule(tasks: [TaskItem]) {
        // SORTING LOGIC:
        // 1. Prioritize Due Date (Urgency)
        // 2. Then Prioritize Importance (Priority)
        let sortedTasks = tasks.sorted { task1, task2 in
            // Compare dates strictly by day (ignoring time for sorting buckets)
            let day1 = appCalendar.startOfDay(for: task1.dueDate)
            let day2 = appCalendar.startOfDay(for: task2.dueDate)
            
            if day1 != day2 {
                return day1 < day2 // Earlier date comes first
            }
            
            // If they are due on the same day, let higher priority item win
            return task1.priority.sortValue > task2.priority.sortValue
        }
        
        // Times for when a typical user is able to complete tasks
        let workDayStartHour = 8 // 8 AM
        let workDayEndHour = 22  // 10 PM
        
        // Start looking from "Now"
        var searchLocation = Date()
        
        // Buffer to prevent tasks from jamming right up against each other
        let bufferTime: TimeInterval = 900 // 15 minutes
        
        for task in sortedTasks {
            // Find a slot for this specific task
            if let startSlot = findNextAvailableSlot(duration: task.duration, after: searchLocation, startHour: workDayStartHour, endHour: workDayEndHour) {
                
                // Create the event
                let newEvent = CalendarEvent(
                    title: "Task: \(task.title)",
                    start: startSlot,
                    end: startSlot.addingTimeInterval(task.duration),
                    color: colorForPriority(task.priority)
                )
                
                self.addEvent(newEvent)
                
                // Update current search location to end of this event + buffer
                searchLocation = newEvent.end.addingTimeInterval(bufferTime)
            } else {
                print("Could not find a slot for \(task.title).")
            }
        }
    }
    
    private func findNextAvailableSlot(duration: TimeInterval, after date: Date, startHour: Int, endHour: Int) -> Date? {
        
        var checkDate = date
        let calendar = Calendar.current
        
        // Limit search to next 3 days
        for _ in 0..<3 {
            let morningLimit = calendar.date(bySettingHour: startHour, minute: 0, second: 0, of: checkDate)!
            let eveningLimit = calendar.date(bySettingHour: endHour, minute: 0, second: 0, of: checkDate)!
            
            var candidateStart = checkDate < morningLimit ? morningLimit : checkDate
            
            if candidateStart >= eveningLimit {
                checkDate = calendar.date(byAdding: .day, value: 1, to: checkDate)!
                checkDate = calendar.date(bySettingHour: startHour, minute: 0, second: 0, of: checkDate)!
                candidateStart = checkDate
            }
            
            let dayEvents = events(on: candidateStart).sorted { $0.start < $1.start }
            
            // 1. Gap before first event
            if let firstEvent = dayEvents.first {
                if firstEvent.start.timeIntervalSince(candidateStart) >= duration {
                    return candidateStart
                }
            } else {
                if eveningLimit.timeIntervalSince(candidateStart) >= duration {
                    return candidateStart
                }
            }
            
            // 2. Gaps between events
            for i in 0..<(dayEvents.count - 1) {
                let currentEvt = dayEvents[i]
                let nextEvt = dayEvents[i+1]
                
                if nextEvt.start.timeIntervalSince(currentEvt.end) >= duration {
                    if currentEvt.end < eveningLimit {
                        return currentEvt.end
                    }
                }
            }
            
            // 3. Gap after last event
            if let lastEvent = dayEvents.last {
                if eveningLimit.timeIntervalSince(lastEvent.end) >= duration {
                    return lastEvent.end
                }
            }
            
            // Move to next day
            checkDate = calendar.date(byAdding: .day, value: 1, to: checkDate)!
            checkDate = calendar.date(bySettingHour: startHour, minute: 0, second: 0, of: checkDate)!
        }
        
        return nil
    }
    
    private func colorForPriority(_ p: TaskPriority) -> Color {
        switch p {
        case .high: return .red
        case .medium: return .yellow
        case .low: return .green
        }
    }
}
