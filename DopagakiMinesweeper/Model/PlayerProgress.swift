import Foundation
import Observation

/// レベル・XP・連続日数・設定など、端末に保存するプレイヤー情報
@Observable
final class PlayerProgress {
    var xp: Int
    var level: Int
    var coins: Int
    var bestScore: Int
    var streak: Int
    var stage: Int
    var lastPlayDay: String

    var soundOn: Bool
    var hapticsOn: Bool
    var shakeOn: Bool

    @ObservationIgnored private let defaults = UserDefaults.standard

    init() {
        let d = UserDefaults.standard
        d.register(defaults: [
            "level": 1, "stage": 1,
            "soundOn": true, "hapticsOn": true, "shakeOn": true
        ])
        xp = d.integer(forKey: "xp")
        level = d.integer(forKey: "level")
        coins = d.integer(forKey: "coins")
        bestScore = d.integer(forKey: "bestScore")
        streak = d.integer(forKey: "streak")
        stage = d.integer(forKey: "stage")
        lastPlayDay = d.string(forKey: "lastPlayDay") ?? ""
        soundOn = d.bool(forKey: "soundOn")
        hapticsOn = d.bool(forKey: "hapticsOn")
        shakeOn = d.bool(forKey: "shakeOn")
        applySettings()
    }

    func save() {
        defaults.set(xp, forKey: "xp")
        defaults.set(level, forKey: "level")
        defaults.set(coins, forKey: "coins")
        defaults.set(bestScore, forKey: "bestScore")
        defaults.set(streak, forKey: "streak")
        defaults.set(stage, forKey: "stage")
        defaults.set(lastPlayDay, forKey: "lastPlayDay")
        defaults.set(soundOn, forKey: "soundOn")
        defaults.set(hapticsOn, forKey: "hapticsOn")
        defaults.set(shakeOn, forKey: "shakeOn")
        applySettings()
    }

    private func applySettings() {
        SoundEngine.shared.isEnabled = soundOn
        Haptics.isEnabled = hapticsOn
    }

    // MARK: レベル

    /// 次のレベルまでに必要な XP（序盤はすぐ上がるように低め）
    static func xpNeeded(for level: Int) -> Int { 300 + level * 100 }

    var xpToNext: Int { Self.xpNeeded(for: level) - xp }
    var levelProgress: Double { Double(xp) / Double(Self.xpNeeded(for: level)) }

    func addXP(_ amount: Int) {
        xp += amount
        while xp >= Self.xpNeeded(for: level) {
            xp -= Self.xpNeeded(for: level)
            level += 1
        }
        save()
    }

    func recordScore(_ score: Int) {
        bestScore = max(bestScore, score)
        save()
    }

    // MARK: 連続プレイ日数

    func markPlayedToday(now: Date = .now) {
        let today = Self.dayString(now)
        guard lastPlayDay != today else { return }
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now).map(Self.dayString)
        streak = (lastPlayDay == yesterday) ? streak + 1 : 1
        lastPlayDay = today
        save()
    }

    private static func dayString(_ date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }
}
