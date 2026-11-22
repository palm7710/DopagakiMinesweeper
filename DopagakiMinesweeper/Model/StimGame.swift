import SwiftUI
import Observation

// MARK: - 画面に出るもの

struct StimNotification: Identifiable {
    let id = UUID()
    let icon: String
    let color: Color
    let app: String
    let message: String
    let reward: Double
}

struct GachaResult: Identifiable {
    enum Rarity: String {
        case n = "N", r = "R", sr = "SR", ssr = "SSR"

        var color: Color {
            switch self {
            case .n: return Palette.lavender
            case .r: return Palette.cyan
            case .sr: return Palette.pink
            case .ssr: return Palette.yellow
            }
        }
    }

    let id = UUID()
    let rarity: Rarity
    let reward: Double
}

/// 画面を右から左へ流れるコメント
struct Danmaku: Identifiable {
    let id = UUID()
    let text: String
    let lane: Int
    let color: Color
    let size: CGFloat
    let born: Date
    let speed: Double
}

struct SuperChat: Identifiable {
    let id = UUID()
    let name: String
    let message: String
    let yen: Int
    let color: Color
    let reward: Double
}

struct ScreenCrack: Identifiable {
    let id = UUID()
    let x: Double
    let y: Double
    let seed: UInt64
    let scale: Double
}

struct SlotSpin: Identifiable {
    let id = UUID()
    let symbols: [String]
    let win: Bool
    let started = Date()

    static let reelSymbols = ["🍒", "💎", "7️⃣", "🧠", "🔔"]
}

struct AdSession: Identifiable {
    enum Purpose { case revive, doubleOffline }

    let id = UUID()
    let purpose: Purpose
    var started: Date?

    var isPlaying: Bool { started != nil }
    static let length: TimeInterval = 5
}

struct LoginBonus {
    let streak: Int
    let dayIndex: Int
    let rewards: [Double]
}

struct OfflineReward {
    let seconds: Double
    let amount: Double
}

struct AchievementToast: Identifiable {
    let id = UUID()
    let achievement: StimAchievement
    let reward: Double
}

// MARK: - 刺激モード本体

/// 刺激モード：マスを開けて「刺激」を稼ぎ、ショップで買うほど画面がにぎやかになる
@MainActor
@Observable
final class StimGame: BoardDriving {
    static let difficulty = Difficulty.easy
    static let comboWindow: TimeInterval = 2.0
    /// 脳汁2倍フェス：10分ごとに2分間
    static let festCycle: Double = 600
    static let festLength: Double = 120

    private(set) var board = Board(difficulty: .easy)
    private(set) var phase: GamePhase = .ready
    var flagMode = false

    // 保存するもの
    private(set) var stim: Double
    private(set) var totalEarned: Double
    private(set) var lifetimeEarned: Double
    private(set) var levels: [StimItem: Int]
    private(set) var cellsOpened: Int
    private(set) var clears: Int
    private(set) var gachaRolls: Int
    private(set) var prestigePoints: Int
    private(set) var prestigeCount: Int
    private(set) var achievements: Set<StimAchievement>
    private(set) var counters: [StimCounter: Int]
    private(set) var loginStreak: Int
    private(set) var petHunger: Double
    private(set) var fish: [OwnedFish]
    private(set) var dex: Set<FishSpecies>

    // 盤面まわり
    private(set) var combo = 0
    private(set) var clearStreak = 0
    private(set) var popups: [Popup] = []
    private(set) var freshDepth: [Int: Int] = [:]
    private(set) var shakeCount = 0
    private(set) var explodedIndex: Int?
    private(set) var revealMines = false
    let radarPing: Int? = nil
    private(set) var luckyCells: Set<Int> = []
    private(set) var slotCells: Set<Int> = []
    private(set) var lastCell = false
    private(set) var celebrateCount = 0

    // 演出
    private(set) var notifications: [StimNotification] = []
    private(set) var stockPrice: Double = 100
    private(set) var stockHistory: [Double] = Array(repeating: 100, count: 60)
    private(set) var gachaResult: GachaResult?
    private(set) var danmaku: [Danmaku] = []
    private(set) var superChats: [SuperChat] = []
    private(set) var cracks: [ScreenCrack] = []
    private(set) var slotSpin: SlotSpin?
    private(set) var birdVisible = false
    private(set) var birdLine = ""
    private(set) var birdAnger = 0
    private(set) var petFedCount = 0
    private(set) var festActive = false
    private(set) var festSeconds = 0

    // 全画面のお知らせ
    private(set) var adSession: AdSession?
    private(set) var loginBonus: LoginBonus?
    private(set) var offlineReward: OfflineReward?
    private(set) var achievementToast: AchievementToast?
    private(set) var showEnding: Bool

    @ObservationIgnored private var tickTask: Task<Void, Never>?
    @ObservationIgnored private var comboToken = 0
    @ObservationIgnored private var freshToken = 0
    @ObservationIgnored private var boardID = 0
    @ObservationIgnored private var notifClock: Double = 3
    @ObservationIgnored private var stockClock: Double = 0
    @ObservationIgnored private var saveClock: Double = 0
    @ObservationIgnored private var danmakuClock: Double = 1
    @ObservationIgnored private var superChatClock: Double = 6
    @ObservationIgnored private var birdClock: Double = 25
    @ObservationIgnored private var birdNagClock: Double = 6
    @ObservationIgnored private var cryClock: Double = 0
    @ObservationIgnored private var heartbeatClock: Double = 0
    @ObservationIgnored private var lastVoice = Date.distantPast
    @ObservationIgnored private var toastQueue: [AchievementToast] = []
    @ObservationIgnored private var welcomeChecked = false
    @ObservationIgnored private var lastSeen: Date?
    @ObservationIgnored private var lastLoginDay: String
    @ObservationIgnored private var botRefund: Double = 0
    @ObservationIgnored private var fishClock: Double = 0

    init() {
        let s = StimSave.load()
        stim = s.stim
        totalEarned = s.totalEarned
        lifetimeEarned = s.lifetimeEarned
        cellsOpened = s.cellsOpened
        clears = s.clears
        gachaRolls = s.gachaRolls
        prestigePoints = s.prestigePoints
        prestigeCount = s.prestigeCount
        loginStreak = s.loginStreak
        lastLoginDay = s.lastLoginDay
        lastSeen = s.lastSeen
        petHunger = s.petHunger
        fish = s.fish
        dex = Set(s.dex.compactMap { FishSpecies(rawValue: $0) })

        var loaded: [StimItem: Int] = [:]
        for (key, value) in s.levels {
            if let item = StimItem(rawValue: key) { loaded[item] = value }
        }
        levels = loaded
        achievements = Set(s.achievements.compactMap { StimAchievement(rawValue: $0) })
        var loadedCounters: [StimCounter: Int] = [:]
        for (key, value) in s.counters {
            if let counter = StimCounter(rawValue: key) { loadedCounters[counter] = value }
        }
        counters = loadedCounters
        showEnding = s.endingSeen && (loaded[.detox] ?? 0) > 0

        // 以前あった「自動ほりほりBot」は廃止したので、使った刺激を返す
        if let botLevel = s.levels["autoBot"], botLevel > 0 {
            var refund = 0.0
            for k in 0..<botLevel { refund += (200 * pow(1.9, Double(k))).rounded() }
            botRefund = refund
        }
    }

