//
//  SpeechService.swift
//  MeetMemento
//
//  Native iOS speech-to-text using Speech framework and AVFoundation.
//

import Foundation
import Speech
import AVFoundation


@MainActor
final class SpeechService: ObservableObject {
    static let shared = SpeechService()

    @Published var isRecording = false
    @Published var isProcessing = false
    @Published var transcribedText = ""
    @Published var errorMessage: String?
    @Published var currentDuration: TimeInterval = 0
    @Published var authorizationStatus: AuthorizationStatus = .notDetermined
    /// Real-time audio level 0...1 for voice-reactive UI (e.g. wave visualizer).
    @Published var audioLevel: Float = 0

    enum AuthorizationStatus {
        case notDetermined, denied, authorized
    }

    enum SpeechError: LocalizedError {
        case notAvailable
        case permissionDenied
        case audioSessionFailed(String)
        case engineStartFailed(String)

        var errorDescription: String? {
            switch self {
            case .notAvailable: return "Speech recognition not available"
            case .permissionDenied: return "Microphone or speech recognition permission denied"
            case .audioSessionFailed(let msg): return "Audio session error: \(msg)"
            case .engineStartFailed(let msg): return "Could not start recording: \(msg)"
            }
        }
    }

    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var durationTimer: Timer?
    private let audioQueue = DispatchQueue(label: "com.meetmemento.speech.audio")
    private var smoothedLevel: Float = 0

    private init() {}

    // MARK: - Audio level (for voice-reactive UI)

