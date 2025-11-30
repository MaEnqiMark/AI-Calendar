//
//  CalendarEvent.swift
//  AI-Calendar
//
//  Created by 马恩奇 on 11/30/25.
//

import Foundation
import SwiftUI

struct CalendarEvent: Identifiable, Hashable {
    let id: UUID
    var title: String
    var start: Date
    var end: Date
    var color: Color

    init(id: UUID = UUID(),
         title: String,
         start: Date,
         end: Date,
         color: Color = .blue) {
        self.id = id
        self.title = title
        self.start = start
        self.end = end
        self.color = color
    }
}
