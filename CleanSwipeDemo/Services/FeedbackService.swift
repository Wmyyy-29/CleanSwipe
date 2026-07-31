import AVFoundation
import UIKit

final class FeedbackService {
    static let shared = FeedbackService()

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    private var started = false

    var soundEnabled = true
    var hapticsEnabled = true

    private init() {
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
    }

    func play(for decision: ReviewDecision) {
        if hapticsEnabled {
            playHaptic(for: decision)
        }
        if soundEnabled {
            playTone(for: decision)
        }
    }

    func playUndo() {
        if hapticsEnabled {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        }
        if soundEnabled {
            scheduleTone(startFrequency: 520, endFrequency: 310, duration: 0.12, volume: 0.10)
        }
    }

    func playSuccess() {
        if hapticsEnabled {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        guard soundEnabled else { return }
        scheduleTone(startFrequency: 440, endFrequency: 660, duration: 0.12, volume: 0.11)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            self?.scheduleTone(startFrequency: 660, endFrequency: 880, duration: 0.16, volume: 0.10)
        }
    }

    private func playHaptic(for decision: ReviewDecision) {
        switch decision {
        case .keep:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .delete:
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        case .later:
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        }
    }

    private func playTone(for decision: ReviewDecision) {
        switch decision {
        case .keep:
            scheduleTone(startFrequency: 570, endFrequency: 760, duration: 0.10, volume: 0.09)
        case .delete:
            scheduleTone(startFrequency: 260, endFrequency: 190, duration: 0.09, volume: 0.10)
        case .later:
            scheduleTone(startFrequency: 420, endFrequency: 420, duration: 0.07, volume: 0.07)
        }
    }

    private func scheduleTone(
        startFrequency: Double,
        endFrequency: Double,
        duration: Double,
        volume: Float
    ) {
        let frameCount = AVAudioFrameCount(format.sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let channel = buffer.floatChannelData?[0] else { return }

        buffer.frameLength = frameCount
        for frame in 0..<Int(frameCount) {
            let progress = Double(frame) / Double(max(Int(frameCount) - 1, 1))
            let frequency = startFrequency + (endFrequency - startFrequency) * progress
            let envelope = sin(.pi * progress)
            let value = sin(2 * .pi * frequency * Double(frame) / format.sampleRate)
            channel[frame] = Float(value * envelope) * volume
        }

        do {
            if !started {
                try engine.start()
                player.play()
                started = true
            } else if !player.isPlaying {
                player.play()
            }
            player.scheduleBuffer(buffer, at: nil, options: [])
        } catch {
            // Sound is optional; haptics continue to work if audio setup is unavailable.
        }
    }
}

