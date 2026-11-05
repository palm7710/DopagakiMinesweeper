import SwiftUI
import Observation

enum GamePhase {
    case ready, playing, won, lost
}

struct Popup: Identifiable {
    enum Kind { case score, chain, combo, fever, info }
    let id = UUID()
    let text: String
    let kind: Kind
    let row: Int
    let col: Int
}

struct RoundResult {
    var won: Bool
    var score: Int
    var time: TimeInterval
    var maxCombo: Int
    var biggestChain: Int
    var feverCount: Int
    var rank: String
    var xpGained: Int
    var coinsGained: Int
    var levelFrom: Int
    var levelTo: Int
    var previousBest: Int
    var remainingSafe: Int
    var clearRatio: Double

    var isNewRecord: Bool { score > previousBest }
    var leveledUp: Bool { levelTo > levelFrom }
}

@MainActor
@Observable
final class GameViewModel {
    static let comboWindow: TimeInterval = 2.0
    static let feverDuration: TimeInterval = 8

    let difficulty: Difficulty
    private(set) var stage: Int
    @ObservationIgnored private let progress: PlayerProgress

    private(set) var board: Board
    private(set) var phase: GamePhase = .ready
    var flagMode = false

    private(set) var score = 0
    private(set) var combo = 0
    private(set) var maxCombo = 0
    private(set) var feverGauge: Double = 0
    private(set) var isFever = false
    private(set) var feverCount = 0
    private(set) var biggestChain = 0
    private(set) var startDate: Date?
    private(set) var endDate: Date?
    private(set) var radarLeft = 2
    private(set) var reviveLeft = 1

    private(set) var popups: [Popup] = []
    /// 直前に開いたマス → 連鎖の深さ（光らせる＆アニメ遅延用）
    private(set) var freshDepth: [Int: Int] = [:]
    private(set) var shakeCount = 0
    private(set) var explodedIndex: Int?
    private(set) var revealMines = false
    private(set) var radarPing: Int?
    private(set) var result: RoundResult?

    @ObservationIgnored private var comboToken = 0
    @ObservationIgnored private var freshToken = 0
    @ObservationIgnored private var feverTask: Task<Void, Never>?
    @ObservationIgnored private var committed = false

    init(difficulty: Difficulty, progress: PlayerProgress) {
        self.difficulty = difficulty
        self.progress = progress
        self.stage = progress.stage
        self.board = Board(difficulty: difficulty)
    }

    var minesLeft: Int { board.mineCount - board.flagCount }
    var isActive: Bool { phase == .ready || phase == .playing }

    func elapsed(at date: Date) -> TimeInterval {
        guard let startDate else { return 0 }
        return max(0, (endDate ?? date).timeIntervalSince(startDate))
    }

    private var multiplier: Double {
        (1 + Double(combo) * 0.1) * (isFever ? 2 : 1)
    }

    // MARK: - 入力

    func tap(_ i: Int) {
        guard isActive else { return }
        let cell = board.cells[i]
        if flagMode && !cell.isOpen {
            toggleFlag(i)
            return
        }
        if cell.isFlagged {
            Haptics.impact(.soft)
            return
        }
        if cell.isOpen {
            chord(i)
            return
        }
        if phase == .ready {
            board.placeMines(avoiding: i)
            phase = .playing
            startDate = .now
        }
        reveal([i], origin: i)
    }

    func longPress(_ i: Int) {
        guard isActive else { return }
        if board.cells[i].isOpen {
            chord(i)
        } else {
            toggleFlag(i)
        }
    }

    func toggleFlagMode() {
        flagMode.toggle()
        Haptics.impact(.rigid)
        SoundEngine.shared.play(.button)
    }

