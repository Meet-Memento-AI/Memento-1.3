//
//  AIChatView.swift
//  MeetMemento
//
//  AI Chat interface for conversing with journal insights AI
//

import SwiftUI

public struct AIChatView: View {
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type
    @Environment(\.dismiss) private var dismiss
    
    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var isSending: Bool = false
    @State private var reviewedJournalCount: Int = 5 // Mock data
    @State private var selectedCitations: [JournalCitation]? = nil
    @State private var showCitationsSheet = false
    @FocusState private var isInputFocused: Bool
    
    public init() {}
    
    public var body: some View {
        ZStack(alignment: .top) {
            // Background
            theme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Messages list
                messagesScrollView
                
                // Input area
                inputArea
            }
            
            // Secondary Header with back button (Layered on top)
            Header(
                onBackTapped: { dismiss() }
            )
        }
        .toolbar(.hidden, for: .navigationBar)
        .background(SwipeBackEnabler())
        .onAppear {
            loadInitialState()
        }
        .sheet(isPresented: $showCitationsSheet) {
            if let citations = selectedCitations {
                CitationsBottomSheet(citations: citations)
            }
        }
    }
    
    // MARK: - Messages Scroll View
    
    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    if messages.isEmpty {
                        ChatEmptyState()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.top, 160)
                            .id("empty")
                    } else {
                        ForEach(messages) { message in
                            ChatMessageBubble(
                                message: message,
                                onCitationsTapped: {
                                    if let citations = message.citations, !citations.isEmpty {
                                        selectedCitations = citations
                                        showCitationsSheet = true
                                    }
                                }
                            )
                            .id(message.id)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                .padding(.top, 100) // Clear the header height (Safe area + 44 + gradient)
            }
            .onChange(of: messages.count) { oldCount, newCount in
                // Auto-scroll to bottom when new message arrives
                if newCount > oldCount, let lastMessage = messages.last {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    // MARK: - Journal Review Indicator
    
    private var journalReviewIndicator: some View {
        JournalReviewIndicator(reviewedCount: reviewedJournalCount)
    }
    
    // MARK: - Input Area
    
    private var inputArea: some View {
        VStack(spacing: 0) {
            
            // Input container
            ChatInputField(
                text: $inputText,
                isSending: isSending,
                onSend: sendMessage
            )
        }
    }
    
    // MARK: - Actions
    
    private func loadInitialState() {
        // Mock initial messages for UI preview (remove when backend is ready)
        // For now, start with empty state
        messages = []
        reviewedJournalCount = 5 // Mock data
    }
    
    private func sendMessage() {
        let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty, !isSending else { return }
        
        // Add user message
        let userMessage = ChatMessage(
            content: trimmedText,
            isFromUser: true
        )
        messages.append(userMessage)
        
        // Clear input
        inputText = ""
        isInputFocused = false
        
        // Simulate AI response (remove when backend is ready)
        isSending = true
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        
        // Simulate delay for AI response
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            
            await MainActor.run {
                // Mock AI response with structured content (replace with actual API call)
                // Example: AI response with headings, body, and citations
                let mockCitations: [JournalCitation]? = [
                    JournalCitation(
                        entryId: UUID(),
                        entryTitle: "Morning Thoughts",
                        entryDate: Date().addingTimeInterval(-86400 * 2),
                        excerpt: "Work has been stressful this week. I've been feeling overwhelmed with deadlines and meetings."
                    )
                ]
                
                let aiResponse = ChatMessage.aiMessage(
                    heading1: "Understanding Your Patterns",
                    heading2: "Key Insights",
                    body: "Based on your journal entries, I've noticed several patterns. **Work-related stress** appears frequently, especially around deadlines. You've also mentioned *feeling more balanced* after taking walks.",
                    citations: mockCitations
                )
                messages.append(aiResponse)
                isSending = false
            }
        }
    }
}

// MARK: - Previews

#Preview("Empty State") {
    NavigationStack {
        AIChatView()
    }
    .useTheme()
    .useTypography()
}

#Preview("With Messages") {
    NavigationStack {
        AIChatView()
            .onAppear {
                // Mock messages for preview
            }
    }
    .useTheme()
    .useTypography()
}

#Preview("Dark Mode") {
    NavigationStack {
        AIChatView()
    }
    .useTheme()
    .useTypography()
    .preferredColorScheme(.dark)
}

// MARK: - Swipe Back Enabler
// Helper to re-enable the interactive pop gesture when the navigation bar is hidden
private struct SwipeBackEnabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Re-enable the interactive pop gesture recognizer
        DispatchQueue.main.async {
            uiViewController.navigationController?.interactivePopGestureRecognizer?.delegate = nil
            uiViewController.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        }
    }
}
