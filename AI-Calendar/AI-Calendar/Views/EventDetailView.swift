//
//  EventDetailView.swift
//  AI-Calendar
//
//  Created by 马恩奇 on 11/30/25.
//

import Foundation
import SwiftUI

struct EventDetailView: View {
    let event: CalendarEvent

    var body: some View {
        VStack(spacing: 16) {
            Text(event.title)
                .font(.title2)
                .bold()

            Text("\(event.start.formatted(date: .omitted, time: .shortened)) – \(event.end.formatted(date: .omitted, time: .shortened))")
                .font(.headline)

            Spacer()
        }
        .padding()
    }
}
