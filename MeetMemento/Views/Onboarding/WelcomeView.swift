//
//  WelcomeView.swift
//  MeetMemento
//
//  Welcome screen with video background and unified auth buttons.
//

import SwiftUI

public struct WelcomeView: View {
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var isAppleLoading = false
    @State private var isGoogleLoading = false
    @State private var authError: String = ""

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                // Video background (full bleed)
                VideoBackground(videoName: "welcome-bg", videoExtension: "mp4")
                    .ignoresSafeArea()

                // Dark overlay for text readability
                LinearGradient(
                    colors: [
                        .black.opacity(0.3),
                        .black.opacity(0.5),
                        .black.opacity(0.7)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // Content overlay
                VStack(spacing: 0) {
                    // Logo at center-top
                    Image("Memento-Logo-White-Text")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 44)
                        .padding(.top, 32)

                    Spacer()

                    // Headline - middle, left-aligned
                    Text("Reflect while you journal with secure AI insights")
                        .typographyH3()
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)

                    Spacer()

                    // Auth buttons at bottom
                    authButtonsSection
                        .padding(.horizontal, 24)
                }
            }
        }
        .useTypography()
    }

    // MARK: - Auth Buttons Section

    @ViewBuilder
    private var authButtonsSection: some View {
        VStack(spacing: 16) {
            Button(action: { signInWithApple() }) {
                HStack(spacing: 8) {
                    if isAppleLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 18, weight: .medium))
                    }
                    Text("Continue with Apple")
                        .font(type.body1Bold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.black)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg, style: .continuous))
            }
            .disabled(isAppleLoading || isGoogleLoading)
            .opacity((isAppleLoading || isGoogleLoading) ? 0.7 : 1.0)

            GoogleSignInButton(
                title: isGoogleLoading ? "Signing in..." : "Continue with Google",
                scheme: .light
            ) {
                signInWithGoogle()
            }
            .disabled(isAppleLoading || isGoogleLoading)
            .opacity((isAppleLoading || isGoogleLoading) ? 0.7 : 1.0)

            if !authError.isEmpty {
                Text(authError)
                    .font(type.body2)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .transition(.opacity)
            }
        }
    }

    // MARK: - Auth Actions

    private func signInWithApple() {
        isAppleLoading = true
        authError = ""

        Task {
            do {
                try await authViewModel.signInWithApple()
                await MainActor.run {
                    isAppleLoading = false
                }
            } catch let error as AppleSignInError {
                await MainActor.run {
                    isAppleLoading = false
                    if case .canceled = error {
                        authError = ""
                    } else {
                        authError = error.localizedDescription
                    }
                }
            } catch {
                #if DEBUG
                print("🔴 Apple Sign In error: \(error)")
                #endif
                await MainActor.run {
                    isAppleLoading = false
                    authError = error.localizedDescription
                }
            }
        }
    }

    private func signInWithGoogle() {
        isGoogleLoading = true
        authError = ""

        Task {
            do {
                try await authViewModel.signInWithGoogle()
                await MainActor.run { isGoogleLoading = false }
            } catch {
                #if DEBUG
                print("🔴 Google Sign In error: \(error)")
                #endif
                await MainActor.run {
                    isGoogleLoading = false
                    authError = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Previews
#Preview("Welcome • Light") {
    WelcomeView()
        .useTheme()
        .useTypography()
        .environmentObject(AuthViewModel())
        .preferredColorScheme(.light)
}

#Preview("Welcome • Dark") {
    WelcomeView()
        .useTheme()
        .useTypography()
        .environmentObject(AuthViewModel())
        .preferredColorScheme(.dark)
}
