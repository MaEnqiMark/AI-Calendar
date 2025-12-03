//
//  AuthViewModel.swift
//  AI-Calendar
//
//  Created by Samuel Lao on 12/2/25.
//
import SwiftUI
import GoogleSignIn
import GoogleSignInSwift
import GoogleAPIClientForREST_Calendar

@Observable class AuthViewModel {
    private var isSignedIn: Bool = false
    private var user: GIDGoogleUser?
    
    func setUser(u: GIDGoogleUser) {
        self.user = u
    }
    
    func getUser() -> GIDGoogleUser? {
        return self.user
    }
    
    func handleSignIn() {
        guard let rootVC = UIApplication.shared
                .connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first?
                .windows
                .first?
                .rootViewController
        else {
          return
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootVC, hint: "hi", additionalScopes: ["https://www.googleapis.com/auth/calendar"]) { signInResult, error in
          guard let result = signInResult else {
            return
          }
            self.user = result.user
        }
    }
    
    func handleSignOut() {
        GIDSignIn.sharedInstance.signOut()
        self.user = nil
    }
}