    // MARK: - 数値

    func level(_ item: StimItem) -> Int { levels[item] ?? 0 }
    func owns(_ item: StimItem) -> Bool { level(item) > 0 }
    func count(_ counter: StimCounter) -> Int { counters[counter] ?? 0 }

    /// 1マスあたりの刺激
    var cellValue: Double { Double(1 + level(.tapPower)) }
    var comboMultiplier: Double { min(3, 1 + Double(combo) * 0.1) }
    /// 連続クリアの倍率（地雷を踏むとリセット）
    var streakMultiplier: Double { min(3, 1 + Double(clearStreak) * 0.25) }
    /// 転生でずっと残る倍率
    var prestigeMultiplier: Double { 1 + 0.1 * Double(prestigePoints) }

    var petMultiplier: Double {
        guard owns(.pet) else { return 1 }
        if petHunger <= 0 { return 0.7 }
        if petHunger > 0.6 { return 1 + 0.15 * Double(min(level(.pet), 10)) }
        return 1
    }

    /// 稼ぐ量すべてにかかる倍率
    var earnMultiplier: Double {
        prestigeMultiplier * (festActive ? 2 : 1) * petMultiplier
    }

    /// 商品から入る毎秒の刺激（フェスや転生の倍率をかける前）
    var basePerSecond: Double {
        var total = 0.0
        for item in StimItem.allCases where item != .stocks {
            total += item.perSecond * Double(level(item))
        }
        if owns(.stocks) {
            total += StimItem.stocks.perSecond * Double(level(.stocks)) * stockPrice / 100
        }
        total += fishPerSecond
        return total * streakMultiplier
    }

    /// 画面に出す毎秒の刺激
    var perSecond: Double { basePerSecond * earnMultiplier }

    var gachaCost: Double { (500 * pow(1.12, Double(gachaRolls))).rounded() }
    var petFoodCost: Double { (30 + basePerSecond * 8).rounded() }
    var isActive: Bool { phase == .ready || phase == .playing }
    var minesLeft: Int { board.mineCount - board.flagCount }

    /// 今転生すると増える転生ポイント
    var prestigeGain: Int {
        let gain = Int((totalEarned / 20_000).squareRoot())
        return showEnding ? max(1, gain) : gain
    }

    /// 全画面のお知らせが出ていて盤面をさわれないとき
    var isBlocked: Bool {
        showEnding || adSession != nil || loginBonus != nil || offlineReward != nil
    }

    // MARK: - ループ

