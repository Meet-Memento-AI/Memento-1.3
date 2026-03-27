//
//  ScrollEdgeFade.swift
//  MeetMemento
//
//  A gradient overlay for scroll view edges
//  Fully obscures content at the edge (100% opacity) fading to transparent (0%)
//

import SwiftUI

struct ScrollEdgeFade: View {
    enum Edge { case top, bottom }

    let edge: Edge
    let height: CGFloat

    @Environment(\.theme) private var theme

    var body: some View {
        LinearGradient(
            stops: edge == .top
                ? [
                    .init(color: theme.background, location: 0.0),
                    .init(color: theme.background, location: 0.3),
                    .init(color: theme.background.opacity(0.8), location: 0.5),
                    .init(color: theme.background.opacity(0.4), location: 0.7),
                    .init(color: theme.background.opacity(0), location: 1.0)
                ]
                : [
                    .init(color: theme.background.opacity(0), location: 0.0),
                    .init(color: theme.background.opacity(0.4), location: 0.3),
                    .init(color: theme.background.opacity(0.8), location: 0.5),
                    .init(color: theme.background, location: 0.7),
                    .init(color: theme.background, location: 1.0)
                ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: height)
        .allowsHitTesting(false)
    }
}

#Preview("Top Edge") {
    ZStack {
        Color.blue
        VStack {
            ForEach(0..<10) { i in
                Text("Content Row \(i)")
                    .padding()
                    .background(Color.red.opacity(0.3))
            }
        }
        ScrollEdgeFade(edge: .top, height: 120)
            .frame(maxHeight: .infinity, alignment: .top)
    }
    .useTheme()
}

#Preview("Bottom Edge") {
    ZStack {
        Color.blue
        VStack {
            ForEach(0..<10) { i in
                Text("Content Row \(i)")
                    .padding()
                    .background(Color.red.opacity(0.3))
            }
        }
        ScrollEdgeFade(edge: .bottom, height: 120)
            .frame(maxHeight: .infinity, alignment: .bottom)
    }
    .useTheme()
}
