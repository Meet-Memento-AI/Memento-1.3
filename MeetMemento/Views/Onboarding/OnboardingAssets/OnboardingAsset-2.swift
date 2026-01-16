//
//  OnboardingAsset-2.swift
//  MeetMemento
//
//  Sentiment analysis showcase for onboarding carousel.
//

import SwiftUI

/// A centered sentiment analysis card for the onboarding flow.
struct OnboardingSentimentCard: View {
    @State private var isVisible = false

    var body: some View {
        SentimentAnalysisCard(
            emotionLabels: ["Joy", "Gratitude", "Calm"],
            emotionValues: [45, 35, 20],
            showPercentages: true
        )
        .scaleEffect(isVisible ? 1.0 : 0.95)
        .opacity(isVisible ? 1 : 0)
        .animation(.easeOut(duration: 0.5).delay(0.15), value: isVisible)
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
        .padding(.top, 32)
        .onAppear {
            isVisible = true
        }
        .padding(.horizontal, 16)

    }
}

// MARK: - Previews

#Preview("Sentiment Card • Light") {
    OnboardingSentimentCard()
        .useTheme()
        .useTypography()
        .preferredColorScheme(.light)
}

#Preview("Sentiment Card • Dark") {
    OnboardingSentimentCard()
        .useTheme()
        .useTypography()
        .preferredColorScheme(.dark)
}
