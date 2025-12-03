//
//  AI_CalendarApp.swift
//  AI-Calendar
//
//  Created by 马恩奇 on 11/25/25.
//

import SwiftUI
import GoogleSignIn
import SwiftData

@main
struct AI_CalendarApp: App {
    @State var auth = AuthViewModel()
    @State var calendarViewModel = CalendarEventViewModel()
    @State var taskViewModel = TaskViewModel()
    
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
            .environment(auth)
            .environment(calendarViewModel)
            .environment(taskViewModel)
            .onAppear {
                // Link the viewmodels
                taskViewModel.calendarVM = calendarViewModel
                
                GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
                    // Check if `user` exists; otherwise, do something with `error`
                    if let user = user {
                        auth.setUser(u: user)
                        Task {
                            do {
                                let events = try await calendarViewModel.listEvents(user: user, offset: 2)
                            } catch {}
                        }
                    } else {}
                }
            }
            .onOpenURL { url in
                GIDSignIn.sharedInstance.handle(url)
            }
        }
        .modelContainer(for: [TaskItem.self])
    }
}
