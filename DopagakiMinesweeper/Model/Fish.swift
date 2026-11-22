import SwiftUI

// MARK: - 魚のレア度

enum FishRarity: Int, Codable, CaseIterable, Comparable {
    case n, r, sr, ssr

    static func < (a: FishRarity, b: FishRarity) -> Bool { a.rawValue < b.rawValue }

    var label: String {
        switch self {
        case .n: return "N"
        case .r: return "R"
        case .sr: return "SR"
        case .ssr: return "SSR"
        }
    }

    var color: Color {
        switch self {
        case .n: return Palette.lavender
        case .r: return Palette.cyan
        case .sr: return Palette.pink
        case .ssr: return Palette.yellow
        }
    }

    /// 卵から出る確率の重み
    var weight: Double {
        switch self {
        case .n: return 60
        case .r: return 28
        case .sr: return 10
        case .ssr: return 2
        }
    }

    /// 成魚になるまでの経験値の倍率（レアほど育つのが遅い）
    var growthScale: Double {
        switch self {
        case .n: return 1
        case .r: return 1.5
        case .sr: return 2.5
        case .ssr: return 4
        }
    }
}

// MARK: - 泳ぎ方と形

enum SwimStyle {
    /// まっすぐ
    case straight
    /// くねくね
    case wiggle
    /// ふわふわ（上下に漂う）
    case float
    /// 止まったり急に進んだり
    case dash
    /// ゆったり大きく
    case glide
}

enum FishShape {
    case slim, goldfish, guppy, puffer, angel, clown, betta, whaleShark, angler, oarfish, jelly
}

// MARK: - 魚の種類

enum FishSpecies: String, CaseIterable, Codable, Identifiable {
    case medaka, neon, goldfish, guppy
    case puffer, angel, clown, betta
    case whaleShark, angler
    case oarfish, jelly

    var id: String { rawValue }

    var name: String {
        switch self {
        case .medaka: return "ドパメダカ"
        case .neon: return "ネオンテトラ"
        case .goldfish: return "金魚"
        case .guppy: return "グッピー"
        case .puffer: return "ハリセンボン"
        case .angel: return "エンゼルフィッシュ"
        case .clown: return "クマノミ"
        case .betta: return "ベタ"
        case .whaleShark: return "ジンベエザメ"
        case .angler: return "チョウチンアンコウ"
        case .oarfish: return "虹色リュウグウノツカイ"
        case .jelly: return "脳汁クラゲ"
        }
    }

    var rarity: FishRarity {
        switch self {
        case .medaka, .neon, .goldfish, .guppy: return .n
        case .puffer, .angel, .clown, .betta: return .r
        case .whaleShark, .angler: return .sr
        case .oarfish, .jelly: return .ssr
        }
    }

    var shape: FishShape {
        switch self {
        case .medaka, .neon: return .slim
        case .goldfish: return .goldfish
        case .guppy: return .guppy
        case .puffer: return .puffer
        case .angel: return .angel
        case .clown: return .clown
        case .betta: return .betta
        case .whaleShark: return .whaleShark
        case .angler: return .angler
        case .oarfish: return .oarfish
        case .jelly: return .jelly
        }
    }

    var swim: SwimStyle {
        switch self {
        case .medaka, .neon: return .dash
        case .goldfish, .betta, .angel: return .wiggle
        case .guppy, .clown: return .straight
        case .puffer, .jelly: return .float
        case .whaleShark, .angler, .oarfish: return .glide
        }
    }

    /// 体の色
    var color: Color {
        switch self {
        case .medaka: return Color(hex: 0xFFD27A)
        case .neon: return Color(hex: 0x3A6BFF)
        case .goldfish: return Color(hex: 0xFF5A2E)
        case .guppy: return Color(hex: 0xB6C2D9)
        case .puffer: return Color(hex: 0xE8C76A)
        case .angel: return Color(hex: 0xF2F2F2)
        case .clown: return Palette.orange
        case .betta: return Color(hex: 0x6B2BD9)
        case .whaleShark: return Color(hex: 0x2D4B7A)
        case .angler: return Color(hex: 0x4A3A5C)
        case .oarfish: return Color(hex: 0xC8D4E8)
        case .jelly: return Palette.pinkSoft
        }
    }

    /// 模様・ひれの色
    var accent: Color {
        switch self {
        case .medaka: return Palette.orange
        case .neon: return Palette.cyan
        case .goldfish: return Palette.yellow
        case .guppy: return Palette.pink
        case .puffer: return Color(hex: 0x6B4A1E)
        case .angel: return .black
        case .clown: return .white
        case .betta: return Palette.pink
        case .whaleShark: return .white
        case .angler: return Palette.yellow
        case .oarfish: return Color(hex: 0xFF3B3B)
        case .jelly: return Palette.lavender
        }
    }

