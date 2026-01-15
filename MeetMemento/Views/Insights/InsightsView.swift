//
//  InsightsView.swift
//  MeetMemento
//
//  Shows a placeholder insights view (UI boilerplate).
//

import SwiftUI

public struct InsightsView: View {
    @EnvironmentObject var entryViewModel: EntryViewModel
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type

    public init() {}

    public var body: some View {
        Group {
            if entryViewModel.entries.isEmpty {
                emptyState(
                    icon: "sparkles",
                    title: "No insights yet",
                    message: "Your insights will appear here after journaling."
                )
            } else {
                placeholderContent
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .ignoresSafeArea()
    }

    /// Placeholder content when entries exist
    private var placeholderContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Your emotional landscape reveals a blend of reflection, frustration, and growth that you’re working towards during this difficult transition period")
                /// add variable for AI-insights
                    .font(type.h3)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                EntriesTag(count: 10)

                /// # of entries tag

                Text("You've been processing heavy emotions around work, identity, and control, yet your tone has steadily shifted toward acceptance and purpose. Despite moments of doubt, there's an emerging sense that you're on the right path forward")
                    .font(type.body)
                    .foregroundStyle(.white.opacity(0.6))

                /// SENTIMENT ANALYSIS

                SentimentAnalysisCard(
                    emotionLabels: ["Anxiety", "Anticipation", "Fear", "Regret"],
                    emotionValues: [50, 20, 18, 12]
                )
                
                /// SECOND TEXT PARAGRAPH
                
                Text("You've been processing heavy emotions around work, identity, and control, yet your tone has steadily shifted toward acceptance and purpose. Despite moments of Fdoubt, there's an emerging sense that you're on the right path forward")
                    .font(type.body)
                    .foregroundStyle(.white.opacity(0.6))
                
                ///KeywordsCard
                KeywordsCard(
                    keywords: [
                        "Stress",
                        "Keeping an image",
                        "Growing from within",
                        "New starts",
                        "Acceptance",
                        "Realizing the truth",
                        "Choosing better",
                    ]
                )

                /// FOLLOW-UP QUESTIONS
                FollowUpQuestionGroup(
                    questions: [
                        "What would happen if you let go of the need to control everything?",
                        "How does your past shape the way you see your future?",
                        "What are you afraid to admit to yourself?"
                    ],
                    onQuestionTap: { index, question in
                        print("Follow-up question \(index + 1) tapped: \(question)")
                    }
                )
                .padding(.vertical, 20)
                .padding(.horizontal, -20) // Offset the parent horizontal padding

            }
            .padding(.horizontal, 20)
            .padding(.top, 108)
            .padding(.bottom, 24)
        }
    }

    /// Reusable empty state view
    private func emptyState(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 12) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundStyle(.white)

            Text(title)
                .font(type.h3)
                .fontWeight(.semibold)
                .foregroundStyle(.white)

            Text(message)
                .font(type.body)
                .foregroundStyle(.white.opacity(0.8))

            Spacer()
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 16)
    }
}

// MARK: - Previews
#Preview("Empty State") {
    @Previewable @StateObject var viewModel = EntryViewModel()
    @Previewable @Environment(\.theme) var theme

    ZStack {
        PrimaryScale.primary900
            .ignoresSafeArea()

        InsightsView()
            .environmentObject(viewModel)
    }
    .useTheme()
    .useTypography()
}

#Preview("With Entries") {
    @Previewable @StateObject var viewModel = EntryViewModel()
    @Previewable @Environment(\.theme) var theme

    ZStack {
        PrimaryScale.primary900
            .ignoresSafeArea()

        InsightsView()
            .environmentObject(viewModel)
            .onAppear {
                viewModel.loadMockEntries()
            }
    }
    .useTheme()
    .useTypography()
}
