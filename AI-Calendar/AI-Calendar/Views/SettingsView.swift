//
//  SettingsView.swift
//  AI-Calendar
//
//  Created by 马恩奇 on 11/30/25.

import SwiftUI
import GoogleSignIn
import GoogleSignInSwift

struct SettingsView: View {
    @Environment(AuthViewModel.self) var auth
    @Environment(TaskViewModel.self) var taskVM
    
    @AppStorage("darkMode") private var darkMode = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("autoPriority") private var autoPriority = true
    
    @AppStorage("workDayStart") private var workDayStart = 9
    @AppStorage("workDayEnd") private var workDayEnd = 17

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Appearance")) {
                    Toggle("Dark Mode", isOn: $darkMode)
                }

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
                    .pickerStyle(.menu)
                    
                    Picker("End Time", selection: $workDayEnd) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text(formatHour(hour)).tag(hour)
                        }
                    }
                    .pickerStyle(.menu)
                }

                GoogleSignInButton(action: auth.handleSignIn)
            }
            .navigationTitle("Settings")
            // Trigger the re-calculation of task placement on calendar
            .onChange(of: workDayStart) {
                taskVM.syncToCalendar()
            }
            .onChange(of: workDayEnd) {
                taskVM.syncToCalendar()
            }
        }
    }
    
    func formatHour(_ hour: Int) -> String {
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!
        return date.formatted(date: .omitted, time: .shortened)
    }
}
