//
//  VideoBackground.swift
//  MeetMemento
//
//  Reusable video background component with seamless looping.
//

import SwiftUI
import UIKit
import AVKit

struct VideoBackground: UIViewRepresentable {
    let videoName: String
    let videoExtension: String

    init(videoName: String, videoExtension: String = "mp4") {
        self.videoName = videoName
        self.videoExtension = videoExtension
    }

    func makeUIView(context: Context) -> PlayerUIView {
        let view = PlayerUIView(frame: .zero)
        view.videoName = videoName
        view.videoExtension = videoExtension
        return view
    }

    func updateUIView(_ uiView: PlayerUIView, context: Context) {}
}

class PlayerUIView: UIView {
    var videoName: String = ""
    var videoExtension: String = "mp4"

    override init(frame: CGRect) {
        super.init(frame: frame)
        isAccessibilityElement = false
        accessibilityElementsHidden = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        isAccessibilityElement = false
        accessibilityElementsHidden = true
    }

    private var playerLayer: AVPlayerLayer?
    private var playerLooper: AVPlayerLooper?
    private var queuePlayer: AVQueuePlayer?

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds

        if queuePlayer == nil {
            setupPlayer()
        }
    }

    private func setupPlayer() {
        guard let url = Bundle.main.url(forResource: videoName, withExtension: videoExtension) else {
            #if DEBUG
            print("⚠️ VideoBackground: Could not find \(videoName).\(videoExtension) in bundle")
            #endif
            return
        }

        let asset = AVAsset(url: url)
        let item = AVPlayerItem(asset: asset)
        let queuePlayer = AVQueuePlayer(playerItem: item)
        self.queuePlayer = queuePlayer

        // Create looper for seamless loop
        playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: item)

        // Setup layer
        let playerLayer = AVPlayerLayer(player: queuePlayer)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.frame = bounds
        layer.addSublayer(playerLayer)
        self.playerLayer = playerLayer

        // Mute and play
        queuePlayer.isMuted = true
        queuePlayer.play()
    }

    deinit {
        queuePlayer?.pause()
        queuePlayer = nil
        playerLooper = nil
    }
}

// MARK: - Preview

#Preview {
    VideoBackground(videoName: "welcome-bg", videoExtension: "mp4")
        .ignoresSafeArea()
}
