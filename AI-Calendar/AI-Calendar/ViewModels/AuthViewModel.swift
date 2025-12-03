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
    
    func handleSignIn() async throws -> GIDGoogleUser {
        guard let rootVC = UIApplication.shared
            .connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?
            .windows
            .first?
            .rootViewController
        else {
            throw NSError(domain: "No root VC", code: -1)
        }

        return try await withCheckedThrowingContinuation { continuation in
            GIDSignIn.sharedInstance.signIn(
                withPresenting: rootVC,
                hint: "hi",
                additionalScopes: ["https://www.googleapis.com/auth/calendar"]
            ) { signInResult, error in
                
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let user = signInResult?.user else {
                    continuation.resume(throwing: NSError(domain: "No user", code: -2))
                    return
                }
                
                self.user = user
                continuation.resume(returning: user)
            }
        }
    }
    
    func handleSignOut() {
        GIDSignIn.sharedInstance.signOut()
        self.user = nil
    }
}

