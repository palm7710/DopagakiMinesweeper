import SwiftUI

// MARK: - 刺激モードのショップ商品

/// 刺激モードで買えるもの。買うほど画面がうるさくなる（並び順＝ショップの並び順）
enum StimItem: String, CaseIterable, Identifiable, Codable {
    case tapPower
    case dvd
    case lucky
    case notifications
    case danmaku
    case ticker
    case lofi
    case pet
    case aquarium
    case runner
    case slot
    case stocks
    case cracks
    case rain
    case superChat
    case emojiRain
    case studyBird
    case gacha
    case hypeVoice
    case rainbow
    case detox

    var id: String { rawValue }

    var name: String {
        switch self {
        case .tapPower: return "脳汁ブースター"
        case .dvd: return "DVDロゴ"
        case .lucky: return "ラッキーマス"
        case .notifications: return "通知ON"
        case .danmaku: return "弾幕コメント"
        case .ticker: return "ニュース速報"
        case .lofi: return "ローファイBGM"
        case .pet: return "謎の生き物"
        case .aquarium: return "水槽"
        case .runner: return "ゲーム実況"
        case .slot: return "スロットマス"
        case .stocks: return "株チャート $DOPA"
        case .cracks: return "画面バキバキ"
        case .rain: return "雨音ASMR"
        case .superChat: return "投げ銭"
        case .emojiRain: return "絵文字シャワー"
        case .studyBird: return "勉強しろ鳥"
        case .gacha: return "ガチャ解禁"
        case .hypeVoice: return "実況ボイス"
        case .rainbow: return "ゲーミング背景"
        case .detox: return "デジタルデトックス"
        }
    }

    var detail: String {
        switch self {
        case .tapPower: return "1マスで手に入る刺激 +1"
        case .dvd: return "画面をはねまわる。角にピッタリ当たると大当たり"
        case .lucky: return "金色のマスが混ざる。開けると刺激 ×10"
        case .notifications: return "どうでもいい通知が届く。タップで刺激"
        case .danmaku: return "コメントが画面を流れる。連鎖すると増える"
        case .ticker: return "画面の上を見出しが流れつづける"
        case .lofi: return "勉強にも作業にも向かないビート"
        case .pet: return "ごはんをあげると刺激が増える。放っておくと泣く"
        case .aquarium: return "魚が飼えるようになる。1個で5匹ぶん"
        case .runner: return "すみっこで知らない人のゲーム配信が流れる"
        case .slot: return "777マスを開けるとスロット。そろえば勝手に連鎖"
        case .stocks: return "株価しだいで毎秒の刺激が増えたり減ったり"
        case .cracks: return "大連鎖のたびに画面にヒビ。クリアで直る"
        case .rain: return "しとしと。なのに落ち着かない"
        case .superChat: return "知らない人からお金が飛んでくる。タップで回収"
        case .emojiRain: return "背景に絵文字が降りそそぐ"
        case .studyBird: return "定期的に勉強しろと言ってくる。なぜか刺激が増える"
        case .gacha: return "刺激を払って刺激を回す"
        case .hypeVoice: return "連鎖するたびに大声でほめてくれる"
        case .rainbow: return "背景が7色に光る。性能は上がらない"
        case .detox: return "すべてを手放す"
        }
    }

    var icon: String {
        switch self {
        case .tapPower: return "brain.head.profile"
        case .dvd: return "tv.fill"
        case .lucky: return "sparkles"
        case .notifications: return "bell.badge.fill"
        case .danmaku: return "text.bubble.fill"
        case .ticker: return "newspaper.fill"
        case .lofi: return "headphones"
        case .pet: return "pawprint.fill"
        case .aquarium: return "fish.fill"
        case .runner: return "play.rectangle.fill"
        case .slot: return "7.square.fill"
        case .stocks: return "chart.line.uptrend.xyaxis"
        case .cracks: return "bolt.fill"
        case .rain: return "cloud.rain.fill"
        case .superChat: return "yensign.circle.fill"
        case .emojiRain: return "face.smiling.inverse"
        case .studyBird: return "bird.fill"
        case .gacha: return "die.face.5.fill"
        case .hypeVoice: return "megaphone.fill"
        case .rainbow: return "rainbow"
        case .detox: return "leaf.fill"
        }
    }

