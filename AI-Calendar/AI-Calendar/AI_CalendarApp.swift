//
//  AI_CalendarApp.swift
//  AI-Calendar
//
//  Created by 马恩奇 on 11/25/25.
//

import SwiftUI

@main
struct AI_CalendarApp: App {
    @AppStorage("darkMode") private var darkMode = false
    var body: some Scene {
        WindowGroup {
            TabView {
                CalendarView()
                    .tabItem { Label("Calendar", systemImage: "calendar") }
                    .preferredColorScheme(darkMode ? .dark : .light)
                
                TaskView()
                    .tabItem { Label("Tasks", systemImage: "checklist") }
                    .preferredColorScheme(darkMode ? .dark : .light)

                SettingsView()
                    .tabItem { Label("Settings", systemImage: "gear") }
                    .preferredColorScheme(darkMode ? .dark : .light)
            }
        }
    }
}