    func start() {
        applyAmbience()
        if !welcomeChecked {
            welcomeChecked = true
            checkWelcome()
        }
        guard tickTask == nil else { return }
        tickTask = Task { [weak self] in
            var last = Date()
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                let now = Date()
                let dt = min(1, now.timeIntervalSince(last))
                last = now
                guard let self else { return }
                self.tick(dt, now: now)
            }
        }
    }

    func stop() {
        tickTask?.cancel()
        tickTask = nil
        SoundEngine.shared.stopAllLoops()
        save()
    }

    private func tick(_ dt: Double, now: Date) {
        guard !showEnding else { return }
        updateFest(now)
        earn(basePerSecond * dt)

        if owns(.notifications) {
            notifClock -= dt
            if notifClock <= 0 {
                notifClock = max(1.5, Double.random(in: 4...9) / (1 + 0.3 * Double(level(.notifications) - 1)))
                pushNotification()
            }
        }
        if owns(.stocks) {
            stockClock += dt
            if stockClock >= 0.5 {
                stockClock = 0
                stepStock()
            }
        }
        if let oldest = danmaku.first, now.timeIntervalSince(oldest.born) > 8 {
            danmaku.removeAll { now.timeIntervalSince($0.born) > 8 }
        }
        if owns(.danmaku) {
            danmakuClock -= dt
            if danmakuClock <= 0 {
                danmakuClock = Double.random(in: 0.8...1.8) / Double(min(level(.danmaku), 6))
                spawnDanmaku(1)
            }
        }
        if owns(.superChat) {
            superChatClock -= dt
            if superChatClock <= 0 {
                superChatClock = max(2.5, Double.random(in: 8...15) / (1 + 0.3 * Double(level(.superChat) - 1)))
                pushSuperChat()
            }
        }
        if owns(.pet) { tickPet(dt) }
        fishClock += dt
        if fishClock >= 1 {
            tickFish(fishClock)
            fishClock = 0
        }
        if owns(.studyBird) { tickBird(dt) }
        if lastCell {
            heartbeatClock -= dt
            if heartbeatClock <= 0 {
                heartbeatClock = 0.75
                Haptics.impact(.soft)
            }
        }

        saveClock += dt
        if saveClock >= 5 { save() }
    }

    /// 刺激を足す。boosted なら転生・フェス・ペットの倍率がかかる。実際に増えた量を返す
    @discardableResult
    private func earn(_ amount: Double, boosted: Bool = true) -> Double {
        guard amount > 0 else { return 0 }
        let value = boosted ? amount * earnMultiplier : amount
        stim += value
        totalEarned += value
        lifetimeEarned += value
        if lifetimeEarned >= 1_000_000 { unlock(.million) }
        return value
    }

    private func bump(_ counter: StimCounter) -> Int {
        let value = count(counter) + 1
        counters[counter] = value
        return value
    }

    // MARK: - ショップ

    func price(_ item: StimItem) -> Double { item.price(at: level(item)) }
    func isMaxed(_ item: StimItem) -> Bool { level(item) >= item.maxLevel }
    func canBuy(_ item: StimItem) -> Bool { !isMaxed(item) && stim >= price(item) }

    /// まとめ買い：quantity 個（nil なら買えるだけ）買うときの個数と合計金額
    func bulkQuote(_ item: StimItem, quantity: Int?) -> (count: Int, cost: Double) {
        let remaining = item.maxLevel - level(item)
        guard remaining > 0 else { return (0, 0) }
        let current = level(item)
        if let quantity {
            let n = min(quantity, remaining)
            var cost = 0.0
            for k in 0..<n { cost += item.price(at: current + k) }
            return (n, cost)
        }
        // 買えるだけ（最低1個ぶんの値段は見せる）
        var n = 0
        var cost = 0.0
        while n < min(remaining, 1_000) {
            let next = item.price(at: current + n)
            if cost + next > stim { break }
            cost += next
            n += 1
        }
        if n == 0 { return (1, item.price(at: current)) }
        return (n, cost)
    }

    func canBuy(_ item: StimItem, quantity: Int?) -> Bool {
        let quote = bulkQuote(item, quantity: quantity)
        return quote.count > 0 && stim >= quote.cost
    }

    /// ある程度稼ぐまで商品名は「？？？」
    func isRevealed(_ item: StimItem) -> Bool {
        item == .tapPower || item == .dvd || owns(item) || totalEarned >= item.basePrice * 0.4
    }

    func buy(_ item: StimItem, quantity: Int? = 1) {
        let quote = bulkQuote(item, quantity: quantity)
        guard quote.count > 0, stim >= quote.cost, !showEnding else {
            Haptics.notify(.warning)
            return
        }
        stim -= quote.cost
        let wasOwned = owns(item)
        levels[item, default: 0] += quote.count
        SoundEngine.shared.play(.buy)
        Haptics.notify(.success)
        if item == .detox {
            unlock(.ending)
            triggerEnding()
        } else {
            applyAmbience()
            let label = quote.count > 1 ? "\(item.name) ×\(quote.count)" : item.name
            addPopup("\(label) GET!", kind: .info, row: board.rows / 2, col: board.cols / 2)
            if item == .pet { petHunger = 1 }
            if item == .lucky || item == .slot, phase == .playing, !wasOwned {
                assignSpecialCells()
            }
        }
        let others = StimItem.allCases.filter { $0 != .tapPower && $0 != .detox }
        if others.allSatisfy({ owns($0) }) { unlock(.allItems) }
        save()
    }

    private func applyAmbience() {
        let on = !showEnding
        SoundEngine.shared.setLoop(.lofi, on: on && level(.lofi) == 1)
        SoundEngine.shared.setLoop(.lofiPlus, on: on && level(.lofi) >= 2)
        SoundEngine.shared.setLoop(.rain, on: on && owns(.rain))
        SoundEngine.shared.setLoop(.heartbeat, on: on && lastCell)
    }

    // MARK: - 入力

    func tap(_ i: Int) {
        guard isActive, !isBlocked else { return }
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
        let first = phase == .ready
        if first {
            board.placeMines(avoiding: i)
            phase = .playing
        }
        reveal([i], origin: i, auto: false)
        if first && phase == .playing { assignSpecialCells() }
    }

    func longPress(_ i: Int) {
        guard isActive, !isBlocked else { return }
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
        reveal(targets, origin: i, auto: false)
    }

    private func reveal(_ targets: [Int], origin: Int, auto: Bool) {
        if let mine = targets.first(where: { board.cells[$0].isMine && !board.cells[$0].isFlagged }) {
            explode(at: mine)
            return
        }
        var opened: [OpenedCell] = []
        for t in targets {
            opened += board.open(t)
        }
        guard !opened.isEmpty else { return }
        registerOpen(opened, origin: origin, auto: auto)
        if board.safeRemaining == 0 {
            win()
        }
    }

    /// 最初の一手のあと、まだ開いていない安全なマスにラッキーマスと777マスを置く
    private func assignSpecialCells() {
        var candidates = board.cells.indices.filter {
            let c = board.cells[$0]
            return !c.isOpen && !c.isMine
        }.shuffled()
        if owns(.lucky) {
            var amount = min(level(.lucky), 4)
            if Double.random(in: 0..<1) < 0.3 { amount += 1 }
            for _ in 0..<amount {
                if let cell = candidates.popLast() { luckyCells.insert(cell) }
            }
        }
        if owns(.slot) {
            for _ in 0..<min(level(.slot), 3) {
                if let cell = candidates.popLast() { slotCells.insert(cell) }
            }
        }
    }

    /// 安全なマスを1つ開ける。開いているマスのとなりを優先する（スロットの当たりで使う）
    private func openOneSafeCell() {
        guard phase == .playing else { return }
        let candidates = board.cells.indices.filter {
            let c = board.cells[$0]
            return !c.isOpen && !c.isMine && !c.isFlagged
        }
        let frontier = candidates.filter { i in
            board.neighbors(of: i).contains { board.cells[$0].isOpen }
        }
        guard let target = (frontier.isEmpty ? candidates : frontier).randomElement() else { return }
        reveal([target], origin: target, auto: true)
    }

    private func registerOpen(_ opened: [OpenedCell], origin: Int, auto: Bool) {
        let count = opened.count
        cellsOpened += count
        growFish(by: Double(count))

        if !auto {
            combo += 1
            comboToken += 1
            let token = comboToken
            Task { [weak self] in
                try? await Task.sleep(for: .seconds(Self.comboWindow))
                guard let self, self.comboToken == token else { return }
                withAnimation(.snappy) { self.combo = 0 }
            }
            if combo >= 20 { unlock(.combo20) }
        }

        var gained = Double(count) * cellValue * comboMultiplier * streakMultiplier
        if count >= 10 { gained *= 2 }

        let r = board.row(of: origin), c = board.col(of: origin)
        let openedSet = Set(opened.map(\.index))

        // ラッキーマス
        let luckyHit = luckyCells.intersection(openedSet)
        if !luckyHit.isEmpty {
            luckyCells.subtract(luckyHit)
            gained *= 10
            addPopup("LUCKY ×10!!", kind: .fever, row: max(r - 1, 0), col: c)
            SoundEngine.shared.play(.ssr)
            Haptics.notify(.success)
            spawnDanmaku(5, from: ["金！！", "ラッキー！", "うらやま", "金色きた", "888888"])
            unlock(.lucky)
            if bump(.lucky) >= 10 { unlock(.lucky10) }
            if Double.random(in: 0..<1) < 0.3 { dropEgg(reason: "ラッキー") }
            shout(["きんいろー！", "ラッキー！"], force: true)
        }

        let earned = earn(gained)

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

        addPopup("+\(earned.stimText)", kind: auto ? .info : .score, row: r, col: c)
        if count >= 10 {
            addPopup("CHAIN \(count)マス!", kind: .chain, row: min(r + 1, board.rows - 1), col: c)
            shout()
        }
        if count >= 25 { unlock(.chain25) }
        if combo >= 5 && combo.isMultiple(of: 5) {
            addPopup("x\(combo) COMBO!!", kind: .combo, row: max(r - 1, 0), col: c)
            shout()
        }
        spawnDanmaku(min(8, 1 + count / 4))
        if count >= 12 { addCrack() }

        // 777マス
        let slotHit = slotCells.intersection(openedSet)
        if !slotHit.isEmpty {
            slotCells.subtract(slotHit)
            startSlot()
        }

        if auto {
            SoundEngine.shared.play(.bounce)
        } else {
            SoundEngine.shared.play(.open(step: combo))
            Haptics.impact(count >= 10 ? .heavy : .light, intensity: min(1, 0.5 + Double(count) / 20))
        }
        if count >= 15 { shakeCount += 1 }

        // ラスト1マス
        if board.safeRemaining == 1 && !lastCell {
            withAnimation(.easeInOut(duration: 0.6)) { lastCell = true }
            heartbeatClock = 0
            applyAmbience()
            addPopup("ラスト1マス!", kind: .combo, row: board.rows / 2, col: board.cols / 2)
            spawnDanmaku(4, from: ["ごくり", "こわ", "いけ！", "たのむ", "手汗やばい"])
        }
    }

    // MARK: - 勝ち負け（盤面はすぐ次が出てくる）

    private func explode(at i: Int) {
        _ = board.open(i)
        explodedIndex = i
        phase = .lost
        combo = 0
        shakeCount += 1
        endLastCell()
        addPopup("ドカーン!", kind: .fever, row: board.row(of: i), col: board.col(of: i))
        SoundEngine.shared.play(.explosion)
        Haptics.notify(.error)
        Haptics.impact(.heavy)
        withAnimation(.easeOut(duration: 0.3).delay(0.25)) { revealMines = true }
        spawnDanmaku(6, from: ["あ", "あーあ", "草", "乙", "ドンマイ", "wwwww", "やっちゃった"])
        addCrack()
        addCrack()

        // 連続クリア中か、半分近く開けていたら「広告を見て復活」をすすめる
        let openedSafe = board.safeTotal - board.safeRemaining
        let progressed = Double(openedSafe) / Double(max(1, board.safeTotal)) >= 0.4
        if clearStreak > 0 || progressed {
            let id = boardID
            Task { [weak self] in
                try? await Task.sleep(for: .seconds(0.9))
                guard let self, self.boardID == id, self.phase == .lost else { return }
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    self.adSession = AdSession(purpose: .revive)
                }
            }
        } else {
            finalizeLoss(after: 1.4)
        }
    }

    private func finalizeLoss(after delay: Double) {
        clearStreak = 0
        let id = boardID
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard let self, self.boardID == id, self.phase == .lost else { return }
            withAnimation(.snappy) { self.newBoard() }
        }
    }

    private func revive() {
        guard phase == .lost, let i = explodedIndex else { return }
        board.close(i)
        board.setFlag(i, true)
        explodedIndex = nil
        revealMines = false
        phase = .playing
        addPopup("復活!!", kind: .fever, row: board.row(of: i), col: board.col(of: i))
        SoundEngine.shared.play(.revive)
        Haptics.notify(.success)
        spawnDanmaku(4, from: ["復活！", "広告えらい", "おかえり", "まだいける"])
        if board.safeRemaining == 1 {
            withAnimation(.easeInOut(duration: 0.6)) { lastCell = true }
            applyAmbience()
        }
    }

    private func win() {
        phase = .won
        clears += 1
        clearStreak += 1
        for i in board.cells.indices where board.cells[i].isMine {
            board.setFlag(i, true)
        }
        if lastCell { unlock(.lastCell) }
        endLastCell()
        celebrateCount += 1

        let bonus = earn(Double(board.safeTotal) * cellValue * streakMultiplier)
        addPopup("CLEAR! +\(bonus.stimText)", kind: .fever, row: board.rows / 2, col: board.cols / 2)
        SoundEngine.shared.play(.fanfare)
        Haptics.notify(.success)
        shout(force: true)
        spawnDanmaku(8, from: ["GG", "うますぎ", "神", "888888", "クリアおめ", "天才か？"])

        if !cracks.isEmpty {
            withAnimation(.easeOut(duration: 0.5)) { cracks = [] }
            addPopup("画面修理完了", kind: .info, row: board.rows - 2, col: board.cols / 2)
        }

        if Double.random(in: 0..<1) < 0.15 { dropEgg(reason: "クリア") }
        unlock(.firstClear)
        if clears >= 10 { unlock(.clears10) }
        if clears >= 50 { unlock(.clears50) }
        save()

        let id = boardID
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.3))
            guard let self, self.boardID == id, self.phase == .won else { return }
            withAnimation(.snappy) { self.newBoard() }
        }
    }

    private func newBoard() {
        boardID += 1
        board = Board(difficulty: Self.difficulty)
        phase = .ready
        explodedIndex = nil
        revealMines = false
        luckyCells = []
        slotCells = []
        freshToken += 1
        freshDepth = [:]
        endLastCell()
    }

    private func endLastCell() {
        guard lastCell else { return }
        withAnimation(.easeOut(duration: 0.3)) { lastCell = false }
        applyAmbience()
    }

    // MARK: - 広告

    func watchAd() {
        guard var session = adSession, !session.isPlaying else { return }
        session.started = Date()
        adSession = session
        SoundEngine.shared.play(.button)
    }

    func finishAd() {
        guard let session = adSession, let started = session.started,
              Date().timeIntervalSince(started) >= AdSession.length - 0.1 else { return }
        withAnimation(.easeOut(duration: 0.25)) { adSession = nil }
        _ = bump(.ads)
        unlock(.adWatched)
        switch session.purpose {
        case .revive:
            revive()
        case .doubleOffline:
            if let reward = offlineReward {
                let earned = earn(reward.amount * 2, boosted: false)
                addPopup("おかえり×2 +\(earned.stimText)", kind: .fever,
                         row: board.rows / 2, col: board.cols / 2)
                SoundEngine.shared.play(.cash)
                withAnimation(.easeOut) { offlineReward = nil }
            }
        }
    }

    func declineAd() {
        guard let session = adSession, !session.isPlaying else { return }
        withAnimation(.easeOut(duration: 0.25)) { adSession = nil }
        if session.purpose == .revive {
            finalizeLoss(after: 0.2)
        }
    }

    // MARK: - ログインボーナスと放置収益

    private static let loginMultipliers: [Double] = [1, 1, 2, 2, 3, 3, 10]

    private func checkWelcome() {
        let now = Date()
        if botRefund > 0 {
            earn(botRefund, boosted: false)
            addPopup("Bot廃止のため返金 +\(botRefund.stimText)", kind: .info, row: board.rows / 2, col: board.cols / 2)
            botRefund = 0
        }

        if let last = lastSeen {
            let seconds = now.timeIntervalSince(last)
            if seconds > 60 {
                if owns(.pet) { petHunger = max(0, petHunger - seconds / 150) }
                applyOfflineFish(seconds: min(seconds, 8 * 3600))
                let capped = min(seconds, 8 * 3600)
                let amount = (basePerSecond * prestigeMultiplier * capped * 0.5).rounded()
                if amount >= 1 {
                    offlineReward = OfflineReward(seconds: seconds, amount: amount)
                }
            }
        }

        let today = Self.dayString(now)
        if lastLoginDay != today {
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now).map(Self.dayString)
            loginStreak = (lastLoginDay == yesterday) ? loginStreak + 1 : 1
            lastLoginDay = today
            let base = max(200, basePerSecond * 120 + cellValue * 50)
            loginBonus = LoginBonus(streak: loginStreak,
                                    dayIndex: (loginStreak - 1) % 7,
                                    rewards: Self.loginMultipliers.map { (base * $0).rounded() })
        }
        save()
    }

    func claimLoginBonus() {
        guard let bonus = loginBonus else { return }
        let reward = bonus.rewards[bonus.dayIndex]
        earn(reward, boosted: false)
        withAnimation(.easeOut(duration: 0.3)) { loginBonus = nil }
        SoundEngine.shared.play(.fanfare)
        Haptics.notify(.success)
        addPopup("ログボ +\(reward.stimText)", kind: .fever, row: board.rows / 2, col: board.cols / 2)
        if bonus.streak >= 7 { unlock(.login7) }
        save()
    }

    func claimOffline(double: Bool) {
        guard let reward = offlineReward, adSession == nil else { return }
        if double {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                adSession = AdSession(purpose: .doubleOffline, started: Date())
            }
        } else {
            earn(reward.amount, boosted: false)
            SoundEngine.shared.play(.cash)
            withAnimation(.easeOut(duration: 0.3)) { offlineReward = nil }
            save()
        }
    }

    private static func dayString(_ date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    // MARK: - フェス

    private func updateFest(_ now: Date) {
        let pos = now.timeIntervalSince1970.truncatingRemainder(dividingBy: Self.festCycle)
        let active = pos < Self.festLength
        let seconds = Int((active ? Self.festLength - pos : Self.festCycle - pos).rounded(.up))
        if active != festActive {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { festActive = active }
            if active {
                addPopup("脳汁2倍フェス開幕!!", kind: .fever, row: board.rows / 2, col: board.cols / 2)
                SoundEngine.shared.play(.fever)
                Haptics.notify(.success)
                spawnDanmaku(6, from: ["フェスきた", "2倍！！", "稼ぎどき", "うおおお"])
            } else {
                addPopup("フェス終了…", kind: .info, row: board.rows / 2, col: board.cols / 2)
            }
        }
        if active { unlock(.festa) }
        if seconds != festSeconds { festSeconds = seconds }
    }

    // MARK: - DVDロゴ

    func dvdBounce(corner: Bool) {
        guard !showEnding else { return }
        if corner {
            let reward = earn(cellValue * 200 + basePerSecond * 30)
            addPopup("CORNER!! +\(reward.stimText)", kind: .fever, row: board.rows / 2, col: board.cols / 2)
            shakeCount += 1
            SoundEngine.shared.play(.ssr)
            Haptics.notify(.success)
            shout(["角ぃぃぃ！", "かどーーー！", "奇跡！"], force: true)
            spawnDanmaku(8, from: ["角！！！", "かどおおお", "見た？", "伝説", "スクショした"])
            _ = bump(.corners)
            unlock(.corner)
        } else {
            earn(cellValue * 3)
            SoundEngine.shared.play(.bounce)
        }
    }

    // MARK: - 通知

    private static let notificationPool: [(icon: String, color: Color, app: String, message: String)] = [
        ("heart.fill", Palette.pink, "ミンスタ", "あなたの旗に「いいね」が3件つきました"),
        ("message.fill", Palette.lime, "メッセージ", "母：ごはんできたよ"),
        ("flame.fill", Palette.orange, "ドパガキ", "連続ログインが途切れそうです！！"),
        ("newspaper.fill", Palette.cyan, "速報", "地雷、ついに意思を持つ"),
        ("battery.25", Palette.yellow, "システム", "バッテリー残り1%（うそ）"),
        ("person.2.fill", Palette.lavender, "フォロワー", "知らない人があなたをフォローしました"),
        ("cart.fill", Palette.orange, "ショッピング", "カートに入れた地雷が値下がりしました"),
        ("gift.fill", Palette.pink, "キャンペーン", "おめでとうございます！当選…したかも"),
        ("figure.walk", Palette.lime, "ヘルスケア", "今日の歩数：12歩"),
        ("calendar", Palette.cyan, "カレンダー", "5分後：とくに予定はありません"),
        ("envelope.fill", Palette.yellow, "メール", "【重要】重要ではないお知らせ"),
        ("bubble.left.and.bubble.right.fill", Palette.lavender, "グループ", "未読 99+")
    ]

    private func pushNotification() {
        guard let pick = Self.notificationPool.randomElement() else { return }
        let note = StimNotification(icon: pick.icon, color: pick.color, app: pick.app,
                                    message: pick.message,
                                    reward: (basePerSecond * 4 + cellValue * 8).rounded())
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            notifications.insert(note, at: 0)
            if notifications.count > 3 { notifications.removeLast() }
        }
        SoundEngine.shared.play(.notify)
        Haptics.impact(.light)
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(6))
            guard let self else { return }
            withAnimation(.easeIn(duration: 0.25)) {
                self.notifications.removeAll { $0.id == note.id }
            }
        }
    }

    func collect(_ note: StimNotification) {
        guard notifications.contains(where: { $0.id == note.id }) else { return }
        let earned = earn(note.reward)
        withAnimation(.easeIn(duration: 0.2)) {
            notifications.removeAll { $0.id == note.id }
        }
        addPopup("+\(earned.stimText)", kind: .score, row: 0, col: board.cols / 2)
        SoundEngine.shared.play(.cash)
        Haptics.impact(.medium)
    }

    // MARK: - 弾幕コメント

    private static let danmakuPool = [
        "うますぎ", "草", "今の神", "888888", "天才か？", "wwwwww", "ナイス！", "脳汁でた", "えぐい",
        "見てる", "初見です", "もう1回！", "うおおお", "やばい", "地雷こわ", "神回", "鳥肌", "おつ",
        "それな", "指はやすぎ", "かわいい", "なにこれ", "同時視聴勢", "寝れない"
    ]
    private static let danmakuColors: [Color] = [.white, .white, .white, Palette.yellow, Palette.cyan, Palette.pink, Palette.lime]

    private func spawnDanmaku(_ amount: Int, from pool: [String]? = nil) {
        guard owns(.danmaku), amount > 0 else { return }
        let source = pool ?? Self.danmakuPool
        let now = Date()
        for _ in 0..<(amount * min(level(.danmaku), 3)) {
            guard danmaku.count < 40, let text = source.randomElement() else { break }
            danmaku.append(Danmaku(text: text,
                                   lane: Int.random(in: 0..<10),
                                   color: Self.danmakuColors.randomElement() ?? .white,
                                   size: .random(in: 15...24),
                                   born: now.addingTimeInterval(.random(in: 0...0.6)),
                                   speed: .random(in: 110...190)))
        }
    }

    // MARK: - 投げ銭

    private static let superChatTiers: [(yen: Int, color: Color, multiplier: Double, weight: Double)] = [
        (100, Palette.cyan, 1, 40),
        (500, Palette.lime, 2, 28),
        (1_000, Palette.yellow, 4, 18),
        (5_000, Palette.orange, 10, 10),
        (10_000, Palette.pink, 25, 4)
    ]
    private static let superChatNames = ["通りすがりの旗職人", "地雷ソムリエ", "脳汁課金勢", "ママ", "未来の自分", "名無しのドパガキ", "鳥（偽物）"]
    private static let superChatMessages = ["今の連鎖に", "スパチャ失礼します", "これで旗買って", "角当てたら追加します", "そろそろ寝ろ", "応援してます", "宿題やった？"]

    private func pushSuperChat() {
        let total = Self.superChatTiers.reduce(0.0) { $0 + $1.weight }
        var roll = Double.random(in: 0..<total)
        var tier = Self.superChatTiers[0]
        for t in Self.superChatTiers {
            if roll < t.weight {
                tier = t
                break
            }
            roll -= t.weight
        }
        let chat = SuperChat(name: Self.superChatNames.randomElement() ?? "名無し",
                             message: Self.superChatMessages.randomElement() ?? "",
                             yen: tier.yen,
                             color: tier.color,
                             reward: ((basePerSecond * 3 + cellValue * 10) * tier.multiplier
                                      * (1 + 0.2 * Double(level(.superChat) - 1))).rounded())
        withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
            superChats.append(chat)
            if superChats.count > 2 { superChats.removeFirst() }
        }
        SoundEngine.shared.play(.notify)
        if tier.yen >= 5_000 {
            spawnDanmaku(4, from: ["赤スパ！", "ナイスパ", "金持ち", "うおお"])
        }
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(7))
            guard let self else { return }
            withAnimation(.easeIn(duration: 0.25)) {
                self.superChats.removeAll { $0.id == chat.id }
            }
        }
    }

    func collect(_ chat: SuperChat) {
        guard superChats.contains(where: { $0.id == chat.id }) else { return }
        let earned = earn(chat.reward)
        withAnimation(.easeIn(duration: 0.2)) {
            superChats.removeAll { $0.id == chat.id }
        }
        addPopup("¥\(chat.yen.formatted()) → +\(earned.stimText)", kind: .chain, row: board.rows - 1, col: board.cols / 2)
        SoundEngine.shared.play(.cash)
        Haptics.impact(.medium)
        if bump(.superChats) >= 10 { unlock(.superChat10) }
    }

    // MARK: - 謎の生き物

    private func tickPet(_ dt: Double) {
        petHunger = max(0, petHunger - dt / 150)
        guard petHunger < 0.3 else { return }
        cryClock -= dt
        if cryClock <= 0 {
            cryClock = 7
            SoundEngine.shared.play(.cry)
            Haptics.impact(.soft)
            if petHunger <= 0 { unlock(.petStarved) }
        }
    }

    func feedPet() {
        let cost = petFoodCost
        guard owns(.pet), stim >= cost else {
            Haptics.notify(.warning)
            return
        }
        stim -= cost
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            petHunger = 1
            petFedCount += 1
        }
        SoundEngine.shared.play(.buy)
        Haptics.impact(.medium)
        _ = bump(.petFeeds)
        unlock(.petFed)
    }

    // MARK: - 勉強しろ鳥

    private static let birdCalm = [
        "今日の勉強、まだですよね？",
        "5分だけ単語やろ？",
        "マインスイーパーは履歴書に書けませんよ",
        "その指、ペンを持てますよね？"
    ]
    private static let birdAngry = [
        "まだやってるの？",
        "鳥は見ています",
        "さっきも「あとで」って言いましたよね",
        "……（無言の圧）",
        "通知、止めませんよ"
    ]

    private func tickBird(_ dt: Double) {
        if birdVisible {
            birdNagClock -= dt
            if birdNagClock <= 0 {
                birdNagClock = 6
                birdAnger += 1
                birdLine = Self.birdAngry.randomElement() ?? ""
                SoundEngine.shared.play(.notify)
                Haptics.impact(.rigid)
            }
        } else {
            birdClock -= dt
            if birdClock <= 0 {
                birdLine = Self.birdCalm.randomElement() ?? ""
                birdAnger = 0
                birdNagClock = 6
                withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) { birdVisible = true }
                SoundEngine.shared.play(.notify)
            }
        }
    }

    /// 画面に出る鳥の数
    var birdCount: Int { min(max(level(.studyBird), 1), 3) }

    func dismissBird() {
        guard birdVisible else { return }
        withAnimation(.easeIn(duration: 0.25)) { birdVisible = false }
        birdClock = .random(in: 45...80)
        let earned = earn((cellValue * 20 + basePerSecond * 5) * Double(level(.studyBird)))
        addPopup("鳥を無視 +\(earned.stimText)", kind: .info, row: board.rows / 2, col: board.cols - 2)
        SoundEngine.shared.play(.button)
        if bump(.birdIgnored) >= 10 { unlock(.birdIgnored10) }
    }

    // MARK: - 魚

    /// 一度に泳がせる魚の上限
    static let maxSwimming = 20

    var fishCapacity: Int { level(.aquarium) * 5 }
    var hasTankSpace: Bool { fish.count < fishCapacity }
    var eggPrice: Double { (300 * pow(1.25, Double(fish.count))).rounded() }
    var fishFoodCost: Double { (20 + basePerSecond * 2).rounded() }
    var hungryFishCount: Int { fish.filter { $0.hunger < 0.99 }.count }
    var swimmingFish: [OwnedFish] {
        Array(fish.filter { $0.swimming && $0.stage != .egg }.prefix(Self.maxSwimming))
    }

    var fishPerSecond: Double {
        fish.reduce(0.0) { $0 + $1.incomePerSecond }
    }

    func buyEgg() {
        let price = eggPrice
        guard owns(.aquarium), hasTankSpace, stim >= price, !isBlocked else {
            Haptics.notify(.warning)
            return
        }
        stim -= price
        addEgg()
        SoundEngine.shared.play(.gacha)
        save()
    }

    /// 盤面クリアなどでたまに卵が落ちる。水槽がいっぱいなら刺激に換える
    private func dropEgg(reason: String) {
        guard owns(.aquarium) else { return }
        if hasTankSpace {
            addEgg(prefix: "\(reason)で")
        } else {
            let earned = earn(eggPrice * 0.3)
            addPopup("水槽が満員… +\(earned.stimText)", kind: .info, row: board.rows / 2, col: board.cols / 2)
        }
    }

    private func addEgg(prefix: String = "") {
        let rarity = FishSpecies.randomRarity()
        let egg = OwnedFish(species: FishSpecies.random(rarity: rarity),
                            swimming: swimmingFish.count < Self.maxSwimming)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { fish.append(egg) }
        addPopup("\(prefix)\(rarity.label)の卵GET!", kind: rarity >= .sr ? .fever : .chain,
                 row: board.rows / 2, col: board.cols / 2)
        if rarity >= .sr {
            SoundEngine.shared.play(.ssr)
            spawnDanmaku(3, from: ["レア卵！", "なにが生まれる？", "あたりの予感"])
        }
        Haptics.impact(.medium)
    }

    /// マスを開けたぶん、おなかが空いていない魚に経験値が入る
    private func growFish(by xp: Double) {
        guard !fish.isEmpty, xp > 0 else { return }
        var updated = fish
        var events: [(OwnedFish, FishStage, FishStage)] = []
        for i in updated.indices where updated[i].hunger > 0 {
            let before = updated[i].stage
            updated[i].xp += xp
            let after = updated[i].stage
            if after != before { events.append((updated[i], before, after)) }
        }
        fish = updated
        for (f, from, stage) in events { celebrateGrowth(f, from: from, to: stage) }
    }

    private func tickFish(_ dt: Double) {
        guard !fish.isEmpty else { return }
        var updated = fish
        var events: [(OwnedFish, FishStage, FishStage)] = []
        for i in updated.indices {
            updated[i].hunger = max(0, updated[i].hunger - dt / OwnedFish.maxHungerSeconds)
            guard updated[i].hunger > 0 else { continue }
            let before = updated[i].stage
            updated[i].xp += OwnedFish.xpPerSecond * dt
            let after = updated[i].stage
            if after != before { events.append((updated[i], before, after)) }
        }
        fish = updated
        for (f, from, stage) in events { celebrateGrowth(f, from: from, to: stage) }
    }

    /// アプリを閉じていたあいだの成長（おなかが空くまでの時間だけ育つ）
    private func applyOfflineFish(seconds: Double) {
        guard !fish.isEmpty else { return }
        var updated = fish
        for i in updated.indices {
            let fedSeconds = min(seconds, updated[i].hunger * OwnedFish.maxHungerSeconds)
            updated[i].xp += OwnedFish.xpPerSecond * fedSeconds
            updated[i].hunger = max(0, updated[i].hunger - seconds / OwnedFish.maxHungerSeconds)
        }
        fish = updated
        for f in fish where f.stage != .egg { dex.insert(f.species) }
    }

    /// 段階が変わったときの演出。一気に2段階以上育った場合も、ふ化の処理は必ず通す
    private func celebrateGrowth(_ f: OwnedFish, from before: FishStage, to stage: FishStage) {
        let r = board.rows / 2, c = board.cols / 2
        if before == .egg && stage >= .fry {
            dex.insert(f.species)
            addPopup("孵化! \(f.species.name)(\(f.species.rarity.label))", kind: f.species.rarity >= .sr ? .fever : .chain,
                     row: r, col: c)
            SoundEngine.shared.play(f.species.rarity >= .sr ? .ssr : .revive)
            Haptics.notify(.success)
            spawnDanmaku(3, from: ["生まれた！", "かわいい", "\(f.species.name)だ", "命の誕生"])
            unlock(.firstFish)
            if f.species.rarity == .ssr { unlock(.ssrFish) }
            if dex.count >= FishSpecies.allCases.count { unlock(.fishDex) }
        }
        if stage == .juvenile && before >= .fry {
            addPopup("\(f.displayName)が若魚に!", kind: .info, row: r, col: c)
        }
        if stage == .adult {
            addPopup("\(f.displayName)が成魚に!!", kind: .combo, row: r, col: c)
            SoundEngine.shared.play(.fanfare)
            if fish.filter({ $0.stage == .adult }).count >= 10 { unlock(.adultFish10) }
        }
    }

    func feedFish(_ id: UUID) {
        let cost = fishFoodCost
        guard let i = fish.firstIndex(where: { $0.id == id }), stim >= cost else {
            Haptics.notify(.warning)
            return
        }
        stim -= cost
        let before = fish[i].stage
        fish[i].hunger = 1
        fish[i].xp += 40
        let after = fish[i].stage
        SoundEngine.shared.play(.buy)
        Haptics.impact(.light)
        if after != before { celebrateGrowth(fish[i], from: before, to: after) }
    }

    func feedAllFish() {
        let targets = fish.filter { $0.hunger < 0.99 }.map(\.id)
        let cost = fishFoodCost * Double(targets.count)
        guard !targets.isEmpty, stim >= cost else {
            Haptics.notify(.warning)
            return
        }
        stim -= cost
        var updated = fish
        var events: [(OwnedFish, FishStage, FishStage)] = []
        for i in updated.indices where targets.contains(updated[i].id) {
            let before = updated[i].stage
            updated[i].hunger = 1
            updated[i].xp += 40
            if updated[i].stage != before { events.append((updated[i], before, updated[i].stage)) }
        }
        fish = updated
        SoundEngine.shared.play(.buy)
        Haptics.impact(.medium)
        for (f, from, stage) in events { celebrateGrowth(f, from: from, to: stage) }
    }

    func toggleSwimming(_ id: UUID) {
        guard let i = fish.firstIndex(where: { $0.id == id }) else { return }
        if !fish[i].swimming && swimmingFish.count >= Self.maxSwimming {
            Haptics.notify(.warning)
            return
        }
        fish[i].swimming.toggle()
        Haptics.impact(.light)
    }

    func renameFish(_ id: UUID, to name: String) {
        guard let i = fish.firstIndex(where: { $0.id == id }) else { return }
        fish[i].nickname = String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(12))
        save()
    }

    /// 手放した魚の値段
    func releaseValue(_ f: OwnedFish) -> Double {
        (f.species.incomePerSecond * max(0.1, f.stage.incomeScale) * 60 + 50).rounded()
    }

    func releaseFish(_ id: UUID) {
        guard let f = fish.first(where: { $0.id == id }) else { return }
        let earned = earn(releaseValue(f), boosted: false)
        withAnimation(.easeOut) { fish.removeAll { $0.id == id } }
        addPopup("さようなら \(f.displayName) +\(earned.stimText)", kind: .info, row: board.rows / 2, col: board.cols / 2)
        SoundEngine.shared.play(.cash)
        save()
    }

    // MARK: - 画面のヒビ

    private func addCrack() {
        guard owns(.cracks) else { return }
        let crack = ScreenCrack(x: .random(in: 0.1...0.9),
                                y: .random(in: 0.15...0.85),
                                seed: UInt64.random(in: 1...UInt64.max),
                                scale: .random(in: 0.7...1.3))
        withAnimation(.easeOut(duration: 0.15)) {
            cracks.append(crack)
            if cracks.count > 8 { cracks.removeFirst() }
        }
        SoundEngine.shared.play(.crack)
        if cracks.count >= 8 { unlock(.cracked) }
    }

    // MARK: - スロット

    private func startSlot() {
        let symbols = SlotSpin.reelSymbols
        let win = Double.random(in: 0..<1) < 0.35
        var result: [String]
        if win {
            let s = symbols.randomElement() ?? "7️⃣"
            result = [s, s, s]
        } else {
            repeat {
                result = (0..<3).map { _ in symbols.randomElement() ?? "🍒" }
            } while result[0] == result[1] && result[1] == result[2]
        }
        let spin = SlotSpin(symbols: result, win: win)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { slotSpin = spin }
        SoundEngine.shared.play(.gacha)
        spawnDanmaku(3, from: ["スロットきた", "そろえ！", "たのむ"])

        let id = boardID
        Task { [weak self] in
            for _ in 0..<3 {
                try? await Task.sleep(for: .seconds(0.4))
                SoundEngine.shared.play(.slotStop)
                Haptics.impact(.rigid)
            }
            try? await Task.sleep(for: .seconds(0.3))
            guard let self, self.slotSpin?.id == spin.id else { return }
            if win {
                let reward = self.earn(self.cellValue * 50 + self.basePerSecond * 10)
                self.addPopup("JACKPOT!! +\(reward.stimText)", kind: .fever, row: self.board.rows / 2, col: self.board.cols / 2)
                SoundEngine.shared.play(.ssr)
                Haptics.notify(.success)
                self.shakeCount += 1
                self.shout(["ジャックポット！", "そろったー！"], force: true)
                self.spawnDanmaku(6, from: ["そろった！！", "777", "神台", "ジャックポット"])
                _ = self.bump(.slotWins)
                self.unlock(.slotWin)
                if Double.random(in: 0..<1) < 0.5 { self.dropEgg(reason: "スロット") }
                for _ in 0..<8 {
                    guard self.boardID == id, self.phase == .playing else { break }
                    self.openOneSafeCell()
                    try? await Task.sleep(for: .milliseconds(90))
                }
            } else {
                let reward = self.earn(self.cellValue * 5)
                self.addPopup("ハズレ… +\(reward.stimText)", kind: .info, row: self.board.rows / 2, col: self.board.cols / 2)
            }
            try? await Task.sleep(for: .seconds(0.8))
            if self.slotSpin?.id == spin.id {
                withAnimation(.easeOut) { self.slotSpin = nil }
            }
        }
    }

    // MARK: - 株

    private func stepStock() {
        let volatility = min(0.15, 0.06 * (1 + 0.1 * Double(level(.stocks) - 1)))
        var p = stockPrice * exp(Double.random(in: -1...1) * volatility) + (100 - stockPrice) * 0.03
        if Double.random(in: 0..<1) < 0.01 {
            p *= 1.6
            addPopup("$DOPA 爆上げ!!", kind: .chain, row: 1, col: board.cols / 2)
        } else if Double.random(in: 0..<1) < 0.01 {
            p *= 0.6
            addPopup("$DOPA 暴落…", kind: .combo, row: 1, col: board.cols / 2)
        }
        stockPrice = min(400, max(20, p))
        stockHistory.append(stockPrice)
        if stockHistory.count > 60 { stockHistory.removeFirst() }
    }

    // MARK: - ガチャ

    func rollGacha() {
        let cost = gachaCost
        guard owns(.gacha), gachaResult == nil, stim >= cost, !isBlocked else {
            Haptics.notify(.warning)
            return
        }
        stim -= cost
        gachaRolls += 1

        let roll = Double.random(in: 0..<1)
        let bonus = Double(level(.gacha) - 1)
        let ssrRate = min(0.08, 0.02 + 0.005 * bonus)
        let srRate = ssrRate + min(0.2, 0.1 + 0.01 * bonus)
        let rarity: GachaResult.Rarity
        let multiplier: Double
        if roll < ssrRate {
            rarity = .ssr
            multiplier = 20
        } else if roll < srRate {
            rarity = .sr
            multiplier = 4
        } else if roll < srRate + 0.28 {
            rarity = .r
            multiplier = 1.5
        } else {
            rarity = .n
            multiplier = 0.5
        }
        let reward = (cost * multiplier).rounded()
        earn(reward, boosted: false)
        let result = GachaResult(rarity: rarity, reward: reward)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) { gachaResult = result }

        switch rarity {
        case .ssr:
            SoundEngine.shared.play(.ssr)
            Haptics.notify(.success)
            shakeCount += 1
            shout(["SSR！！！", "神引き！！"], force: true)
            spawnDanmaku(8, from: ["SSR！！", "神引き", "うそだろ", "おめ！", "888888"])
            unlock(.ssr)
        case .sr:
            SoundEngine.shared.play(.ssr)
            Haptics.impact(.heavy)
        default:
            SoundEngine.shared.play(.gacha)
            Haptics.impact(.light)
        }
        save()

        Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.8))
            guard let self, self.gachaResult?.id == result.id else { return }
            withAnimation(.easeOut) { self.gachaResult = nil }
        }
    }

    // MARK: - 実況ボイス

    private func shout(_ lines: [String] = ["ナイス！", "うおおおお！", "天才！", "脳汁ドバドバ！", "やばすぎ！", "神！", "いけいけー！"],
                       force: Bool = false) {
        guard owns(.hypeVoice), !showEnding else { return }
        let interval = max(0.5, 1.5 / Double(level(.hypeVoice)))
        guard force || Date().timeIntervalSince(lastVoice) > interval else { return }
        lastVoice = Date()
        if let line = lines.randomElement() {
            HypeVoice.shared.say(line)
        }
    }

    // MARK: - 実績

    private func unlock(_ achievement: StimAchievement) {
        guard !achievements.contains(achievement) else { return }
        achievements.insert(achievement)
        let reward = earn((max(100, basePerSecond * 30 + cellValue * 20)).rounded(), boosted: false)
        toastQueue.append(AchievementToast(achievement: achievement, reward: reward))
        showNextToast()
        saveClock = 5
    }

    private func showNextToast() {
        guard achievementToast == nil, !toastQueue.isEmpty else { return }
        let toast = toastQueue.removeFirst()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { achievementToast = toast }
        SoundEngine.shared.play(.ssr)
        Haptics.notify(.success)
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(2.4))
            guard let self else { return }
            withAnimation(.easeIn(duration: 0.25)) { self.achievementToast = nil }
            try? await Task.sleep(for: .seconds(0.35))
            self.showNextToast()
        }
    }

    // MARK: - エンディングと転生

    private func triggerEnding() {
        SoundEngine.shared.stopAllLoops()
        HypeVoice.shared.stop()
        withAnimation(.easeOut) {
            notifications = []
            superChats = []
            danmaku = []
            birdVisible = false
        }
        save(endingSeen: true)
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(0.6))
            withAnimation(.easeInOut(duration: 2.5)) { self?.showEnding = true }
        }
    }

    /// 今回の周回を手放して、ずっと残る倍率をもらう
    func prestige() {
        let gain = prestigeGain
        guard gain > 0 else {
            Haptics.notify(.warning)
            return
        }
        prestigePoints += gain
        prestigeCount += 1
        HypeVoice.shared.stop()

        stim = 0
        totalEarned = 0
        // 魚と水槽は転生しても残す
        let aquarium = level(.aquarium)
        var kept: [StimItem: Int] = [:]
        if aquarium > 0 { kept[.aquarium] = aquarium }
        levels = kept
        gachaRolls = 0
        combo = 0
        clearStreak = 0
        petHunger = 1
        stockPrice = 100
        stockHistory = Array(repeating: 100, count: 60)
        notifications = []
        superChats = []
        danmaku = []
        cracks = []
        popups = []
        gachaResult = nil
        slotSpin = nil
        adSession = nil
        birdVisible = false
        birdClock = 25
        newBoard()
        showEnding = false
        applyAmbience()

        SoundEngine.shared.play(.fanfare)
        Haptics.notify(.success)
        addPopup("転生!! 倍率 x\(prestigeMultiplier.formatted(.number.precision(.fractionLength(1))))",
                 kind: .fever, row: board.rows / 2, col: board.cols / 2)
        unlock(.prestige)
        save(endingSeen: false)
    }

    // MARK: - その他

    private func addPopup(_ text: String, kind: Popup.Kind, row: Int, col: Int) {
        let popup = Popup(text: text, kind: kind, row: row, col: col)
        popups.append(popup)
        if popups.count > 12 { popups.removeFirst() }
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.1))
            self?.popups.removeAll { $0.id == popup.id }
        }
    }

    func save(endingSeen: Bool? = nil) {
        saveClock = 0
        var s = StimSave()
        s.stim = stim
        s.totalEarned = totalEarned
        s.lifetimeEarned = lifetimeEarned
        s.levels = Dictionary(uniqueKeysWithValues: levels.map { ($0.key.rawValue, $0.value) })
        s.cellsOpened = cellsOpened
        s.clears = clears
        s.gachaRolls = gachaRolls
        s.endingSeen = endingSeen ?? showEnding
        s.prestigePoints = prestigePoints
        s.prestigeCount = prestigeCount
        s.achievements = achievements.map(\.rawValue).sorted()
        s.counters = Dictionary(uniqueKeysWithValues: counters.map { ($0.key.rawValue, $0.value) })
        s.lastSeen = Date()
        s.lastLoginDay = lastLoginDay
        s.loginStreak = loginStreak
        s.petHunger = petHunger
        s.fish = fish
        s.dex = dex.map(\.rawValue).sorted()
        s.store()
    }
}
