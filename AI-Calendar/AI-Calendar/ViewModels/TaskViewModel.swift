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

    init() {}

    func addTask(_ task: TaskItem, context: ModelContext) {
        context.insert(task)
        syncToCalendar(context: context)
    }

    func updateTask(_ task: TaskItem, context: ModelContext) {
        syncToCalendar(context: context)
    }

    func toggleCompletion(for task: TaskItem, context: ModelContext) {
        task.isCompleted.toggle()
        task.completedDate = task.isCompleted ? Date() : nil
        syncToCalendar(context: context)
    }

    func delete(_ task: TaskItem, context: ModelContext) {
        context.delete(task)
        syncToCalendar(context: context)
    }

    func move(from source: IndexSet, to destination: Int, tasks: [TaskItem], context: ModelContext) {
        // If you want persistent ordering, add a sortIndex to TaskItem
        syncToCalendar(context: context)
    }

    func syncToCalendar(context: ModelContext) {
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate { !$0.isCompleted },
            sortBy: [.init(\TaskItem.dueDate)]
        )
        if let tasks = try? context.fetch(descriptor) {
            calendarVM?.autoSchedule(tasks: tasks)
        }
    }

    func parseStringForTask(_ string: String) async throws -> TaskItem {
        guard let task = try await NetworkManager.instance.analyzeTask(string) else {
            throw NSError(domain: "TaskParsing", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to parse task from string."
            ])
        }
        return task
    }
}
