//
//  TaskViewModel.swift
//  AI-Calendar
//
//  Created by Max Davidoff on 12/1/25.
//
import Foundation
import SwiftUI
import SwiftData
import Observation

@Observable
class TaskViewModel {
    weak var calendarVM: CalendarEventViewModel?
    
    // MARK: - Logic
    
    func addTask(_ task: TaskItem) {
        // Insert based on Date/Priority, but allow user to move later
        let index = pendingTasks.firstIndex {
            let d1 = Calendar.current.startOfDay(for: task.dueDate)
            let d2 = Calendar.current.startOfDay(for: $0.dueDate)
            if d1 < d2 { return true }
            if d1 > d2 { return false }
            return task.priority.sortValue > $0.priority.sortValue
        } ?? pendingTasks.count
        
        pendingTasks.insert(task, at: index)
        syncToCalendar()
    }
    
    func updateTask(_ task: TaskItem) {
        if let idx = pendingTasks.firstIndex(where: { $0.id == task.id }) {
            pendingTasks[idx] = task
            syncToCalendar()
        }
    }
    
    func toggleCompletion(for task: TaskItem) {
        if let idx = pendingTasks.firstIndex(where: { $0.id == task.id }) {
            var t = pendingTasks.remove(at: idx)
            t.isCompleted = true
            t.completedDate = Date()
            completedTasks.insert(t, at: 0)
            syncToCalendar()
        } else if let idx = completedTasks.firstIndex(where: { $0.id == task.id }) {
            var t = completedTasks.remove(at: idx)
            t.isCompleted = false
            t.completedDate = nil
            // Add back to top of pending
            pendingTasks.insert(t, at: 0)
            syncToCalendar()
        }
    }
    
    func delete(at offsets: IndexSet, isCompleted: Bool) {
        if isCompleted {
            completedTasks.remove(atOffsets: offsets)
        } else {
            pendingTasks.remove(atOffsets: offsets)
            syncToCalendar()
        }
    }
    
    // MARK: - Reordering Logic
    
    func move(from source: IndexSet, to destination: Int) {
        // Only affects pendingTasks
        pendingTasks.move(fromOffsets: source, toOffset: destination)
        
        // Update calendar to reflect new priority order
        syncToCalendar()
    }
    
    // MARK: - Communication
    
    func syncToCalendar() {
        calendarVM?.autoSchedule(tasks: pendingTasks)
    }
    
    func parseStringForTask(_ string: String) async throws -> TaskItem? {
        return try await NetworkManager.instance.analyzeTask(string)
    }
}
