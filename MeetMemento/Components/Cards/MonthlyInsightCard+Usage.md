# MonthlyInsightCard Usage

A beautiful purple gradient card component for displaying monthly insights with entry counts.

## Features

- **Purple gradient background** with semi-transparent overlay
- **White text** optimized for contrast
- **Entry count badge** with pen icon
- **Chevron navigation affordance**
- **Haptic feedback** on tap
- **Press animation** for interactive feel
- **Accessibility** labels and hints included

## Basic Usage

```swift
import SwiftUI

struct InsightsListView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                MonthlyInsightCard(
                    month: "January 2026",
                    summary: "Your emotional landscape reveals a blend of reflection, frustration, and growth that you're working towards during this difficult transition.",
                    entryCount: 5,
                    onTap: {
                        // Navigate to monthly insight detail
                        print("Navigate to January 2026 insights")
                    }
                )

                MonthlyInsightCard(
                    month: "February 2026",
                    summary: "Add a one sentence summary of the users insights this month.",
                    entryCount: 11,
                    onTap: {
                        // Navigate to monthly insight detail
                        print("Navigate to February 2026 insights")
                    }
                )
            }
            .padding()
        }
        .background(theme.insightsBackground.ignoresSafeArea())
    }

    @Environment(\.theme) private var theme
}
```

## With NavigationStack

```swift
struct InsightsView: View {
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(monthlyInsights) { insight in
                        MonthlyInsightCard(
                            month: insight.monthYear,
                            summary: insight.summary,
                            entryCount: insight.entryCount,
                            onTap: {
                                navigationPath.append(insight)
                            }
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Insights")
            .navigationDestination(for: MonthlyInsight.self) { insight in
                MonthlyInsightDetailView(insight: insight)
            }
        }
    }

    var monthlyInsights: [MonthlyInsight] {
        // Your data source
        []
    }
}
```

## Design Tokens Used

- **Gradient Background**: `PrimaryScale.primary700` → `PrimaryScale.primary800`
- **Border**: White with 15% → 5% opacity gradient
- **Text**: White with 95-100% opacity
- **Badge Background**: White with 20% opacity
- **Corner Radius**: 20pt continuous
- **Shadow**: Black 15% opacity, 12pt radius

## Accessibility

The component includes:
- Combined accessibility element for entire card
- Descriptive label: "January 2026, Your emotional landscape... 5 entries"
- Hint: "Double tap to view monthly insights"
- Singular/plural entry count handling

## Preview

The component includes three preview variations:
1. **Light Mode** - Full list of cards
2. **Dark Mode** - Full list of cards
3. **Single Entry** - Edge case with 1 entry

Run the preview in Xcode to see the component in action.
