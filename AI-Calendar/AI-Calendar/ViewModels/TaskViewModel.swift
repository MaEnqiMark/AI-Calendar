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
        TaskItem(title: "Buy Groceries", dueDate: Date(), priority: .medium),
        TaskItem(title: "Walk the dog", dueDate: Date().addingTimeInterval(3600), priority: .high),
        TaskItem(title: "Submit report", isCompleted: true, dueDate: Date().addingTimeInterval(-86400), completedDate: Date())
    ]
    
    // Derived properties for sections
    var pendingTasks: [TaskItem] {
        tasks.filter { !$0.isCompleted }
    }
    
    var completedTasks: [TaskItem] {
        tasks.filter { $0.isCompleted }
            .sorted { ($0.completedDate ?? Date()) > ($1.completedDate ?? Date()) }
    }
    
    func addTask(title: String, date: Date, priority: TaskPriority) {
        let newTask = TaskItem(title: title, dueDate: date, priority: priority)
        tasks.insert(newTask, at: 0)
    }
    
    // Function to update an existing task
    func updateTask(_ updatedTask: TaskItem) {
        if let index = tasks.firstIndex(where: { $0.id == updatedTask.id }) {
            tasks[index] = updatedTask
        }
    }
    
    func toggleCompletion(for task: TaskItem) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            // Toggle state
            tasks[index].isCompleted.toggle()
            
            // Update timestamp
            if tasks[index].isCompleted {
                tasks[index].completedDate = Date()
            } else {
                tasks[index].completedDate = nil
            }
        }
    }
    
    func delete(at offsets: IndexSet, isCompletedSection: Bool) {
        // Map the IndexSet from the filtered view back to the main array
        let sourceList = isCompletedSection ? completedTasks : pendingTasks
        
        offsets.forEach { index in
            if index < sourceList.count {
                let taskToDelete = sourceList[index]
                tasks.removeAll { $0.id == taskToDelete.id }
            }
        }
    }
    
    func move(from source: IndexSet, to destination: Int) {
        // Reordering is only enabled for Pending tasks
        var activeTasks = pendingTasks
        activeTasks.move(fromOffsets: source, toOffset: destination)
        
        // Reconstruct the main list: New Active Order + Existing Completed Tasks
        tasks = activeTasks + completedTasks
    }
}