    var color: Color {
        switch self {
        case .tapPower, .runner, .hypeVoice, .superChat: return Palette.pink
        case .dvd, .rain, .danmaku, .aquarium: return Palette.cyan
        case .notifications, .emojiRain, .lucky: return Palette.yellow
        case .stocks, .rainbow, .studyBird: return Palette.lime
        case .ticker, .gacha, .slot, .cracks: return Palette.orange
        case .lofi, .pet: return Palette.lavender
        case .detox: return .white
        }
    }

    var basePrice: Double {
        switch self {
        case .tapPower: return 15
        case .dvd: return 40
        case .lucky: return 80
        case .notifications: return 150
        case .danmaku: return 300
        case .ticker: return 500
        case .lofi: return 800
        case .pet: return 1_200
        case .aquarium: return 1_500
        case .runner: return 1_800
        case .slot: return 2_500
        case .stocks: return 3_500
        case .cracks: return 5_000
        case .rain: return 7_000
        case .superChat: return 9_000
        case .emojiRain: return 12_000
        case .studyBird: return 16_000
        case .gacha: return 20_000
        case .hypeVoice: return 28_000
        case .rainbow: return 40_000
        case .detox: return 200_000
        }
    }

    /// 買うたびに値段が何倍になるか
    var priceGrowth: Double {
        switch self {
        case .tapPower: return 1.4
        case .detox: return 1
        default: return 1.15
        }
    }

    /// デジタルデトックス以外は何回でも買える
    var maxLevel: Int {
        self == .detox ? 1 : 9_999
    }

    /// 数が増えると何が変わるか（ショップに表示）
    var scaling: String {
        switch self {
        case .tapPower: return "1マスの刺激がさらに +1"
        case .dvd: return "ロゴが増える（最大5個）"
        case .lucky: return "ラッキーマスが増える（最大4個）"
        case .notifications: return "通知がどんどん届く"
        case .danmaku: return "コメントの量が増える"
        case .ticker: return "流れる速さが上がる"
        case .lofi: return "2個目からメロディとベースが重なる"
        case .pet: return "生き物が増え、ごきげん時の倍率が上がる（最大3匹）"
        case .aquarium: return "飼える魚が5匹ずつ増える"
        case .runner: return "配信の小窓が増える（最大3つ）"
        case .slot: return "777マスが増える（最大3個）"
        case .stocks: return "持ち株が増え、値動きも激しくなる"
        case .cracks: return "毎秒の刺激が増える"
        case .rain: return "雨が強くなる"
        case .superChat: return "投げ銭が増え、金額も上がる"
        case .emojiRain: return "絵文字が増える"
        case .studyBird: return "鳥が増える（最大3羽）。無視したときの刺激も増える"
        case .gacha: return "SR・SSRが出やすくなる"
        case .hypeVoice: return "しゃべる回数が増える"
        case .rainbow: return "光る速さが上がる"
        case .detox: return ""
        }
    }

    /// 1レベルあたりの毎秒の刺激
    var perSecond: Double {
        switch self {
        case .dvd: return 0.5
        case .notifications: return 1
        case .danmaku: return 2
        case .ticker: return 3
        case .lofi: return 4
        case .runner: return 6
        case .stocks: return 8
        case .cracks: return 10
        case .rain: return 12
        case .emojiRain: return 18
        case .studyBird: return 25
        case .hypeVoice: return 35
        case .rainbow: return 50
        default: return 0
        }
    }

    func price(at level: Int) -> Double {
        (basePrice * pow(priceGrowth, Double(level))).rounded()
    }
}

// MARK: - 実績

