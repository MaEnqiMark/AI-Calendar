//
//  SettingsView.swift
//  AI-Calendar
//
//  Created by 马恩奇 on 11/30/25.

import SwiftUI

struct SettingsView: View {
    @AppStorage("darkMode") private var darkMode = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("autoPriority") private var autoPriority = true
    
    // Working Hours, defaulting with 9 to 5
    @AppStorage("workDayStart") private var workDayStart = 9
    @AppStorage("workDayEnd") private var workDayEnd = 17

    var body: some View {
        NavigationView {
            Form {
                // Appearance
                Section(header: Text("Appearance")) {
                    Toggle("Dark Mode", isOn: $darkMode)
                }

                // Behavior
                Section(header: Text("Behavior")) {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                }
                
                // Working Hours
                Section(header: Text("Working Hours")) {
                    Picker("Start Time", selection: $workDayStart) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text(formatHour(hour)).tag(hour)
                        }
                    }
                    .pickerStyle(.menu) // Makes it look like a dropdown
                    
                    Picker("End Time", selection: $workDayEnd) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text(formatHour(hour)).tag(hour)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // Info / About
                Section(footer: Text("Version 1.0 • AI Calendar")) {
                    EmptyView()
                }
            }
            .navigationTitle("Settings")
        }
    }
    
    // Helper to format time
    func formatHour(_ hour: Int) -> String {
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!
        return date.formatted(date: .omitted, time: .shortened)
    }
}
