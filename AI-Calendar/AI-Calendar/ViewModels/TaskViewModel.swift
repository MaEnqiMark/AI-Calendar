//
//  TaskViewModel.swift
//  AI-Calendar
//
//  Created by Max Davidoff on 12/1/25.
//

import Foundation
import SwiftUI
import Combine

class TaskViewModel: ObservableObject {
    @Published var tasks: [TaskItem] = [
        TaskItem(title: "Buy Groceries", dueDate: Date(), priority: .medium, duration: 3600),
        TaskItem(title: "Walk the dog", dueDate: Date().addingTimeInterval(3600), priority: .high, duration: 1800),
        TaskItem(title: "Submit report", isCompleted: true, dueDate: Date().addingTimeInterval(-86400), completedDate: Date(), duration: 7200)
    ]
    
    var pendingTasks: [TaskItem] {
        tasks.filter { !$0.isCompleted }
             .sorted {
                 // Sort by Priority (High first), then by Date
                 if $0.priority.sortValue != $1.priority.sortValue {
                     return $0.priority.sortValue > $1.priority.sortValue
                 } else {
                     return $0.dueDate < $1.dueDate
                 }
             }
    }
    
    var completedTasks: [TaskItem] {
        tasks.filter { $0.isCompleted }
            .sorted { ($0.completedDate ?? Date()) > ($1.completedDate ?? Date()) }
    }
    
    func addTask(_ task: TaskItem) {
        tasks.insert(task, at: 0)
    }
    
    func updateTask(_ updatedTask: TaskItem) {
        if let index = tasks.firstIndex(where: { $0.id == updatedTask.id }) {
            tasks[index] = updatedTask
        }
    }
    
    func toggleCompletion(for task: TaskItem) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
            if tasks[index].isCompleted {
                tasks[index].completedDate = Date()
            } else {
                tasks[index].completedDate = nil
            }
        }
    }
    
    func delete(at offsets: IndexSet, isCompletedSection: Bool) {
        let sourceList = isCompletedSection ? completedTasks : pendingTasks
        offsets.forEach { index in
            if index < sourceList.count {
                let taskToDelete = sourceList[index]
                tasks.removeAll { $0.id == taskToDelete.id }
            }
        }
    }
    
    func move(from source: IndexSet, to destination: Int) {
        var activeTasks = pendingTasks
        activeTasks.move(fromOffsets: source, toOffset: destination)
        // Note: Re-sorting might override manual move if sorting logic is strict in 'pendingTasks' computed property
        // For now we allow moving, but the list might snap back if we strictly enforce priority sort.
        // To fix this in production, you'd add a 'sortIndex' property.
    }
}
