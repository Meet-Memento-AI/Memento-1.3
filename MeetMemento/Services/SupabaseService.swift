
import Foundation
import Supabase

/// Singleton service for Supabase client interaction.
/// Ensure you have added the 'supabase-swift' package dependency to your project.
class SupabaseService {
    static let shared = SupabaseService()

    /// Configuration error that occurred during initialization
    enum ConfigurationError: LocalizedError {
        case invalidSupabaseURL(String)

        var errorDescription: String? {
            switch self {
            case .invalidSupabaseURL(let urlString):
                return "Invalid Supabase URL: '\(urlString)'. Please update Secrets.swift with a valid project URL."
            }
        }
    }

    // Configuration from git-ignored Secrets.swift
    private let supabaseUrl: URL
    private let supabaseKey = Secrets.supabaseAnonKey

    /// The Supabase client. Access this safely using `getClient()` for error handling.
    let client: SupabaseClient

    /// Stores any configuration error that occurred during initialization
    private(set) var configurationError: ConfigurationError?

    /// Returns true if the service was initialized successfully
    var isConfiguredCorrectly: Bool { configurationError == nil }

    private init() {
        // Validate URL - use a safe fallback if invalid to prevent crash
        if let url = URL(string: Secrets.supabaseUrl) {
            self.supabaseUrl = url
            self.configurationError = nil
        } else {
            // Log the error and use a placeholder URL to prevent crash
            // The configurationError will be checked by callers
            print("CRITICAL ERROR: Invalid Supabase URL in Secrets.swift: '\(Secrets.supabaseUrl)'")
            self.supabaseUrl = URL(string: "https://invalid.supabase.co")!
            self.configurationError = .invalidSupabaseURL(Secrets.supabaseUrl)

            #if DEBUG
            // In debug builds, assert to catch configuration errors during development
            assertionFailure("Invalid Supabase URL. Please update Secrets.swift with your project URL.")
            #endif
        }

        self.client = SupabaseClient(
            supabaseURL: supabaseUrl,
            supabaseKey: supabaseKey,
            options: .init(
                auth: .init(
                    redirectToURL: URL(string: "memento://auth/callback")
                )
            )
        )
    }

    /// Returns the Supabase client, throwing if configuration failed
    func getClient() throws -> SupabaseClient {
        if let error = configurationError {
            throw error
        }
        return client
    }
}
