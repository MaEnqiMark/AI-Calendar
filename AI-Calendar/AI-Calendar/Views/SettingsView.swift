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
    
    @AppStorage("darkMode") private var darkMode = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("autoPriority") private var autoPriority = true
    
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
                    Toggle("Auto-Prioritize Tasks", isOn: $autoPriority)
                }

                // Info / About
                Section(footer: Text("Version 1.0 • AI Calendar")) {
                    EmptyView()
                }
                
                GoogleSignInButton(action: auth.handleSignIn)
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
