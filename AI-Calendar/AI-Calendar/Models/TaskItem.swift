//
//  TaskItem.swift
//  AI-Calendar
//
//  Created by Max Davidoff on 12/1/25.
//
import Foundation
import SwiftData

enum TaskPriority: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    var sortValue: Int {
        switch self {
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
}

@Model
class TaskItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var isCompleted: Bool
    var dueDate: Date
    var priority: TaskPriority
    var completedDate: Date?
    var duration: TimeInterval
    
    init(id: UUID = UUID(),
         title: String,
         isCompleted: Bool = false,
         dueDate: Date = Date(),
         priority: TaskPriority = .medium,
         completedDate: Date? = nil,
         duration: TimeInterval = 3600) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.dueDate = dueDate
        self.priority = priority
        self.completedDate = completedDate
        self.duration = duration
    }
}