enum StimAchievement: String, CaseIterable, Identifiable, Codable {
    case firstClear, clears10, clears50
    case chain25, combo20, lastCell
    case corner, lucky, lucky10, slotWin, ssr
    case adWatched, petFed, petStarved, superChat10, birdIgnored10
    case cracked, festa, login7
    case firstFish, ssrFish, adultFish10, fishDex
    case million, allItems, prestige, ending

    var id: String { rawValue }

    var title: String {
        switch self {
        case .firstClear: return "はじめてのクリア"
        case .clears10: return "10回クリア"
        case .clears50: return "50回クリア"
        case .chain25: return "大連鎖"
        case .combo20: return "コンボ職人"
        case .lastCell: return "心臓に悪い"
        case .corner: return "角の奇跡"
        case .lucky: return "金色の予感"
        case .lucky10: return "ラッキー体質"
        case .slotWin: return "ジャックポット"
        case .ssr: return "神引き"
        case .adWatched: return "広告を最後まで見た人"
        case .petFed: return "はじめてのごはん"
        case .petStarved: return "ごめんね"
        case .superChat10: return "投げ銭で生きる"
        case .birdIgnored10: return "鳥より地雷"
        case .cracked: return "画面バキバキ"
        case .festa: return "フェス参戦"
        case .login7: return "7日連続ログイン"
        case .firstFish: return "はじめての魚"
        case .ssrFish: return "伝説の魚"
        case .adultFish10: return "立派に育った"
        case .fishDex: return "魚図鑑コンプ"
        case .million: return "ミリオン脳汁"
        case .allItems: return "全部買った"
        case .prestige: return "生まれ変わり"
        case .ending: return "手放す"
        }
    }

    var detail: String {
        switch self {
        case .firstClear: return "刺激モードで盤面をクリアする"
        case .clears10: return "盤面を10回クリアする"
        case .clears50: return "盤面を50回クリアする"
        case .chain25: return "一度に25マス以上開ける"
        case .combo20: return "20コンボをつなぐ"
        case .lastCell: return "ラスト1マスの緊張に勝つ"
        case .corner: return "DVDロゴを角に当てる"
        case .lucky: return "ラッキーマスを開ける"
        case .lucky10: return "ラッキーマスを10回開ける"
        case .slotWin: return "スロットで3つそろえる"
        case .ssr: return "ガチャでSSRを引く"
        case .adWatched: return "広告を最後まで見る"
        case .petFed: return "謎の生き物にごはんをあげる"
        case .petStarved: return "謎の生き物のおなかを空っぽにする"
        case .superChat10: return "投げ銭を10回受け取る"
        case .birdIgnored10: return "勉強しろ鳥を10回無視する"
        case .cracked: return "画面にヒビを8本入れる"
        case .festa: return "脳汁2倍フェスに参加する"
        case .login7: return "7日続けてログインする"
        case .firstFish: return "卵から魚をかえす"
        case .ssrFish: return "SSRの魚をかえす"
        case .adultFish10: return "成魚を10匹そろえる"
        case .fishDex: return "魚図鑑をすべて埋める"
        case .million: return "累計100万の刺激を浴びる"
        case .allItems: return "ショップの商品をぜんぶ買う"
        case .prestige: return "はじめて転生する"
        case .ending: return "デジタルデトックスを買う"
        }
    }

    var icon: String {
        switch self {
        case .firstClear, .clears10, .clears50: return "flag.checkered"
        case .chain25: return "link"
        case .combo20: return "flame.fill"
        case .lastCell: return "heart.fill"
        case .corner: return "tv.fill"
        case .lucky, .lucky10: return "sparkles"
        case .slotWin: return "7.square.fill"
        case .ssr: return "star.fill"
        case .adWatched: return "play.tv.fill"
        case .petFed, .petStarved: return "pawprint.fill"
        case .superChat10: return "yensign.circle.fill"
        case .birdIgnored10: return "bird.fill"
        case .cracked: return "bolt.fill"
        case .festa: return "party.popper.fill"
        case .login7: return "calendar"
        case .firstFish, .adultFish10: return "fish.fill"
        case .ssrFish: return "star.circle.fill"
        case .fishDex: return "book.fill"
        case .million: return "crown.fill"
        case .allItems: return "cart.fill"
        case .prestige: return "arrow.triangle.2.circlepath"
        case .ending: return "leaf.fill"
        }
    }
}