    /// 成魚のときの体長（pt）
    var adultLength: Double {
        switch self {
        case .medaka, .neon: return 34
        case .guppy: return 40
        case .goldfish, .clown: return 46
        case .puffer, .betta: return 50
        case .angel: return 54
        case .jelly: return 56
        case .angler: return 62
        case .whaleShark: return 110
        case .oarfish: return 130
        }
    }

    /// 泳ぐ速さ（pt/秒）
    var speed: Double {
        switch swim {
        case .straight: return 55
        case .wiggle: return 40
        case .float: return 14
        case .dash: return 70
        case .glide: return 28
        }
    }

    /// 成魚が生む毎秒の刺激
    var incomePerSecond: Double {
        switch rarity {
        case .n: return 2
        case .r: return 6
        case .sr: return 20
        case .ssr: return 60
        }
    }

    static func random(rarity: FishRarity) -> FishSpecies {
        allCases.filter { $0.rarity == rarity }.randomElement() ?? .medaka
    }

    static func randomRarity() -> FishRarity {
        let total = FishRarity.allCases.reduce(0.0) { $0 + $1.weight }
        var roll = Double.random(in: 0..<total)
        for r in FishRarity.allCases {
            if roll < r.weight { return r }
            roll -= r.weight
        }
        return .n
    }
}

// MARK: - 成長段階

enum FishStage: Int, Comparable {
    case egg, fry, juvenile, adult

    static func < (a: FishStage, b: FishStage) -> Bool { a.rawValue < b.rawValue }

    var label: String {
        switch self {
        case .egg: return "卵"
        case .fry: return "稚魚"
        case .juvenile: return "若魚"
        case .adult: return "成魚"
        }
    }

    /// 成魚を1としたときの大きさ
    var sizeScale: Double {
        switch self {
        case .egg: return 0
        case .fry: return 0.4
        case .juvenile: return 0.7
        case .adult: return 1
        }
    }

    /// 成魚を1としたときの刺激
    var incomeScale: Double {
        switch self {
        case .egg: return 0
        case .fry: return 0.25
        case .juvenile: return 0.5
        case .adult: return 1
        }
    }

    /// この段階になるのに必要な経験値（N の場合）
    var baseXP: Double {
        switch self {
        case .egg: return 0
        case .fry: return 20
        case .juvenile: return 150
        case .adult: return 600
        }
    }
}

// MARK: - 飼っている魚

struct OwnedFish: Identifiable, Codable, Equatable {
    var id = UUID()
    var species: FishSpecies
    var nickname: String = ""
    var xp: Double = 0
    /// 1 で満腹、0 でおなかぺこぺこ（成長が止まる）
    var hunger: Double = 1
    /// 画面で泳がせるか
    var swimming: Bool = true

    static let maxHungerSeconds: Double = 600
    static let xpPerSecond: Double = 0.2

    var stage: FishStage {
        let scale = species.rarity.growthScale
        if xp >= FishStage.adult.baseXP * scale { return .adult }
        if xp >= FishStage.juvenile.baseXP * scale { return .juvenile }
        if xp >= FishStage.fry.baseXP * scale { return .fry }
        return .egg
    }

    /// 次の段階までの進み具合（0〜1）
    var stageProgress: Double {
        let scale = species.rarity.growthScale
        switch stage {
        case .adult: return 1
        case .egg: return xp / (FishStage.fry.baseXP * scale)
        case .fry:
            let lo = FishStage.fry.baseXP * scale, hi = FishStage.juvenile.baseXP * scale
            return (xp - lo) / (hi - lo)
        case .juvenile:
            let lo = FishStage.juvenile.baseXP * scale, hi = FishStage.adult.baseXP * scale
            return (xp - lo) / (hi - lo)
        }
    }

    var displayName: String {
        if stage == .egg { return "\(species.rarity.label)の卵" }
        return nickname.isEmpty ? species.name : nickname
    }

    var incomePerSecond: Double {
        species.incomePerSecond * stage.incomeScale * (hunger > 0 ? 1 : 0.5)
    }

    /// 泳ぐ動きをばらけさせるための 0〜1 の値
    var seed: Double {
        let bytes = id.uuid
        return Double(Int(bytes.0) * 256 + Int(bytes.1)) / 65_536
    }

    var seed2: Double {
        let bytes = id.uuid
        return Double(Int(bytes.2) * 256 + Int(bytes.3)) / 65_536
    }
}
