//
//  ChatSummarySheet.swift
//  MeetMemento
//
//  Bottom sheet modal for summarizing a chat conversation into a journal entry.
//

import SwiftUI

public struct ChatSummarySheet: View {
    let onSummarize: () -> Void
    let isSummarizing: Bool

    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type
    @Environment(\.dismiss) private var dismiss

    public init(
        onSummarize: @escaping () -> Void,
        isSummarizing: Bool
    ) {
        self.onSummarize = onSummarize
        self.isSummarizing = isSummarizing
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            RoundedRectangle(cornerRadius: 2.5)
                .fill(theme.mutedForeground.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 24)

            // Icon
            Image(systemName: "doc.text.fill")
                .font(.system(size: 48))
                .foregroundStyle(theme.primary)
                .padding(.bottom, 16)

            // Title
            Text("Save Chat as Entry")
                .font(type.h4)
                .foregroundStyle(theme.foreground)
                .padding(.bottom, 8)

            // Description
            Text("Create a journal entry from this conversation. Memento will summarize the key insights and reflections.")
                .font(type.body1)
                .foregroundStyle(theme.mutedForeground)
                .multilineTextAlignment(.center)
                .lineSpacing(type.bodyLineSpacing)
                .padding(.horizontal, 32)
                .padding(.bottom, 32)

            // Primary Button
            Button(action: onSummarize) {
                HStack(spacing: 8) {
                    if isSummarizing {
                        ProgressView()
                            .tint(.white)
                        Text("Generating...")
                    } else {
                        Text("Summarize Chat")
                    }
                }
                .font(type.body1Bold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .background(theme.primary)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 24)
            .disabled(isSummarizing)
            .opacity(isSummarizing ? 0.7 : 1.0)

            // Cancel Button
            Button("Cancel") {
                dismiss()
            }
            .font(type.body1)
            .foregroundStyle(theme.mutedForeground)
            .padding(.top, 16)
            .padding(.bottom, 32)
            .disabled(isSummarizing)
        }
        .background(theme.background.ignoresSafeArea())
        .presentationDetents([.height(360)])
        .presentationDragIndicator(.hidden)
        .interactiveDismissDisabled(isSummarizing)
    }
}

// MARK: - Previews

#Preview("Default") {
    ChatSummarySheet(
        onSummarize: { print("Summarize tapped") },
        isSummarizing: false
    )
    .useTheme()
    .useTypography()
}

#Preview("Loading") {
    ChatSummarySheet(
        onSummarize: { print("Summarize tapped") },
        isSummarizing: true
    )
    .useTheme()
    .useTypography()
}

#Preview("Dark Mode") {
    ChatSummarySheet(
        onSummarize: { print("Summarize tapped") },
        isSummarizing: false
    )
    .useTheme()
    .useTypography()
    .preferredColorScheme(.dark)
}
