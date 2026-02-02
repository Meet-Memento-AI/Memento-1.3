//
//  ChatInputField.swift
//  MeetMemento
//
//  Input field component for AI Chat interface with send button
//  Matches Claude/ChatGPT style with send button positioned inside input field
//

import SwiftUI

public struct ChatInputField: View {
    @Binding var text: String
    var isSending: Bool
    var onSend: () -> Void
    /// When false, input and all buttons are disabled (e.g. carousel preview in WelcomeView).
    var isInteractive: Bool = true

    @Environment(\.theme) private var theme
    @FocusState private var isFocused: Bool
    @StateObject private var speechService = SpeechService.shared
    @State private var showPermissionDenied = false
    @State private var showSTTError = false

    public init(
        text: Binding<String>,
        isSending: Bool = false,
        isInteractive: Bool = true,
        onSend: @escaping () -> Void
    ) {
        self._text = text
        self.isSending = isSending
        self.isInteractive = isInteractive
        self.onSend = onSend
    }

    // MARK: - Body

    public var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // TextField container with white background and fixed 120px min height
            ZStack(alignment: .center) {
                if speechService.isRecording {
                    VoiceWaveView(audioLevel: speechService.audioLevel)
                        .frame(height: 24) // Match roughly the line height of text input
                        .padding(.leading, 16)
                        .padding(.trailing, 56)
                        .padding(.vertical, 16)
                        .transition(.opacity)
                } else {
                    // Default Text Input State
                    ZStack(alignment: .topLeading) {
                        // Placeholder Text
                        if text.isEmpty {
                            Text("Chat with Memento")
                                .typographyBody1()
                                .foregroundStyle(GrayScale.gray500)
                                .padding(.leading, 16)
                                .padding(.top, 16)
                        }
                        
                        // TextField with top-aligned text
                        TextField("", text: $text, axis: .vertical)
                            .typographyBody1()
                            .foregroundStyle(theme.foreground)
                            .focused($isFocused)
                            .lineLimit(1...5)
                            .textInputAutocapitalization(.sentences)
                            .submitLabel(.send)
                            .disabled(!isInteractive)
                            .onSubmit {
                                guard isInteractive, isSendButtonEnabled else { return }
                                onSend()
                            }
                            .padding(.leading, 16)
                            .padding(.trailing, text.isEmpty ? 100 : 52) // Shrink when mic is hidden
                            .padding(.top, 16)
                            .padding(.bottom, 16)
                            .animation(.easeInOut(duration: 0.2), value: text.isEmpty)
                    }
                    .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 56) // Ensure full width and minimum height consistency
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: theme.radius.xl, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radius.xl, style: .continuous)
                    .stroke(theme.border.opacity(0.2), lineWidth: 0)
            )
            .animation(.easeInOut(duration: 0.2), value: speechService.isRecording)
            
            // Buttons positioned at bottom right
            HStack(spacing: 16) {
                if speechService.isRecording {
                    stopButton
                        .transition(.scale.combined(with: .opacity))
                } else {
                    if text.isEmpty {
                        microphoneButton
                            .transition(.scale.combined(with: .opacity))
                    }
                    sendButton
                }
            }
            .animation(.easeInOut(duration: 0.2), value: text.isEmpty)
            .padding(.trailing, 8)
            .padding(.bottom, 10) // Align center with single-line text (56/2 - 36/2 = 10)
        }
        .allowsHitTesting(isInteractive)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .onChange(of: speechService.isRecording) { oldValue, newValue in
            if oldValue == true && newValue == false && !speechService.transcribedText.isEmpty {
                insertTranscribedText(speechService.transcribedText)
            }
        }
        .onChange(of: speechService.transcribedText) { _, newText in
            if !newText.isEmpty && !speechService.isRecording {
                insertTranscribedText(newText)
            }
        }
        .alert("Microphone Access Required", isPresented: $showPermissionDenied) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("MeetMemento needs microphone access to transcribe your voice. Enable it in Settings > Privacy > Microphone.")
        }
        .alert("Recording Failed", isPresented: $showSTTError) {
            Button("Try Again") {
                Task {
                    do {
                        try await speechService.startRecording()
                    } catch {
                        showSTTError = true
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(speechService.errorMessage ?? "Unable to start recording. Please try again.")
        }
    }
    
    // MARK: - Microphone Button
    
    private var microphoneButton: some View {
        Button {
            guard isInteractive else { return }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            Task {
                do {
                    try await speechService.startRecording()
                } catch let error as SpeechService.SpeechError {
                    if case .permissionDenied = error {
                        showPermissionDenied = true
                    } else {
                        showSTTError = true
                    }
                } catch {
                    showSTTError = true
                }
            }
        } label: {
            Image(systemName: "mic")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(GrayScale.gray500)
                .frame(width: 36, height: 36)
                .background(Color.clear)
        }
        .disabled(speechService.isProcessing)
        .accessibilityLabel("Start voice input")
        .accessibilityHint("Double-tap to record your voice")
    }
    
    // MARK: - Stop Button
    
    private var stopButton: some View {
        Button {
            guard isInteractive else { return }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            Task {
                await speechService.stopRecording()
            }
        } label: {
            ZStack {
                Image(systemName: "square.fill") // Stop icon
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(width: 36, height: 36)
            .background(
                Circle()
                    .fill(Color.red)
            )
        }
        .accessibilityLabel("Stop voice input")
        .accessibilityHint("Double-tap to stop and insert text")
    }
    
    // MARK: - Send Button
    
    private var sendButton: some View {
        Button {
            guard isInteractive else { return }
            onSend()
        } label: {
            ZStack {
                if isSending {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.white)
                } else {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .frame(width: 36, height: 36)
            .background(
                Circle()
                    .fill(
                        isSendButtonEnabled
                            ? PrimaryScale.primary600
                            : theme.muted
                    )
            )
        }
        .disabled(!isInteractive || !isSendButtonEnabled || isSending)
        .animation(.easeInOut(duration: 0.2), value: isSendButtonEnabled)
    }
    
    private var isSendButtonEnabled: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func insertTranscribedText(_ transcribedText: String) {
        let trimmed = transcribedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if text.isEmpty {
            text = trimmed
        } else {
            text += "\n\n" + trimmed
        }
        speechService.transcribedText = ""
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        onSend()
    }
}

// MARK: - Voice Wave View (voice-reactive)
private struct VoiceWaveView: View {
    let audioLevel: Float
    private let barCount = 30
    private let minHeight: CGFloat = 4
    private let maxHeight: CGFloat = 20
    private let barWidth: CGFloat = 4
    private let barSpacing: CGFloat = 4

    private static func barVariation(for index: Int) -> CGFloat {
        let seed = sin(CGFloat(index) * 0.7) * 0.5 + 0.5
        return 0.7 + 0.3 * seed
    }

    var body: some View {
        HStack(spacing: barSpacing) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(GrayScale.gray400)
                    .frame(width: barWidth, height: barHeight(for: index))
                    .animation(.easeOut(duration: 0.12), value: audioLevel)
            }
        }
    }

    private func barHeight(for index: Int) -> CGFloat {
        let level = CGFloat(audioLevel)
        let variation = Self.barVariation(for: index)
        let amplitude = (maxHeight - minHeight) * level * variation
        return max(minHeight, minHeight + amplitude)
    }
}

// MARK: - Previews

#Preview("Input Field") {
    @Previewable @State var text = ""
    
    VStack {
        Spacer()
        ChatInputField(text: $text, onSend: {
            print("Send: \(text)")
        })
    }
    .useTheme()
    .useTypography()
    .background(Color.gray.opacity(0.1))
}

#Preview("Input Field Recording") {
    @Previewable @State var text = ""
    
    VStack {
        Spacer()
        // Note: Preview won't auto-trigger recording state unless we expose it,
        // but user can interact in preview
        ChatInputField(text: $text, onSend: {})
    }
    .useTheme()
    .useTypography()
    .background(Color.gray.opacity(0.1))
}