    /// まだ旗のない地雷を1つ見つけて自動で旗を立てる
    func useRadar() {
        guard phase == .playing, radarLeft > 0 else { return }
        let candidates = board.cells.indices.filter { board.cells[$0].isMine && !board.cells[$0].isFlagged }
        guard let target = candidates.randomElement() else { return }
        radarLeft -= 1
        board.setFlag(target, true)
        radarPing = target
        addPopup("レーダー!", kind: .info, row: board.row(of: target), col: board.col(of: target))
        SoundEngine.shared.play(.radar)
        Haptics.notify(.success)
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.2))
            guard let self, self.radarPing == target else { return }
            withAnimation(.easeOut) { self.radarPing = nil }
        }
    }

    private func toggleFlag(_ i: Int) {
        guard board.toggleFlag(i) else { return }
        Haptics.impact(.medium)
        SoundEngine.shared.play(.flag)
    }

    private func chord(_ i: Int) {
        let targets = board.chordTargets(i)
        guard !targets.isEmpty else {
            Haptics.impact(.soft)
            return
        }
        reveal(targets, origin: i)
    }

    private func reveal(_ targets: [Int], origin: Int) {
        if let mine = targets.first(where: { board.cells[$0].isMine && !board.cells[$0].isFlagged }) {
            explode(at: mine)
            return
        }
        var opened: [OpenedCell] = []
        for t in targets {
            opened += board.open(t)
        }
        guard !opened.isEmpty else { return }
        registerOpen(opened, origin: origin)
        if board.safeRemaining == 0 {
            win()
        }
    }

    // MARK: - スコア・コンボ・フィーバー

    private func registerOpen(_ opened: [OpenedCell], origin: Int) {
        // コンボ：前回から2秒以内なら継続
        combo += 1
        maxCombo = max(maxCombo, combo)
        comboToken += 1
        let token = comboToken
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(Self.comboWindow))
            guard let self, self.comboToken == token, self.phase == .playing else { return }
            withAnimation(.snappy) { self.combo = 0 }
        }

        // スコア
        let count = opened.count
        biggestChain = max(biggestChain, count)
        var gained = Double(count * 10) * multiplier
        if count >= 10 { gained += Double(count * 20) }
        let points = Int(gained.rounded())
        score += points

        // 開いたマスを一瞬光らせる
        var depths: [Int: Int] = [:]
        for o in opened { depths[o.index] = o.depth }
        freshDepth = depths
        freshToken += 1
        let fToken = freshToken
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(0.9))
            guard let self, self.freshToken == fToken else { return }
            withAnimation(.easeOut(duration: 0.4)) { self.freshDepth = [:] }
        }

        // ポップアップ
        let r = board.row(of: origin), c = board.col(of: origin)
        addPopup("+\(points.formatted())", kind: .score, row: r, col: c)
        if count >= 10 {
            addPopup("CHAIN \(count)マス!", kind: .chain, row: min(r + 1, board.rows - 1), col: c)
        }
        if combo >= 5 && combo.isMultiple(of: 5) {
            addPopup("x\(combo) COMBO!!", kind: .combo, row: max(r - 1, 0), col: c)
        }

        // フィーバーゲージ
        if !isFever {
            feverGauge = min(1, feverGauge + 0.05 + Double(count) * 0.015)
            if feverGauge >= 1 { startFever() }
        }

        // 音・振動・揺れ
        SoundEngine.shared.play(.open(step: combo))
        Haptics.impact(count >= 10 ? .heavy : .light, intensity: min(1, 0.5 + Double(count) / 20))
        if count >= 15 { shakeCount += 1 }
    }

    private func startFever() {
        isFever = true
        feverCount += 1
        feverGauge = 1
        SoundEngine.shared.play(.fever)
        Haptics.notify(.success)
        addPopup("FEVER!!", kind: .fever, row: board.rows / 2, col: board.cols / 2)

        feverTask?.cancel()
        feverTask = Task { [weak self] in
            let steps = 40
            for _ in 0..<steps {
                try? await Task.sleep(for: .seconds(Self.feverDuration / Double(steps)))
                if Task.isCancelled { return }
                guard let self else { return }
                self.feverGauge = max(0, self.feverGauge - 1 / Double(steps))
            }
            guard let self, !Task.isCancelled else { return }
            withAnimation(.easeInOut) {
                self.isFever = false
                self.feverGauge = 0
            }
        }
    }

    private func stopFever() {
        feverTask?.cancel()
        feverTask = nil
        isFever = false
    }

    private func addPopup(_ text: String, kind: Popup.Kind, row: Int, col: Int) {
        let popup = Popup(text: text, kind: kind, row: row, col: col)
        popups.append(popup)
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.1))
            self?.popups.removeAll { $0.id == popup.id }
        }
    }

    // MARK: - 勝ち負け

    private func explode(at i: Int) {
        _ = board.open(i)
        explodedIndex = i
        phase = .lost
        endDate = .now
        stopFever()
        shakeCount += 1
        SoundEngine.shared.play(.explosion)
        Haptics.notify(.error)
        Haptics.impact(.heavy)
        withAnimation(.easeOut(duration: 0.3).delay(0.25)) { revealMines = true }
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.1))
            guard let self, self.phase == .lost else { return }
            self.finishRound(won: false)
        }
    }

    private func win() {
        phase = .won
        endDate = .now
        stopFever()
        for i in board.cells.indices where board.cells[i].isMine {
            board.setFlag(i, true)
        }
        let t = elapsed(at: .now)
        let timeBonus = max(0, Int((difficulty.parSeconds * 2 - t) * 50))
        if timeBonus > 0 {
            score += timeBonus
            addPopup("TIME BONUS +\(timeBonus.formatted())", kind: .chain, row: board.rows / 2, col: board.cols / 2)
        }
        SoundEngine.shared.play(.fanfare)
        Haptics.notify(.success)
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(0.9))
            self?.finishRound(won: true)
        }
    }

    private func finishRound(won: Bool) {
        let t = elapsed(at: .now)
        let total = board.safeTotal
        let remaining = board.safeRemaining
        var r = RoundResult(
            won: won,
            score: score,
            time: t,
            maxCombo: maxCombo,
            biggestChain: biggestChain,
            feverCount: feverCount,
            rank: won ? Self.rank(time: t, par: difficulty.parSeconds, maxCombo: maxCombo) : "-",
            xpGained: won ? 200 + score / 50 : 20 + score / 200,
            coinsGained: won ? 50 + score / 100 : score / 400,
            levelFrom: progress.level,
            levelTo: progress.level,
            previousBest: progress.bestScore,
            remainingSafe: remaining,
            clearRatio: total > 0 ? Double(total - remaining) / Double(total) : 0
        )
        // 負けた時は「復活」できるので、確定は次の操作まで保留する
        if won { r = commit(r) }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) { result = r }
    }

    private func commit(_ r: RoundResult) -> RoundResult {
        guard !committed else { return r }
        committed = true
        var r = r
        r.levelFrom = progress.level
        progress.coins += r.coinsGained
        progress.recordScore(r.score)
        if r.won { progress.stage += 1 }
        progress.addXP(r.xpGained)
        r.levelTo = progress.level
        return r
    }

    /// 保留中の結果（ゲームオーバー）を確定する
    func commitPendingResult() {
        guard let r = result, !committed else { return }
        result = commit(r)
    }

    static func rank(time: TimeInterval, par: Double, maxCombo: Int) -> String {
        let ratio = time / par
        if ratio < 0.7 || (ratio < 1.0 && maxCombo >= 15) { return "S" }
        if ratio < 1.1 { return "A" }
        if ratio < 1.8 { return "B" }
        return "C"
    }

    // MARK: - 復活・リスタート

    func revive() {
        guard phase == .lost, reviveLeft > 0, let i = explodedIndex else { return }
        reviveLeft -= 1
        board.close(i)
        board.setFlag(i, true)
        explodedIndex = nil
        revealMines = false
        result = nil
        combo = 0
        endDate = nil
        phase = .playing
        SoundEngine.shared.play(.revive)
        Haptics.notify(.success)
    }

    func restart() {
        commitPendingResult()
        stopFever()
        comboToken += 1
        freshToken += 1
        stage = progress.stage
        board = Board(difficulty: difficulty)
        phase = .ready
        flagMode = false
        score = 0
        combo = 0
        maxCombo = 0
        feverGauge = 0
        feverCount = 0
        biggestChain = 0
        startDate = nil
        endDate = nil
        radarLeft = 2
        reviveLeft = 1
        popups = []
        freshDepth = [:]
        explodedIndex = nil
        revealMines = false
        radarPing = nil
        result = nil
        committed = false
        progress.markPlayedToday()
    }
}
