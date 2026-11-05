import SwiftUI
import UIKit
import CoreText

// MARK: - カラー（デザイン案「脳汁ネオン・ステッカー」）

enum Palette {
    static let base = Color(hex: 0x1B0F3B)
    static let panel = Color(hex: 0x2A1A5E)
    static let well = Color(hex: 0x120A2A)
    static let boardBG = Color(hex: 0x0B0620)
    static let divider = Color(hex: 0x4A3690)

    static let tile = Color(hex: 0x6B4BFF)
    static let tileDark = Color(hex: 0x3B22B8)
    static let tileLight = Color(hex: 0x9C85FF)
    static let fresh = Color(hex: 0x3A1050)

    static let yellow = Color(hex: 0xFFE600)
    static let pink = Color(hex: 0xFF2E88)
    static let pinkSoft = Color(hex: 0xFF4FA0)
    static let cyan = Color(hex: 0x2EE6FF)
    static let lime = Color(hex: 0x7CFF4F)
    static let orange = Color(hex: 0xFF8A1F)
    static let lavender = Color(hex: 0xC9BEFF)

    static let feverBG = Color(hex: 0x3A0A3E)
    static let gameOverBG = Color(hex: 0x2B0A1E)

    static func number(_ n: Int) -> Color {
        switch n {
        case 1: return cyan
        case 2: return lime
        case 3: return pinkSoft
        case 4: return yellow
        case 5: return orange
        case 6: return Color(hex: 0xB69CFF)
        case 7: return .white
        default: return Color(hex: 0x9E9E9E)
        }
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

// MARK: - フォント

enum AppFont {
    /// 見出し用フォント（Dela Gothic One）。Fonts フォルダに ttf を入れると自動で使われる
    static let displayName = "DelaGothicOne-Regular"

    static func registerBundledFonts() {
        for ext in ["ttf", "otf"] {
            for url in Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: nil) ?? [] {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
    }

    static let hasDisplayFont: Bool = UIFont(name: displayName, size: 12) != nil

    static func display(_ size: CGFloat) -> Font {
        hasDisplayFont
            ? .custom(displayName, fixedSize: size)
            : .system(size: size, weight: .black, design: .rounded)
    }

    static func body(_ size: CGFloat, weight: Font.Weight = .heavy) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

// MARK: - 太フチ＋ハード影の文字

struct PopText: View {
    let text: String
    var size: CGFloat
    var color: Color = Palette.yellow
    var stroke: CGFloat = 2
    /// 奥から順ではなく、手前から順に並べる（例: [.pink, .cyan, .black]）
    var shadows: [Color] = [.black]
    var shadowStep: CGFloat = 4

    var body: some View {
        ZStack {
            ForEach(Array(shadows.enumerated().reversed()), id: \.offset) { item in
                outlined(item.element)
                    .offset(x: shadowStep * CGFloat(item.offset + 1),
                            y: shadowStep * CGFloat(item.offset + 1))
            }
            outlined(color)
        }
        .fixedSize()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
    }

    private func outlined(_ fill: Color) -> some View {
        ZStack {
            ForEach(0..<8, id: \.self) { i in
                label
                    .foregroundStyle(Color.black)
                    .offset(x: cos(Double(i) * .pi / 4) * stroke,
                            y: sin(Double(i) * .pi / 4) * stroke)
            }
            label.foregroundStyle(fill)
        }
    }

    private var label: Text {
        Text(text).font(AppFont.display(size))
    }
}

// MARK: - ステッカー

struct Sticker: ViewModifier {
    var fill: Color
    var rotation: Double
    var corner: CGFloat

    func body(content: Content) -> some View {
        content
            .foregroundStyle(Color.black)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: corner).fill(fill))
            .overlay(RoundedRectangle(cornerRadius: corner).strokeBorder(Color.black, lineWidth: 3))
            .background(RoundedRectangle(cornerRadius: corner).fill(Color.black).offset(x: 3, y: 3))
            .rotationEffect(.degrees(rotation))
            .fixedSize()
    }
}

struct ChunkyPanel: ViewModifier {
    var fill: Color
    var corner: CGFloat
    var depth: CGFloat
    var border: CGFloat
    var borderColor: Color = .black

    func body(content: Content) -> some View {
        content
            .background(RoundedRectangle(cornerRadius: corner).fill(fill))
            .overlay(RoundedRectangle(cornerRadius: corner).strokeBorder(borderColor, lineWidth: border))
            .background(RoundedRectangle(cornerRadius: corner).fill(Color.black).offset(y: depth))
    }
}

extension View {
    func sticker(_ fill: Color, rotation: Double = 0, corner: CGFloat = 4) -> some View {
        modifier(Sticker(fill: fill, rotation: rotation, corner: corner))
    }

    func chunkyPanel(_ fill: Color, corner: CGFloat = 18, depth: CGFloat = 5,
                     border: CGFloat = 3, borderColor: Color = .black) -> some View {
        modifier(ChunkyPanel(fill: fill, corner: corner, depth: depth, border: border, borderColor: borderColor))
    }
}

// MARK: - 押すと沈むボタン

struct ChunkyButtonStyle: ButtonStyle {
    var fill: Color
    var textColor: Color = .black
    var corner: CGFloat = 16
    var depth: CGFloat = 5
    var border: CGFloat = 3

    func makeBody(configuration: Configuration) -> some View {
        ChunkyButtonBody(configuration: configuration, fill: fill, textColor: textColor,
                         corner: corner, depth: depth, border: border)
    }
}

private struct ChunkyButtonBody: View {
    let configuration: ButtonStyleConfiguration
    let fill: Color
    let textColor: Color
    let corner: CGFloat
    let depth: CGFloat
    let border: CGFloat
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        let pressed = configuration.isPressed
        configuration.label
            .foregroundStyle(isEnabled ? textColor : Color.white.opacity(0.5))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(RoundedRectangle(cornerRadius: corner).fill(isEnabled ? fill : Palette.panel))
            .overlay(RoundedRectangle(cornerRadius: corner).strokeBorder(Color.black, lineWidth: border))
            .offset(y: pressed ? depth : 0)
            .background(RoundedRectangle(cornerRadius: corner).fill(Color.black).offset(y: depth))
            .contentShape(Rectangle())
            .animation(.spring(response: 0.15, dampingFraction: 0.5), value: pressed)
    }
}

// MARK: - 図形

/// 爆発・バッジ用のギザギザ
struct Starburst: Shape {
    var points: Int = 12
    var innerRatio: CGFloat = 0.72

    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        var p = Path()
        for i in 0..<(points * 2) {
            let r = i.isMultiple(of: 2) ? outer : outer * innerRatio
            let a = Double(i) * .pi / Double(points) - .pi / 2
            let pt = CGPoint(x: c.x + cos(a) * r, y: c.y + sin(a) * r)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}

struct MineIcon: View {
    var color: Color = .black