    private static func computeRMS(from buffer: AVAudioPCMBuffer) -> Float {
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return 0 }
        if let channelData = buffer.floatChannelData {
            let ptr = channelData[0]
            var sum: Float = 0
            for i in 0..<frameLength {
                let s = ptr[i]
                sum += s * s
            }
            let rms = sqrt(sum / Float(frameLength))
            return min(1, rms * 3)
        }
        if let channelData = buffer.int16ChannelData {
            let ptr = channelData[0]
            var sum: Float = 0
            let scale: Float = 1 / 32768
            for i in 0..<frameLength {
                let s = Float(ptr[i]) * scale
                sum += s * s
            }
            let rms = sqrt(sum / Float(frameLength))
            return min(1, rms * 3)
        }
        return 0
    }

    private func updateAudioLevel(_ rms: Float) {
        smoothedLevel = smoothedLevel * 0.3 + rms * 0.7
        audioLevel = smoothedLevel
    }

    /// Converts buffer to 16 kHz mono for Speech framework; returns nil on failure.
    /// Output buffer capacity must be >= input frame length per AVAudioConverter requirement.
    private static func convertTo16kMono(_ buffer: AVAudioPCMBuffer, inputFormat: AVAudioFormat, converter: AVAudioConverter, outputFormat: AVAudioFormat) -> AVAudioPCMBuffer? {
        let outFrameCount = AVAudioFrameCount(Double(buffer.frameLength) * 16000.0 / inputFormat.sampleRate + 1)
        let capacity = max(outFrameCount, buffer.frameLength)
        guard let outBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: capacity) else { return nil }
        do {
            try converter.convert(to: outBuffer, from: buffer)
            return outBuffer
        } catch {
            return nil
        }
    }

    // MARK: - Authorization

    func requestAuthorization() async -> AuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { [weak self] status in
                Task { @MainActor in
                    let auth: AuthorizationStatus
                    switch status {
                    case .notDetermined: auth = .notDetermined
                    case .denied: auth = .denied
                    case .restricted: auth = .denied
                    case .authorized: auth = .authorized
                    @unknown default: auth = .denied
                    }
                    self?.authorizationStatus = auth
                    continuation.resume(returning: auth)
                }
            }
        }
    }

    private func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    private func checkAvailability() throws {
        guard let recognizer = SFSpeechRecognizer(locale: Locale.current), recognizer.isAvailable else {
            throw SpeechError.notAvailable
        }
    }

    private func handleRecognitionResult(_ result: SFSpeechRecognitionResult?, _ error: Error?) {
        if let error = error {
            errorMessage = error.localizedDescription
            isProcessing = false
            isRecording = false
            recognitionTask = nil
            recognitionRequest = nil
            return
        }
        guard let result = result else { return }
        if result.isFinal {
            let best = result.bestTranscription.formattedString
            if !best.isEmpty {
                transcribedText = best
            }
            isProcessing = false
            recognitionTask = nil
            recognitionRequest = nil
        }
    }

    /// Runs on a background thread to avoid blocking the main thread (watchdog / SIGKILL).
    private nonisolated static func performEngineSetup(
        recognizer: SFSpeechRecognizer,
        onResult: @escaping (SFSpeechRecognitionResult?, Error?) -> Void,
        onLevel: @escaping (Float) -> Void
    ) throws -> (AVAudioEngine, SFSpeechAudioBufferRecognitionRequest, SFSpeechRecognitionTask) {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: [.allowBluetooth])
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.taskHint = .dictation
        if #available(iOS 16.0, *) {
            request.addsPunctuation = true
        }

        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        let speechFormat: AVAudioFormat?
        let converter: AVAudioConverter?
        if inputFormat.sampleRate == 16000 && inputFormat.channelCount == 1 {
            speechFormat = nil
            converter = nil
        } else {
            speechFormat = AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1)
            converter = speechFormat.flatMap { AVAudioConverter(from: inputFormat, to: $0) }
        }

        let task = recognizer.recognitionTask(with: request) { result, error in
            onResult(result, error)
        }

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { buffer, _ in
            let toAppend: AVAudioPCMBuffer
            if let conv = converter, let outFmt = speechFormat,
               let converted = Self.convertTo16kMono(buffer, inputFormat: inputFormat, converter: conv, outputFormat: outFmt) {
                toAppend = converted
            } else {
                toAppend = buffer
            }
            request.append(toAppend)
            onLevel(Self.computeRMS(from: buffer))
        }

        try engine.start()
        return (engine, request, task)
    }

    // MARK: - Recording

    func startRecording() async throws {
        errorMessage = nil
        transcribedText = ""

        // 1. Speech authorization
        let speechAuth = await requestAuthorization()
        if speechAuth != .authorized {
            authorizationStatus = speechAuth
            errorMessage = SpeechError.permissionDenied.errorDescription
            throw SpeechError.permissionDenied
        }

        // 2. Microphone permission
        let micGranted = await requestMicrophonePermission()
        if !micGranted {
            errorMessage = SpeechError.permissionDenied.errorDescription
            throw SpeechError.permissionDenied
        }

        // 3. Recognizer available
        do {
            try checkAvailability()
        } catch {
            errorMessage = (error as? SpeechError)?.errorDescription ?? error.localizedDescription
            throw error
        }

        guard let recognizer = SFSpeechRecognizer(locale: Locale.current) else {
            errorMessage = SpeechError.notAvailable.errorDescription
            throw SpeechError.notAvailable
        }

        // 4–7. Run audio session + engine setup off the main thread to avoid watchdog SIGKILL
        let onResult: (SFSpeechRecognitionResult?, Error?) -> Void = { [weak self] result, error in
            Task { @MainActor in
                self?.handleRecognitionResult(result, error)
            }
        }
        let onLevel: (Float) -> Void = { [weak self] rms in
            Task { @MainActor in
                self?.updateAudioLevel(rms)
            }
        }

        let setupResult: Result<(AVAudioEngine, SFSpeechAudioBufferRecognitionRequest, SFSpeechRecognitionTask), Error>
        do {
            let triple = try await Task.detached(priority: .userInitiated) {
                try Self.performEngineSetup(recognizer: recognizer, onResult: onResult, onLevel: onLevel)
            }.value
            setupResult = .success(triple)
        } catch {
            setupResult = .failure(error)
        }

        switch setupResult {
        case .failure(let error):
            let msg = (error as NSError).localizedDescription
            errorMessage = (SpeechError.engineStartFailed(msg)).errorDescription
            isProcessing = false
            throw SpeechError.engineStartFailed(msg)
        case .success((let engine, let request, let task)):
            audioEngine = engine
            recognitionRequest = request
            recognitionTask = task
            isProcessing = true
            isRecording = true

            let startTime = Date()
            durationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    guard let self = self, self.isRecording else { return }
                    self.currentDuration = Date().timeIntervalSince(startTime)
                }
            }
            RunLoop.main.add(durationTimer!, forMode: .common)
        }
    }

    func stopRecording() async {
        durationTimer?.invalidate()
        durationTimer = nil
        currentDuration = 0

        recognitionRequest?.endAudio()
        // Do not cancel the task — let it finish so we get the final transcription in the callback

        if let engine = audioEngine {
            let inputNode = engine.inputNode
            inputNode.removeTap(onBus: 0)
            engine.stop()
        }
        audioEngine = nil

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        audioLevel = 0
        smoothedLevel = 0
        isRecording = false
        // transcribedText already set in recognition task callback when isFinal; if not, partial may be in transcribedText from last callback
    }
}
