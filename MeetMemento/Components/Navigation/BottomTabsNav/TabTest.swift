//
//  TabTest.swift
//  MeetMemento
//
//  Test component for iOS 26+ tab bar features including:
//  - Left-aligned tab bar
//  - Compose overlay with matched geometry transitions
//  - Tab bar minimize behavior on scroll
//

import SwiftUI

/// Test component for experimenting with iOS 26+ tab bar features
public struct TabTest: View {
    @State private var selectedTab: TestTabType = .journal
    @State private var showComposeOverlay: Bool = false
    @Namespace private var composeNamespace

    public init() {}
    
    public var body: some View {
        if #available(iOS 26.0, *) {
            // iOS 26+: Left-aligned tabs with compose overlay
            TabView(selection: $selectedTab) {
                // Only iterate through navigation tabs (exclude compose)
                ForEach([TestTabType.journal, TestTabType.insights], id: \.self) { tab in
                    Tab(value: tab) {
                        tabContent(for: tab)
                            .toolbar {
                                // Add compose button in toolbar for space-between layout
                                ToolbarItem(placement: .bottomBar) {
                                    Spacer()
                                }
                                ToolbarItem(placement: .bottomBar) {
                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            showComposeOverlay = true
                                        }
                                    } label: {
                                        Image(systemName: "square.and.pencil")
                                            .font(.system(size: 22, weight: .semibold))
                                            .foregroundStyle(.white)
                                            .frame(width: 56, height: 56)
                                            .background {
                                                Circle()
                                                    .fill(PrimaryScale.primary600)
                                            }
                                            .shadow(
                                                color: PrimaryScale.primary600.opacity(0.3),
                                                radius: 12,
                                                x: 0,
                                                y: 4
                                            )
                                    }
                                    .matchedTransitionSource(
                                        id: "compose-button",
                                        in: composeNamespace
                                    )
                                    .accessibilityLabel("New Journal Entry")
                                }
                            }
                    } label: {
                        Label(tab.title, systemImage: tab.systemImage)
                    }
                }
            }
            .tint(PrimaryScale.primary600)
            .tabViewStyle(.automatic)  // Use .automatic for left-aligned tabs
            .tabBarMinimizeBehavior(.onScrollDown)  // Auto-hide on scroll
            .overlay {
                // Compose overlay sheet
                if showComposeOverlay {
                    composeOverlayView
                }
            }
        } else {
            // iOS 25 and below: Fallback
            TabView(selection: $selectedTab) {
                NavigationStack {
                    VStack {
                        Text("Journal Tab")
                            .font(.largeTitle)
                            .padding()
                        Spacer()
                    }
                    .navigationTitle("Journal")
                    .toolbar {
                        ToolbarItemGroup(placement: .bottomBar) {
                            Spacer()
                            Button {
                                print("New Journal tapped")
                            } label: {
                                Label("New Journal", systemImage: "square.and.pencil")
                                    .labelStyle(.iconOnly)
                            }
                        }
                    }
                }
                .tabItem {
                    Label("Journal", systemImage: "book.closed.fill")
                }
                .tag(TestTabType.journal)

                NavigationStack {
                    VStack {
                        Text("Insights Tab")
                            .font(.largeTitle)
                            .padding()
                        Spacer()
                    }
                    .navigationTitle("Insights")
                    .toolbar {
                        ToolbarItemGroup(placement: .bottomBar) {
                            Spacer()
                            Button {
                                print("New Journal tapped")
                            } label: {
                                Label("New Journal", systemImage: "square.and.pencil")
                                    .labelStyle(.iconOnly)
                            }
                        }
                    }
                }
                .tabItem {
                    Label("Insights", systemImage: "sparkles")
                }
                .tag(TestTabType.insights)
            }
            .tint(PrimaryScale.primary600)
        }
    }

    // MARK: - Tab Content Helper

    @ViewBuilder
    private func tabContent(for tab: TestTabType) -> some View {
        NavigationStack {
            VStack {
                Text("\(tab.title) Tab")
                    .font(.largeTitle)
                    .padding()
                Spacer()
            }
            .navigationTitle(tab.title)
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Compose Overlay

    @available(iOS 18.0, *)
    @ViewBuilder
    private var composeOverlayView: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showComposeOverlay = false
                    }
                }

            VStack {
                Spacer()

                // Compose card
                VStack(spacing: 20) {
                    HStack {
                        Text("New Journal Entry")
                            .font(.title2)
                            .fontWeight(.bold)

                        Spacer()

                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showComposeOverlay = false
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Placeholder content
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.secondary.opacity(0.1))
                        .frame(height: 200)
                        .overlay {
                            Text("Compose View")
                                .foregroundStyle(.secondary)
                        }

                    // Action button
                    Button {
                        print("Create entry")
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showComposeOverlay = false
                        }
                    } label: {
                        Text("Create Entry")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(PrimaryScale.primary600)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(24)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .padding(.horizontal, 20)
                .matchedTransitionSource(id: "compose-content", in: composeNamespace)

                Spacer()
                    .frame(height: 100)
            }
        }
        .transition(.opacity)
    }
}

// MARK: - Test Tab Type

enum TestTabType: String, CaseIterable, Identifiable, Hashable {
    case journal
    case insights
    case compose  // Compose tab (triggers overlay, not navigation)

    var id: String { rawValue }

    var title: String {
        switch self {
        case .journal: return "Journal"
        case .insights: return "Insights"
        case .compose: return "" // Empty for compose (icon-only)
        }
    }

    var systemImage: String {
        switch self {
        case .journal: return "book.closed"
        case .insights: return "sparkles"
        case .compose: return "square.and.pencil"
        }
    }
}

// MARK: - Preview

#Preview("TabTest") {
    TabTest()
        .preferredColorScheme(.light)
}
