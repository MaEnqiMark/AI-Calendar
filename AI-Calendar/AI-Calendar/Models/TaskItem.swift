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
    
    // Higher value = Higher Priority
    var sortValue: Int {
        switch self {
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
}

struct TaskItem: Identifiable, Codable {
    var id = UUID()
    var title: String
    var isCompleted: Bool = false
    var dueDate: Date = Date()
    var priority: TaskPriority = .medium
    var completedDate: Date? = nil
    var duration: TimeInterval = 3600 // Default 1 hour
}
