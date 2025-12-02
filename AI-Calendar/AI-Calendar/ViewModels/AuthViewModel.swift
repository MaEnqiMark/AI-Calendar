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

/// A simple view model managing sign-in and token retrieval.
@Observable class AuthViewModel {
    private var isSignedIn: Bool = false
    private var user: GIDGoogleUser?
    private let service = GTLRCalendarService()
    
    func setUser(u: GIDGoogleUser) {
        self.user = u
        self.service.authorizer = u.fetcherAuthorizer
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
            self.service.authorizer = result.user.fetcherAuthorizer
        }
    }
    
    func listEvents() async throws -> [GTLRCalendar_Event] {
        let query = GTLRCalendarQuery_EventsList.query(withCalendarId: "primary")
        query.timeMin = GTLRDateTime(date: Date())
        query.singleEvents = true
        query.orderBy = kGTLRCalendarOrderByStartTime
        query.maxResults = 10
        
        return try await withCheckedThrowingContinuation { continuation in
            service.executeQuery(query) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let events = (result as? GTLRCalendar_Events)?.items else {
                    let err = NSError(
                        domain: "Calendar",
                        code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "Invalid Calendar response"]
                    )
                    continuation.resume(throwing: err)
                    return
                }

                continuation.resume(returning: events)
            }
        }
    }
}

