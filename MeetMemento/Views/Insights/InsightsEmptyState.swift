//
//  InsightsEmptyState.swift
//  MeetMemento
//
//  Reusable empty state view for InsightsView
//

import SwiftUI

struct InsightsEmptyState: View {
    @Environment(\.typography) private var type

    let icon: String
    let title: String
    let message: String

    var body: some View {
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
                .font(type.body1)
                .foregroundStyle(.white.opacity(0.8))

            Spacer()
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 16)
    }
}

#Preview {
    InsightsEmptyState(
        icon: "sparkles",
        title: "No insights yet",
        message: "Your insights will appear here after journaling."
    )
    .background(Color.purple)
    .useTypography()
}
