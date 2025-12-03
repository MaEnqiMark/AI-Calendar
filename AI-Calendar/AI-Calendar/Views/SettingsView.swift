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
    @AppStorage("bufferMinutes") private var bufferMinutes = 15

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
                    
                    Picker("Buffer Between Tasks", selection: $bufferMinutes) {
                                            Text("None").tag(0)
                                            Text("5 min").tag(5)
                                            Text("10 min").tag(10)
                                            Text("15 min").tag(15)
                                            Text("30 min").tag(30)
                                            Text("1 hour").tag(60)
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
            .onChange(of: bufferMinutes) {
                taskVM.syncToCalendar()
            }
        }
    }
    
    func formatHour(_ hour: Int) -> String {
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!
        return date.formatted(date: .omitted, time: .shortened)
    }
}
