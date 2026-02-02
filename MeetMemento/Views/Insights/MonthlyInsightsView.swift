//
//  MonthlyInsightsView.swift
//  MeetMemento
//
//  Displays a list of monthly insights grouped by month.
//  Each card shows a summary and entry count for that month.
//  Tapping a card navigates to the detailed InsightsView for that month.
//

import SwiftUI

public struct MonthlyInsightsView: View {
    @EnvironmentObject var entryViewModel: EntryViewModel
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type

    let onNavigateToMonthInsight: (MonthGroup) -> Void

    public init(onNavigateToMonthInsight: @escaping (MonthGroup) -> Void) {
        self.onNavigateToMonthInsight = onNavigateToMonthInsight
    }

    public var body: some View {
        Group {
            if entryViewModel.entries.isEmpty {
                emptyState
            } else {
                monthlyInsightsList
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
    }

    // MARK: - Monthly Insights List

    private var monthlyInsightsList: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(entryViewModel.entriesByMonth) { monthGroup in
                    MonthlyInsightCard(
                        month: monthGroup.monthLabel,
                        summary: generateSummary(for: monthGroup),
                        entryCount: monthGroup.entryCount,
                        onTap: {
                            onNavigateToMonthInsight(monthGroup)
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 100) // Extra padding for bottom tab bar
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .headerGradient()

            Text("No insights yet")
                .font(type.h2)
                .headerGradient()

            Text("Your monthly insights will appear here after journaling.")
                .font(type.body1)
                .foregroundStyle(theme.mutedForeground)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Helper Methods

    /// Generates a summary for the month based on entry count and content
    /// In a real implementation, this would come from an API
    private func generateSummary(for monthGroup: MonthGroup) -> String {
        // For now, return a placeholder summary
        // In production, this would be fetched from the insights API
        let count = monthGroup.entryCount

        if count == 1 {
            return "You made one journal entry this month. Start exploring your thoughts and patterns."
        } else if count <= 5 {
            return "You're building a journaling habit. Keep exploring your thoughts and emotions."
        } else if count <= 10 {
            return "Your emotional landscape is taking shape. Patterns in your thoughts are beginning to emerge."
        } else {
            return "Your emotional landscape reveals a blend of reflection, frustration, and growth that you're working towards during this period."
        }
    }
}

// MARK: - Preview

#Preview("MonthlyInsightsView · With Entries") {
    NavigationStack {
        MonthlyInsightsView(onNavigateToMonthInsight: { _ in })
            .environmentObject({
                let vm = EntryViewModel()
                // Create mock entries for different months
                vm.entries = [
                    Entry(title: "Morning thoughts", text: "Feeling good today", createdAt: Date()),
                    Entry(title: "Evening reflection", text: "A productive day", createdAt: Date().addingTimeInterval(-86400)),
                    Entry(title: "Weekly review", text: "Learning and growing", createdAt: Date().addingTimeInterval(-86400 * 7)),
                    Entry(title: "Monthly goals", text: "Setting intentions", createdAt: Date().addingTimeInterval(-86400 * 30)),
                    Entry(title: "Gratitude", text: "Thankful for today", createdAt: Date().addingTimeInterval(-86400 * 31)),
                ]
                return vm
            }())
            .useTheme()
            .useTypography()
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
    }
    .background(Theme.light.insightsBackground.ignoresSafeArea())
}

#Preview("MonthlyInsightsView · Empty") {
    NavigationStack {
        MonthlyInsightsView(onNavigateToMonthInsight: { _ in })
            .environmentObject(EntryViewModel())
            .useTheme()
            .useTypography()
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
    }
    .background(Theme.light.insightsBackground.ignoresSafeArea())
}