    var body: some View {
        GeometryReader { g in
            let s = min(g.size.width, g.size.height)
            let c = CGPoint(x: g.size.width / 2, y: g.size.height / 2)
            ZStack {
                Path { p in
                    for i in 0..<8 {
                        let a = Double(i) * .pi / 4
                        p.move(to: CGPoint(x: c.x + cos(a) * s * 0.25, y: c.y + sin(a) * s * 0.25))
                        p.addLine(to: CGPoint(x: c.x + cos(a) * s * 0.48, y: c.y + sin(a) * s * 0.48))
                    }
                }
                .stroke(color, style: StrokeStyle(lineWidth: max(1.5, s * 0.1), lineCap: .round))
                Circle()
                    .fill(color)
                    .frame(width: s * 0.56, height: s * 0.56)
                    .position(c)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

// MARK: - 画面揺れ

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let x = amount * sin(animatableData * .pi * 6)
        let y = amount * 0.5 * sin(animatableData * .pi * 4)
        return ProjectionTransform(CGAffineTransform(translationX: x, y: y))
    }
}

// MARK: - 紙吹雪

struct ConfettiView: View {
    private struct Piece {
        let x: CGFloat
        let speed: CGFloat
        let size: CGFloat
        let color: Color
        let spin: Double
        let phase: Double
        let delay: Double
    }

    @State private var start = Date()
    @State private var pieces: [Piece] = (0..<70).map { _ in
        Piece(
            x: .random(in: 0...1),
            speed: .random(in: 140...320),
            size: .random(in: 8...16),
            color: [Palette.yellow, Palette.pink, Palette.cyan, Palette.lime, Palette.orange].randomElement()!,
            spin: .random(in: -8...8),
            phase: .random(in: 0...(2 * .pi)),
            delay: .random(in: 0...1.2)
        )
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { ctx, size in
                let t = timeline.date.timeIntervalSince(start)
                for p in pieces where t > p.delay {
                    let travel = CGFloat(t - p.delay) * p.speed
                    let y = travel.truncatingRemainder(dividingBy: size.height + 60) - 30
                    let x = p.x * size.width + CGFloat(sin(t * 2 + p.phase)) * 24
                    var c = ctx
                    c.translateBy(x: x, y: y)
                    c.rotate(by: .radians(t * p.spin))
                    let rect = CGRect(x: -p.size / 2, y: -p.size / 4, width: p.size, height: p.size / 2)
                    c.fill(Path(rect), with: .color(p.color))
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}
