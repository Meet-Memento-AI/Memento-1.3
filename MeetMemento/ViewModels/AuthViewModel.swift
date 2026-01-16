//
//  AuthViewModel.swift
//  MeetMemento
//
//  Minimal stub for authentication state (UI boilerplate).
//

import Foundation
import SwiftUI

/// Auth state enum for onboarding flow
enum AuthState: Equatable {
    case unauthenticated
    case authenticated(needsOnboarding: Bool)

    var isAuthenticated: Bool {
        if case .authenticated = self { return true }
        return false
    }
}

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var hasCompletedOnboarding = false
    @Published var authState: AuthState = .unauthenticated

    /// For testing: bypass auth and onboarding, go straight to main app
    func bypassToMainApp() {
        isAuthenticated = true
        hasCompletedOnboarding = true
        authState = .authenticated(needsOnboarding: false)
    }

    // Pending profile from Apple Sign In (stub)
    var pendingFirstName: String?
    var pendingLastName: String?

    func initializeAuth() async {
        // Stub: No-op
    }

    func checkAuthState() async {
        // Stub: No-op
    }

    func sendOTP(email: String) async throws {
        // Stub: No-op
    }

    func verifyOTP(code: String) async throws {
        // Stub: Mark as authenticated
        authState = .authenticated(needsOnboarding: false)
    }

    func storePendingAppleProfile(firstName: String, lastName: String) {
        pendingFirstName = firstName
        pendingLastName = lastName
    }

    func clearPendingProfile() {
        pendingFirstName = nil
        pendingLastName = nil
    }

    func updateProfile(firstName: String, lastName: String) async throws {
        // Stub: Just store locally
        UserDefaults.standard.set(firstName, forKey: "memento_first_name")
        UserDefaults.standard.set(lastName, forKey: "memento_last_name")
    }
}