/// 実績の判定に使う回数
enum StimCounter: String, Codable {
    case lucky, slotWins, ads, petFeeds, superChats, birdIgnored, corners
}

// MARK: - 保存データ

struct StimSave: Codable {
    var stim: Double = 0
    /// 今回の周回で稼いだ量（転生でリセット）
    var totalEarned: Double = 0
    /// これまでに稼いだ量（転生してもリセットしない）
    var lifetimeEarned: Double = 0
    var levels: [String: Int] = [:]
    var cellsOpened: Int = 0
    var clears: Int = 0
    var gachaRolls: Int = 0
    var endingSeen = false
    var prestigePoints: Int = 0
    var prestigeCount: Int = 0
    var achievements: [String] = []
    var counters: [String: Int] = [:]
    var lastSeen: Date?
    var lastLoginDay: String = ""
    var loginStreak: Int = 0
    var petHunger: Double = 1
    var fish: [OwnedFish] = []
    var dex: [String] = []

    private static let key = "stimSave"

    init() {}

    /// 古い保存データに無い項目があっても読めるようにする
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        stim = try c.decodeIfPresent(Double.self, forKey: .stim) ?? 0
        totalEarned = try c.decodeIfPresent(Double.self, forKey: .totalEarned) ?? 0
        lifetimeEarned = try c.decodeIfPresent(Double.self, forKey: .lifetimeEarned) ?? totalEarned
        levels = try c.decodeIfPresent([String: Int].self, forKey: .levels) ?? [:]
        cellsOpened = try c.decodeIfPresent(Int.self, forKey: .cellsOpened) ?? 0
        clears = try c.decodeIfPresent(Int.self, forKey: .clears) ?? 0
        gachaRolls = try c.decodeIfPresent(Int.self, forKey: .gachaRolls) ?? 0
        endingSeen = try c.decodeIfPresent(Bool.self, forKey: .endingSeen) ?? false
        prestigePoints = try c.decodeIfPresent(Int.self, forKey: .prestigePoints) ?? 0
        prestigeCount = try c.decodeIfPresent(Int.self, forKey: .prestigeCount) ?? 0
        achievements = try c.decodeIfPresent([String].self, forKey: .achievements) ?? []
        counters = try c.decodeIfPresent([String: Int].self, forKey: .counters) ?? [:]
        lastSeen = try c.decodeIfPresent(Date.self, forKey: .lastSeen)
        lastLoginDay = try c.decodeIfPresent(String.self, forKey: .lastLoginDay) ?? ""
        loginStreak = try c.decodeIfPresent(Int.self, forKey: .loginStreak) ?? 0
        petHunger = try c.decodeIfPresent(Double.self, forKey: .petHunger) ?? 1
        fish = try c.decodeIfPresent([OwnedFish].self, forKey: .fish) ?? []
        dex = try c.decodeIfPresent([String].self, forKey: .dex) ?? []
    }

    static func load() -> StimSave {
        guard let data = UserDefaults.standard.data(forKey: key),
              let save = try? JSONDecoder().decode(StimSave.self, from: data) else { return StimSave() }
        return save
    }

    func store() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }
}

// MARK: - 数字の表示

extension Double {
    /// 1.2万 のような短い表記
    var stimText: String {
        if self < 1_000 {
            return self < 10 && self != rounded()
                ? formatted(.number.precision(.fractionLength(1)))
                : Int(self).formatted()
        }
        return formatted(.number.notation(.compactName).precision(.significantDigits(1...3)))
    }
}
