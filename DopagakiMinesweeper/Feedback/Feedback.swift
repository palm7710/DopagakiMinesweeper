import UIKit
import AVFoundation

// MARK: - 振動

enum Haptics {
    static var isEnabled = true

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle, intensity: CGFloat = 1) {
        guard isEnabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred(intensity: intensity)
    }

    static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
}

// MARK: - 効果音（音声ファイル不要。その場で波形を合成する）

enum SoundEffect {
    /// マスを開けた音。step（コンボ数）が上がるほど音程が上がる
    case open(step: Int)
    case flag
    case explosion
    case fanfare
    case fever
    case revive
    case radar
    case button
}

final class SoundEngine {
    static let shared = SoundEngine()

    var isEnabled = true

    private enum Wave: String { case sine, square, triangle }

    private let engine = AVAudioEngine()
    private var players: [AVAudioPlayerNode] = []
    private var nextPlayer = 0
    private let sampleRate: Double = 44_100
    private let format: AVAudioFormat
    private var cache: [String: AVAudioPCMBuffer] = [:]

    private init() {
        format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
        for _ in 0..<8 {
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
            players.append(player)
        }
        engine.mainMixerNode.outputVolume = 0.6
        try? engine.start()
    }

    func play(_ effect: SoundEffect) {
        guard isEnabled else { return }
        if !engine.isRunning { try? engine.start() }
        guard engine.isRunning else { return }

        switch effect {
        case .open(let step):
            let semitones = Double(min(max(step - 1, 0), 24))
            schedule([tone(523.25 * pow(2, semitones / 12), 0.09, .square, decay: 28)])
        case .flag:
            schedule([tone(330, 0.08, .triangle, decay: 30)])
        case .button:
            schedule([tone(880, 0.05, .triangle, decay: 40)])
        case .radar:
            schedule([tone(1200, 0.07, .sine, decay: 25), tone(1600, 0.1, .sine, decay: 25)])
        case .explosion:
            schedule([noise(0.8, decay: 5)])
        case .fanfare:
            schedule([523.25, 659.25, 783.99].map { tone($0, 0.1, .square, decay: 14) }
                     + [tone(1046.5, 0.45, .square, decay: 5)])
        case .fever:
            schedule([659.25, 783.99, 987.77, 1318.5, 1568].map { tone($0, 0.06, .square, decay: 18) })
        case .revive:
            schedule([392, 523.25, 659.25].map { tone($0, 0.1, .triangle, decay: 12) })
        }
    }

    private func schedule(_ buffers: [AVAudioPCMBuffer]) {
        let player = players[nextPlayer]
        nextPlayer = (nextPlayer + 1) % players.count
        player.stop()
        for buffer in buffers {
            player.scheduleBuffer(buffer, completionHandler: nil)
        }
        player.play()
    }

    private func tone(_ freq: Double, _ duration: Double, _ wave: Wave, decay: Double) -> AVAudioPCMBuffer {
        let key = "\(wave.rawValue)-\(Int(freq))-\(duration)-\(decay)"
        if let cached = cache[key] { return cached }
        let buffer = makeBuffer(duration) { t in
            let phase = 2 * Double.pi * freq * t
            let s: Double
            switch wave {
            case .sine: s = sin(phase)
            case .square: s = sin(phase) >= 0 ? 0.5 : -0.5
            case .triangle: s = 2 / Double.pi * asin(sin(phase))
            }
            return s * Self.envelope(t, decay: decay) * 0.35
        }
        cache[key] = buffer
        return buffer
    }

    private func noise(_ duration: Double, decay: Double) -> AVAudioPCMBuffer {
        let key = "noise-\(duration)-\(decay)"
        if let cached = cache[key] { return cached }
        var filtered = 0.0
        let buffer = makeBuffer(duration) { t in
            filtered += 0.18 * (Double.random(in: -1...1) - filtered)
            let thump = sin(2 * Double.pi * 55 * t) * exp(-t * 7)
            return (filtered * 1.6 + thump * 0.8) * Self.envelope(t, decay: decay) * 0.5
        }
        cache[key] = buffer
        return buffer
    }

    private static func envelope(_ t: Double, decay: Double) -> Double {
        min(1, t / 0.004) * exp(-t * decay)
    }

    private func makeBuffer(_ duration: Double, sample: (Double) -> Double) -> AVAudioPCMBuffer {
        let frames = AVAudioFrameCount(duration * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames)!
        buffer.frameLength = frames
        let data = buffer.floatChannelData![0]
        for i in 0..<Int(frames) {
            data[i] = Float(sample(Double(i) / sampleRate))
        }
        return buffer
    }
}
