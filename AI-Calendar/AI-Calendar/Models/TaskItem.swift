//
//  TaskItem.swift
//  AI-Calendar
//
//  Created by Max Davidoff on 12/1/25.
//

import Foundation

enum TaskPriority: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
}

struct TaskItem: Identifiable, Codable {
    var id = UUID()
    var title: String
    var isCompleted: Bool = false
    var dueDate: Date = Date()
    var priority: TaskPriority = .medium
    var completedDate: Date? = nil
}
