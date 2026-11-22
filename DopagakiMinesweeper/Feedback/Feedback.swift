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
    // 刺激モード
    case bounce
    case buy
    case cash
    case notify
    case gacha
    case ssr
    case cry
    case crack
    case slotStop
}

/// 流しっぱなしにする環境音（刺激モードのショップで買う）
enum LoopSound: CaseIterable {
    case lofi
    /// メロディとベースが重なったローファイ（2個目から）
    case lofiPlus
    case rain
    case heartbeat
}

final class SoundEngine {
    static let shared = SoundEngine()

    var isEnabled = true {
        didSet { refreshLoops() }
    }

    private enum Wave: String { case sine, square, triangle }

    private let engine = AVAudioEngine()
    private var players: [AVAudioPlayerNode] = []
    private var nextPlayer = 0
    private let sampleRate: Double = 44_100
    private let format: AVAudioFormat
    private var cache: [String: AVAudioPCMBuffer] = [:]
    private var loopPlayers: [LoopSound: AVAudioPlayerNode] = [:]
    private var loopBuffers: [LoopSound: AVAudioPCMBuffer] = [:]
    private var wantedLoops: Set<LoopSound> = []
    private var playingLoops: Set<LoopSound> = []

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
        for loop in LoopSound.allCases {
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
            switch loop {
            case .lofi, .lofiPlus: player.volume = 0.55
            case .rain: player.volume = 0.4
            case .heartbeat: player.volume = 0.9
            }
            loopPlayers[loop] = player
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
        case .bounce:
            schedule([tone(1400, 0.035, .sine, decay: 70)])
        case .buy:
            schedule([783.99, 1046.5, 1568].map { tone($0, 0.07, .triangle, decay: 20) })
        case .cash:
            schedule([tone(1318.5, 0.05, .square, decay: 30), tone(1760, 0.14, .square, decay: 18)])
        case .notify:
            schedule([tone(880, 0.08, .sine, decay: 20), tone(1318.5, 0.12, .sine, decay: 16)])
        case .gacha:
            schedule([523.25, 659.25, 783.99, 1046.5].map { tone($0, 0.05, .square, decay: 25) })
        case .ssr:
            schedule([523.25, 659.25, 783.99, 1046.5, 1318.5, 1568].map { tone($0, 0.05, .square, decay: 20) }
                     + [tone(2093, 0.5, .square, decay: 5)])
        case .cry:
            schedule([659.25, 587.33, 493.88].map { tone($0, 0.16, .triangle, decay: 9) })
        case .crack:
            schedule([noise(0.18, decay: 22), tone(2600, 0.04, .square, decay: 60)])
        case .slotStop:
            schedule([tone(220, 0.06, .square, decay: 35)])
        }
    }

    // MARK: 環境音ループ

    func setLoop(_ loop: LoopSound, on: Bool) {
        if on { wantedLoops.insert(loop) } else { wantedLoops.remove(loop) }
        refreshLoops()
    }

    func stopAllLoops() {
        wantedLoops.removeAll()
        refreshLoops()
    }

    private func refreshLoops() {
        for loop in LoopSound.allCases {
            guard let player = loopPlayers[loop] else { continue }
            let want = isEnabled && wantedLoops.contains(loop)
            if want && !playingLoops.contains(loop) {
                if !engine.isRunning { try? engine.start() }
                guard engine.isRunning else { continue }
                player.stop()
                player.scheduleBuffer(loopBuffer(loop), at: nil, options: .loops, completionHandler: nil)
                player.play()
                playingLoops.insert(loop)
            } else if !want && playingLoops.contains(loop) {
                player.stop()
                playingLoops.remove(loop)
            }
        }
    }

    private func loopBuffer(_ loop: LoopSound) -> AVAudioPCMBuffer {
        if let cached = loopBuffers[loop] { return cached }
        let buffer: AVAudioPCMBuffer
        switch loop {
        case .lofi: buffer = makeLofi(extra: false)
        case .lofiPlus: buffer = makeLofi(extra: true)
        case .rain: buffer = makeRain()
        case .heartbeat: buffer = makeHeartbeat()
        }
        loopBuffers[loop] = buffer
        return buffer
    }

    /// 72BPM・4小節のゆるいビート（コード、キック、スネア、ハイハット、レコードのノイズ）
    private func makeLofi(extra: Bool) -> AVAudioPCMBuffer {
        let beat = 60.0 / 72
        let bar = beat * 4
        let chords: [[Double]] = [
            [174.61, 220.00, 261.63, 329.63],
            [164.81, 196.00, 246.94, 293.66],
            [146.83, 174.61, 220.00, 261.63],
            [130.81, 164.81, 196.00, 246.94]
        ]
        var lp = 0.0
        var noiseLP = 0.0
        return makeBuffer(bar * 4) { t in
            let barIndex = min(3, Int(t / bar))
            let tb = t - Double(barIndex) * bar
            let wobble = 1 + 0.004 * sin(2 * .pi * 0.4 * t)
            var pad = 0.0
            for f in chords[barIndex] {
                pad += sin(2 * .pi * f * wobble * t) + 0.3 * sin(2 * .pi * f * 2 * t)
            }
            pad *= 0.05 * min(1, tb / 0.25) * (0.6 + 0.4 * exp(-tb * 0.8))

            let tBeat = t.truncatingRemainder(dividingBy: beat)
            let beatIndex = Int(t / beat) % 4
            var drums = 0.0
            if beatIndex == 0 || beatIndex == 2 {
                drums += sin(2 * .pi * (50 + 60 * exp(-tBeat * 25)) * tBeat) * exp(-tBeat * 8) * 0.6
            }
            let n = Double.random(in: -1...1)
            noiseLP += 0.35 * (n - noiseLP)
            if beatIndex == 1 || beatIndex == 3 {
                drums += noiseLP * exp(-tBeat * 16) * 0.35
            }
            let tEighth = t.truncatingRemainder(dividingBy: beat / 2)
            drums += (n - noiseLP) * exp(-tEighth * 70) * 0.07
            let crackle = Double.random(in: 0..<1) < 0.0004 ? Double.random(in: -0.3...0.3) : 0

            var lead = 0.0
            if extra {
                // ベース（コードの一番下の音を1オクターブ下で）
                let root = chords[barIndex][0] / 2
                lead += sin(2 * .pi * root * t) * 0.12 * (0.5 + 0.5 * exp(-tBeat * 3))
                // 8分音符のメロディ（コードの音を順番に）
                let eighth = beat / 2
                let step = Int(t / eighth)
                let notes = chords[barIndex]
                let f = notes[(step * 3 + barIndex) % notes.count] * 2
                let te = t.truncatingRemainder(dividingBy: eighth)
                lead += (sin(2 * .pi * f * te) > 0 ? 0.05 : -0.05) * exp(-te * 9)
            }
            lp += 0.25 * (pad + drums + lead - lp)
            return lp + crackle + noiseLP * 0.01
        }
    }

    /// ドクン、ドクン（80BPM）
    private func makeHeartbeat() -> AVAudioPCMBuffer {
        makeBuffer(0.75) { t in
            var s = 0.0
            for (start, amp) in [(0.0, 1.0), (0.2, 0.7)] where t >= start {
                let d = t - start
                s += sin(2 * .pi * (48 + 30 * exp(-d * 30)) * d) * exp(-d * 18) * amp
            }
            return s * 0.8
        }
    }

    /// 雨音（ろ過したノイズ＋ときどきの雫）
    private func makeRain() -> AVAudioPCMBuffer {
        var a = 0.0
        var b = 0.0
        var dripT = 1.0
        var dripF = 2000.0
        return makeBuffer(6) { _ in
            let n = Double.random(in: -1...1)
            a += 0.08 * (n - a)
            b += 0.5 * (n - b)
            dripT += 1 / 44_100
            if Double.random(in: 0..<1) < 0.00012 {
                dripT = 0
                dripF = Double.random(in: 1500...3200)
            }
            let drip = sin(2 * .pi * dripF * dripT) * exp(-dripT * 60) * 0.15
            return a * 0.9 + (n - b) * 0.08 + drip
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

// MARK: - 実況ボイス（刺激モード）

@MainActor
final class HypeVoice {
    static let shared = HypeVoice()

    private let synth = AVSpeechSynthesizer()

    func say(_ text: String) {
        guard SoundEngine.shared.isEnabled, !synth.isSpeaking else { return }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "ja-JP")
        utterance.rate = 0.58
        utterance.pitchMultiplier = 1.6
        synth.speak(utterance)
    }

    func stop() {
        synth.stopSpeaking(at: .immediate)
    }
}
