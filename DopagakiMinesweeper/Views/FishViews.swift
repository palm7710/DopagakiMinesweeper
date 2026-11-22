import SwiftUI

// MARK: - 魚の絵（コードで描くオリジナル）

enum FishRenderer {
    /// 右向き・中心 p・体長 length で魚を描く
    static func draw(_ species: FishSpecies, in ctx: GraphicsContext, at p: CGPoint,
                     length: Double, facingRight: Bool, t: Double, phase: Double) {
        guard length > 1 else { return }
        var c = ctx
        c.translateBy(x: p.x, y: p.y)
        if !facingRight && species.shape != .jelly {
            c.scaleBy(x: -1, y: 1)
        }
        let L = length
        let swing = sin(t * 8 + phase * 6) * 0.22
        let line = max(1.2, L * 0.035)

        switch species.shape {
        case .slim:
            drawSlim(c, species, L: L, swing: swing, line: line)
        case .goldfish:
            drawGoldfish(c, species, L: L, swing: swing, line: line)
        case .guppy:
            drawGuppy(c, species, L: L, swing: swing, line: line)
        case .puffer:
            drawPuffer(c, species, L: L, swing: swing, line: line)
        case .angel:
            drawAngel(c, species, L: L, swing: swing, line: line)
        case .clown:
            drawClown(c, species, L: L, swing: swing, line: line)
        case .betta:
            drawBetta(c, species, L: L, swing: swing, line: line)
        case .whaleShark:
            drawWhaleShark(c, species, L: L, swing: swing, line: line)
        case .angler:
            drawAngler(c, species, L: L, swing: swing, line: line, t: t)
        case .oarfish:
            drawOarfish(c, species, L: L, line: line, t: t, phase: phase)
        case .jelly:
            drawJelly(c, species, L: L, line: line, t: t, phase: phase)
        }
    }

    // MARK: 部品

    private static func pt(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x, y: y) }

    private static func ellipse(_ cx: Double, _ cy: Double, _ w: Double, _ h: Double) -> Path {
        Path(ellipseIn: CGRect(x: cx - w / 2, y: cy - h / 2, width: w, height: h))
    }

    private static func fillStroke(_ c: GraphicsContext, _ path: Path, _ color: Color, line: Double) {
        c.fill(path, with: .color(color))
        c.stroke(path, with: .color(.black), lineWidth: line)
    }

    private static func eye(_ c: GraphicsContext, _ x: Double, _ y: Double, _ r: Double) {
        c.fill(ellipse(x, y, r * 2, r * 2), with: .color(.white))
        c.fill(ellipse(x + r * 0.25, y, r * 1.1, r * 1.1), with: .color(.black))
    }

    private static func tail(_ baseX: Double, length: Double, spread: Double, swing: Double) -> Path {
        var p = Path()
        p.move(to: pt(baseX, 0))
        p.addLine(to: pt(baseX - length, -spread + swing * spread * 2))
        p.addQuadCurve(to: pt(baseX - length, spread + swing * spread * 2),
                       control: pt(baseX - length * 0.7, swing * spread * 2))
        p.closeSubpath()
        return p
    }

    // MARK: 種類ごと

    private static func drawSlim(_ c: GraphicsContext, _ s: FishSpecies, L: Double, swing: Double, line: Double) {
        fillStroke(c, tail(-0.3 * L, length: 0.22 * L, spread: 0.16 * L, swing: swing), s.accent, line: line)
        let body = ellipse(0.07 * L, 0, 0.8 * L, 0.32 * L)
        fillStroke(c, body, s.color, line: line)
        var inner = c
        inner.clip(to: body)
        inner.fill(Path(CGRect(x: -0.3 * L, y: -0.06 * L, width: 0.6 * L, height: 0.07 * L)), with: .color(s.accent))
        eye(c, 0.32 * L, -0.03 * L, 0.06 * L)
    }

    private static func drawGoldfish(_ c: GraphicsContext, _ s: FishSpecies, L: Double, swing: Double, line: Double) {
        var fins = Path()
        fins.move(to: pt(-0.15 * L, 0))
        fins.addQuadCurve(to: pt(-0.55 * L, -0.32 * L + swing * 0.2 * L), control: pt(-0.3 * L, -0.4 * L))
        fins.addQuadCurve(to: pt(-0.4 * L, 0), control: pt(-0.45 * L, -0.08 * L))
        fins.addQuadCurve(to: pt(-0.55 * L, 0.32 * L + swing * 0.2 * L), control: pt(-0.45 * L, 0.08 * L))
        fins.addQuadCurve(to: pt(-0.15 * L, 0), control: pt(-0.3 * L, 0.4 * L))
        fillStroke(c, fins, s.accent.opacity(0.9), line: line)
        var dorsal = Path()
        dorsal.move(to: pt(-0.05 * L, -0.24 * L))
        dorsal.addQuadCurve(to: pt(0.2 * L, -0.25 * L), control: pt(0.05 * L, -0.42 * L))
        fillStroke(c, dorsal, s.accent, line: line)
        fillStroke(c, ellipse(0.1 * L, 0, 0.62 * L, 0.52 * L), s.color, line: line)
        eye(c, 0.28 * L, -0.06 * L, 0.07 * L)
    }

    private static func drawGuppy(_ c: GraphicsContext, _ s: FishSpecies, L: Double, swing: Double, line: Double) {
        var fan = Path()
        fan.move(to: pt(0, 0))
        fan.addLine(to: pt(-0.5 * L, -0.32 * L + swing * 0.15 * L))
        fan.addQuadCurve(to: pt(-0.5 * L, 0.32 * L + swing * 0.15 * L), control: pt(-0.62 * L, swing * 0.15 * L))
        fan.closeSubpath()
        c.fill(fan, with: .linearGradient(Gradient(colors: [s.accent, Palette.cyan, Palette.yellow]),
                                          startPoint: pt(0, -0.3 * L), endPoint: pt(-0.5 * L, 0.3 * L)))
        c.stroke(fan, with: .color(.black), lineWidth: line)
        fillStroke(c, ellipse(0.2 * L, 0, 0.5 * L, 0.24 * L), s.color, line: line)
        eye(c, 0.36 * L, -0.02 * L, 0.05 * L)
    }

    private static func drawPuffer(_ c: GraphicsContext, _ s: FishSpecies, L: Double, swing: Double, line: Double) {
        fillStroke(c, tail(-0.36 * L, length: 0.16 * L, spread: 0.12 * L, swing: swing), s.color, line: line)
        var spikes = Path()
        for k in 0..<14 {
            let a = Double(k) / 14 * 2 * .pi
            spikes.move(to: pt(cos(a) * 0.36 * L, sin(a) * 0.36 * L))
            spikes.addLine(to: pt(cos(a) * 0.5 * L, sin(a) * 0.5 * L))
        }
        c.stroke(spikes, with: .color(.black), lineWidth: line * 1.2)
        fillStroke(c, ellipse(0, 0, 0.76 * L, 0.72 * L), s.color, line: line)
        for (x, y) in [(-0.1, -0.15), (0.05, 0.18), (-0.18, 0.08), (0.12, -0.02)] {
            c.fill(ellipse(x * L, y * L, 0.07 * L, 0.07 * L), with: .color(s.accent))
        }
        eye(c, 0.2 * L, -0.1 * L, 0.09 * L)
    }

    private static func drawAngel(_ c: GraphicsContext, _ s: FishSpecies, L: Double, swing: Double, line: Double) {
        var fins = Path()
        fins.move(to: pt(0.05 * L, -0.25 * L))
        fins.addLine(to: pt(-0.25 * L + swing * 0.1 * L, -0.65 * L))
        fins.addLine(to: pt(-0.12 * L, -0.12 * L))
        fins.move(to: pt(0.05 * L, 0.25 * L))
        fins.addLine(to: pt(-0.25 * L + swing * 0.1 * L, 0.65 * L))
        fins.addLine(to: pt(-0.12 * L, 0.12 * L))
        fillStroke(c, fins, s.color, line: line)
        fillStroke(c, tail(-0.25 * L, length: 0.18 * L, spread: 0.14 * L, swing: swing), s.color, line: line)
        var body = Path()
        body.move(to: pt(0.45 * L, 0))
        body.addLine(to: pt(0.02 * L, -0.34 * L))
        body.addLine(to: pt(-0.26 * L, 0))
        body.addLine(to: pt(0.02 * L, 0.34 * L))
        body.closeSubpath()
        c.fill(body, with: .color(s.color))
        var inner = c
        inner.clip(to: body)
        for x in [-0.12, 0.08, 0.26] {
            inner.fill(Path(CGRect(x: x * L, y: -0.4 * L, width: 0.06 * L, height: 0.8 * L)), with: .color(s.accent))
        }
        c.stroke(body, with: .color(.black), lineWidth: line)
        eye(c, 0.28 * L, -0.04 * L, 0.05 * L)
    }

    private static func drawClown(_ c: GraphicsContext, _ s: FishSpecies, L: Double, swing: Double, line: Double) {
        fillStroke(c, tail(-0.34 * L, length: 0.18 * L, spread: 0.16 * L, swing: swing), s.color, line: line)
        let body = ellipse(0.05 * L, 0, 0.8 * L, 0.44 * L)
        c.fill(body, with: .color(s.color))
        var inner = c
        inner.clip(to: body)
        for x in [-0.25, 0.0, 0.25] {
            let band = Path(CGRect(x: x * L - 0.045 * L, y: -0.3 * L, width: 0.09 * L, height: 0.6 * L))
            inner.fill(band, with: .color(s.accent))
            inner.stroke(band, with: .color(.black), lineWidth: line * 0.7)
        }
        c.stroke(body, with: .color(.black), lineWidth: line)
        eye(c, 0.33 * L, -0.05 * L, 0.055 * L)
    }

    private static func drawBetta(_ c: GraphicsContext, _ s: FishSpecies, L: Double, swing: Double, line: Double) {
        var veil = Path()
        veil.move(to: pt(0.05 * L, -0.1 * L))
        veil.addQuadCurve(to: pt(-0.55 * L, -0.42 * L + swing * 0.2 * L), control: pt(-0.15 * L, -0.5 * L))
        veil.addQuadCurve(to: pt(-0.55 * L, 0.42 * L + swing * 0.2 * L), control: pt(-0.75 * L, swing * 0.3 * L))
        veil.addQuadCurve(to: pt(0.05 * L, 0.1 * L), control: pt(-0.15 * L, 0.5 * L))
        veil.closeSubpath()
        c.fill(veil, with: .linearGradient(Gradient(colors: [s.color, s.accent]),
                                           startPoint: pt(0, 0), endPoint: pt(-0.55 * L, 0)))
        c.stroke(veil, with: .color(.black), lineWidth: line)
        fillStroke(c, ellipse(0.18 * L, 0, 0.5 * L, 0.24 * L), s.color, line: line)
        eye(c, 0.34 * L, -0.03 * L, 0.05 * L)
    }

    private static func drawWhaleShark(_ c: GraphicsContext, _ s: FishSpecies, L: Double, swing: Double, line: Double) {
        var tailFin = Path()
        tailFin.move(to: pt(-0.4 * L, 0))
        tailFin.addLine(to: pt(-0.6 * L, -0.24 * L + swing * 0.1 * L))
        tailFin.addLine(to: pt(-0.52 * L, 0))
        tailFin.addLine(to: pt(-0.58 * L, 0.18 * L + swing * 0.1 * L))
        tailFin.closeSubpath()
        fillStroke(c, tailFin, s.color, line: line)
        var dorsal = Path()
        dorsal.move(to: pt(-0.05 * L, -0.12 * L))
        dorsal.addLine(to: pt(-0.15 * L, -0.26 * L))
        dorsal.addLine(to: pt(-0.2 * L, -0.1 * L))
        fillStroke(c, dorsal, s.color, line: line)
        let body = ellipse(0.02 * L, 0, 0.92 * L, 0.28 * L)
        c.fill(body, with: .color(s.color))
        var inner = c
        inner.clip(to: body)
        for i in 0..<14 {
            let x = -0.38 + Double(i % 7) * 0.11
            let y = i < 7 ? -0.06 : 0.04
            inner.fill(ellipse(x * L, y * L, 0.025 * L, 0.025 * L), with: .color(s.accent))
        }
        c.stroke(body, with: .color(.black), lineWidth: line)
        var mouth = Path()
        mouth.move(to: pt(0.42 * L, 0.04 * L))
        mouth.addLine(to: pt(0.3 * L, 0.05 * L))
        c.stroke(mouth, with: .color(.black), lineWidth: line)
        eye(c, 0.36 * L, -0.03 * L, 0.025 * L)
    }

    private static func drawAngler(_ c: GraphicsContext, _ s: FishSpecies, L: Double, swing: Double, line: Double, t: Double) {
        fillStroke(c, tail(-0.32 * L, length: 0.18 * L, spread: 0.14 * L, swing: swing), s.color, line: line)
        var stalk = Path()
        stalk.move(to: pt(0.05 * L, -0.26 * L))
        stalk.addQuadCurve(to: pt(0.45 * L, -0.45 * L), control: pt(0.15 * L, -0.6 * L))
        c.stroke(stalk, with: .color(.black), lineWidth: line)
        let glow = 0.6 + 0.4 * sin(t * 4)
        c.fill(ellipse(0.45 * L, -0.45 * L, 0.3 * L, 0.3 * L), with: .color(s.accent.opacity(0.25 * glow)))
        fillStroke(c, ellipse(0.45 * L, -0.45 * L, 0.1 * L, 0.1 * L), s.accent, line: line * 0.7)
        fillStroke(c, ellipse(0.02 * L, 0, 0.7 * L, 0.56 * L), s.color, line: line)
        var mouth = Path()
        mouth.move(to: pt(0.36 * L, -0.02 * L))
        mouth.addQuadCurve(to: pt(0.1 * L, 0.14 * L), control: pt(0.3 * L, 0.18 * L))
        c.stroke(mouth, with: .color(.black), lineWidth: line)
        for k in 0..<4 {
            let x = 0.14 + Double(k) * 0.055
            var tooth = Path()
            tooth.move(to: pt(x * L, 0.1 * L))
            tooth.addLine(to: pt((x + 0.025) * L, 0.03 * L))
            tooth.addLine(to: pt((x + 0.05) * L, 0.09 * L))
            c.fill(tooth, with: .color(.white))
        }
        eye(c, 0.2 * L, -0.12 * L, 0.05 * L)
    }

    private static func drawOarfish(_ c: GraphicsContext, _ s: FishSpecies, L: Double, line: Double, t: Double, phase: Double) {
        var spine = Path()
        var crest = Path()
        let steps = 24
        for k in 0...steps {
            let u = Double(k) / Double(steps)
            let x = (0.5 - u) * L
            let y = sin(u * 2 * .pi * 1.5 - t * 4 + phase * 6) * 0.06 * L * u
            if k == 0 {
                spine.move(to: pt(x, y))
                crest.move(to: pt(x, y - 0.06 * L))
            } else {
                spine.addLine(to: pt(x, y))
                crest.addLine(to: pt(x, y - 0.06 * L))
            }
        }
        let hue = (t * 0.15 + phase).truncatingRemainder(dividingBy: 1)
        let rainbow = Gradient(colors: (0..<6).map { i in
            Color(hue: (hue + Double(i) / 6).truncatingRemainder(dividingBy: 1), saturation: 0.55, brightness: 1)
        })
        c.stroke(crest, with: .color(s.accent), style: StrokeStyle(lineWidth: line * 1.6, lineCap: .round, lineJoin: .round))
        c.stroke(spine, with: .color(.black), style: StrokeStyle(lineWidth: 0.1 * L + line * 2, lineCap: .round, lineJoin: .round))
        c.stroke(spine, with: .linearGradient(rainbow, startPoint: pt(0.5 * L, 0), endPoint: pt(-0.5 * L, 0)),
                 style: StrokeStyle(lineWidth: 0.1 * L, lineCap: .round, lineJoin: .round))
        eye(c, 0.46 * L, -0.01 * L, 0.025 * L)
    }

    private static func drawJelly(_ c: GraphicsContext, _ s: FishSpecies, L: Double, line: Double, t: Double, phase: Double) {
        let pulse = 1 + 0.08 * sin(t * 3 + phase * 6)
        var tentacles = Path()
        for k in 0..<5 {
            let x0 = (-0.25 + Double(k) * 0.125) * L
            tentacles.move(to: pt(x0, 0))
            for j in 1...6 {
                let y = Double(j) * 0.11 * L
                let x = x0 + sin(t * 3 + Double(k) + Double(j) * 0.8) * 0.05 * L
                tentacles.addLine(to: pt(x, y))
            }
        }
        c.stroke(tentacles, with: .color(s.accent), style: StrokeStyle(lineWidth: line * 1.3, lineCap: .round))
        c.fill(ellipse(0, -0.12 * L, 0.9 * L * pulse, 0.7 * L), with: .color(s.color.opacity(0.18)))
        var dome = Path()
        dome.move(to: pt(-0.35 * L * pulse, 0))
        dome.addQuadCurve(to: pt(0.35 * L * pulse, 0), control: pt(0, -0.7 * L))
        dome.addQuadCurve(to: pt(-0.35 * L * pulse, 0), control: pt(0, 0.08 * L))
        dome.closeSubpath()
        c.fill(dome, with: .color(s.color.opacity(0.85)))
        c.stroke(dome, with: .color(.black), lineWidth: line)
        c.fill(ellipse(-0.08 * L, -0.18 * L, 0.06 * L, 0.06 * L), with: .color(.black))
        c.fill(ellipse(0.08 * L, -0.18 * L, 0.06 * L, 0.06 * L), with: .color(.black))
    }

    /// 卵（レア度の色で光る）
    static func drawEgg(_ rarity: FishRarity, in ctx: GraphicsContext, at p: CGPoint, size: Double, t: Double) {
        var c = ctx
        c.translateBy(x: p.x, y: p.y)
        c.rotate(by: .radians(sin(t * 5) * 0.15))
        if rarity >= .sr {
            c.fill(ellipse(0, 0, size * 1.6, size * 1.8), with: .color(rarity.color.opacity(0.3)))
        }
        let egg = ellipse(0, 0, size, size * 1.25)
        c.fill(egg, with: .color(Color(hex: 0xFFF6E0)))
        var inner = c
        inner.clip(to: egg)
        for (x, y) in [(-0.2, -0.25), (0.18, 0.05), (-0.1, 0.3), (0.25, -0.35)] {
            inner.fill(ellipse(x * size, y * size, size * 0.22, size * 0.22), with: .color(rarity.color))
        }
        c.stroke(egg, with: .color(.black), lineWidth: max(1.5, size * 0.06))
    }
}

// MARK: - 画面を泳ぐ魚

enum FishMotion {
    /// その時刻の位置・体長・向き
    static func state(of f: OwnedFish, t: Double, size: CGSize) -> (point: CGPoint, length: Double, facingRight: Bool) {
        let w = Double(size.width)
        let h = Double(size.height)
        let species = f.species
        let length = species.adultLength * f.stage.sizeScale
        let margin = length
        let span = w + margin * 2
        let speed = species.speed * (0.8 + 0.4 * f.seed2)
        var travel = speed * t + f.seed * span * 2
        if species.swim == .dash {
            // 止まりかけたり急いだりする（向きは変わらない）
            travel += speed * 0.4 * sin(t * 2 + f.seed * 9) / 2
        }
        let m = travel.truncatingRemainder(dividingBy: span * 2)
        let goingRight = m < span
        let x = (goingRight ? m : span * 2 - m) - margin

        let base = h * (0.12 + 0.76 * f.seed2)
        let wave: Double
        switch species.swim {
        case .straight: wave = sin(t * 1.2 + f.seed * 20) * 6
        case .wiggle: wave = sin(t * 2.5 + f.seed * 20) * 14
        case .float: wave = sin(t * 0.6 + f.seed * 20) * 40
        case .dash: wave = sin(t * 0.9 + f.seed * 20) * 10
        case .glide: wave = sin(t * 0.4 + f.seed * 20) * 24
        }
        return (CGPoint(x: x, y: base + wave), length, goingRight)
    }
}

struct FishTankLayer: View {
    let fish: [OwnedFish]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            Canvas { ctx, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                // 大きい魚を奥に描く
                for f in fish.sorted(by: { $0.species.adultLength > $1.species.adultLength }) {
                    let s = FishMotion.state(of: f, t: t, size: size)
                    FishRenderer.draw(f.species, in: ctx, at: s.point, length: s.length,
                                      facingRight: s.facingRight, t: t, phase: f.seed)
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

// MARK: - 一覧用のアイコン

struct FishIcon: View {
    let species: FishSpecies
    var egg = false
    var animate = true

    var body: some View {
        TimelineView(.animation(paused: !animate)) { timeline in
            Canvas { ctx, size in
                let t = animate ? timeline.date.timeIntervalSinceReferenceDate : 0
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                if egg {
                    FishRenderer.drawEgg(species.rarity, in: ctx, at: center, size: Double(size.height) * 0.6, t: t)
                } else {
                    let length = min(Double(size.width) * 0.8, species.adultLength)
                    let y = species.shape == .jelly ? Double(size.height) * 0.4 : Double(size.height) / 2
                    FishRenderer.draw(species, in: ctx, at: CGPoint(x: Double(size.width) / 2, y: y),
                                      length: length, facingRight: true, t: t, phase: 0)
                }
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - ショップの「水槽」タブ

struct AquariumPanel: View {
    let game: StimGame

    @AppStorage("fishInFront") private var fishInFront = false
    @State private var renaming: OwnedFish?
    @State private var newName = ""
    @State private var releasing: OwnedFish?

    var body: some View {
        VStack(spacing: 12) {
            if game.owns(.aquarium) {
                summary
                actions
                Toggle(isOn: $fishInFront) {
                    Text("盤面の前で泳がせる（うるさい）").font(AppFont.body(13))
                }
                .tint(Palette.cyan)
                .padding(.horizontal, 4)
                dexGrid
                if game.fish.isEmpty {
                    Text("まだ魚がいません。卵を買うか、盤面をクリアして卵を拾おう")
                        .font(AppFont.body(12, weight: .bold))
                        .foregroundStyle(Palette.lavender)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 12)
                }
                ForEach(game.fish) { f in
                    FishRow(fish: f, game: game,
                            onRename: {
                                newName = f.nickname
                                renaming = f
                            },
                            onRelease: { releasing = f })
                }
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "fish.fill")
                        .font(.system(size: 40, weight: .black))
                        .foregroundStyle(Palette.cyan)
                    Text("ショップで「水槽」を買うと魚が飼えます")
                        .font(AppFont.body(14))
                    Text("卵からかえして、マスを開けて育てよう。育った魚は画面を泳いで刺激を生みます")
                        .font(AppFont.body(12, weight: .bold))
                        .foregroundStyle(Palette.lavender)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 30)
            }
        }
        .alert("名前をつける", isPresented: Binding(get: { renaming != nil },
                                                set: { if !$0 { renaming = nil } })) {
            TextField("名前（12文字まで）", text: $newName)
            Button("決定") {
                if let f = renaming { game.renameFish(f.id, to: newName) }
                renaming = nil
            }
            Button("やめる", role: .cancel) { renaming = nil }
        }
        .confirmationDialog(releaseTitle,
                            isPresented: Binding(get: { releasing != nil },
                                                 set: { if !$0 { releasing = nil } }),
                            titleVisibility: .visible) {
            Button("放流する", role: .destructive) {
                if let f = releasing { game.releaseFish(f.id) }
                releasing = nil
            }
            Button("やめる", role: .cancel) { releasing = nil }
        }
    }

    private var releaseTitle: String {
        guard let f = releasing else { return "" }
        return "\(f.displayName)を海に帰しますか？（+\(game.releaseValue(f).stimText)）"
    }

    private var summary: some View {
        HStack(spacing: 8) {
            stat("飼っている", "\(game.fish.count) / \(game.fishCapacity)匹")
            stat("泳いでいる", "\(game.swimmingFish.count) / \(StimGame.maxSwimming)")
            stat("毎秒", "+\(game.fishPerSecond.stimText)")
        }
    }

    private var actions: some View {
        HStack(spacing: 8) {
            Button {
                game.buyEgg()
            } label: {
                VStack(spacing: 0) {
                    Text(game.hasTankSpace ? "卵を買う" : "水槽が満員").font(AppFont.body(13))
                    if game.hasTankSpace {
                        Text(game.eggPrice.stimText).font(AppFont.display(15))
                    }
                }
            }
            .buttonStyle(ChunkyButtonStyle(fill: Palette.yellow, corner: 14, depth: 4))
            .disabled(!game.hasTankSpace || game.stim < game.eggPrice)

            let hungry = game.hungryFishCount
            Button {
                game.feedAllFish()
            } label: {
                VStack(spacing: 0) {
                    Text("まとめてエサ").font(AppFont.body(13))
                    Text(hungry > 0 ? (game.fishFoodCost * Double(hungry)).stimText : "みんな満腹")
                        .font(AppFont.display(hungry > 0 ? 15 : 12))
                }
            }
            .buttonStyle(ChunkyButtonStyle(fill: Palette.lime, corner: 14, depth: 4))
            .disabled(hungry == 0 || game.stim < game.fishFoodCost * Double(hungry))
        }
        .frame(height: 56)
    }

    private var dexGrid: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("図鑑 \(game.dex.count) / \(FishSpecies.allCases.count)")
                .font(AppFont.display(14))
                .foregroundStyle(Palette.yellow)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 6), spacing: 6) {
                ForEach(FishSpecies.allCases) { sp in
                    let found = game.dex.contains(sp)
                    ZStack {
                        RoundedRectangle(cornerRadius: 8).fill(found ? Palette.well : Palette.panel.opacity(0.5))
                        if found {
                            FishIcon(species: sp, animate: false).padding(3)
                        } else {
                            Text("？").font(AppFont.display(14)).foregroundStyle(Palette.lavender)
                        }
                    }
                    .frame(height: 40)
                    .overlay(RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(found ? sp.rarity.color : Color.black, lineWidth: 2))
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(found ? "\(sp.name) \(sp.rarity.label)" : "未発見")
                }
            }
        }
        .padding(10)
        .chunkyPanel(Palette.panel, corner: 14, depth: 4)
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(label).font(AppFont.body(10)).foregroundStyle(Palette.lavender)
            Text(value).font(AppFont.display(14)).foregroundStyle(Palette.yellow)
                .lineLimit(1).minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .chunkyPanel(Palette.well, corner: 12, depth: 3)
    }
}

private struct FishRow: View {
    let fish: OwnedFish
    let game: StimGame
    var onRename: () -> Void
    var onRelease: () -> Void

    var body: some View {
        let isEgg = fish.stage == .egg
        HStack(spacing: 10) {
            FishIcon(species: fish.species, egg: isEgg)
                .frame(width: 60, height: 44)
                .background(RoundedRectangle(cornerRadius: 10).fill(Palette.well))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(fish.species.rarity.color, lineWidth: 2))

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(fish.displayName).font(AppFont.display(14)).lineLimit(1).minimumScaleFactor(0.7)
                    Text(fish.species.rarity.label)
                        .font(AppFont.body(10))
                        .sticker(fish.species.rarity.color, corner: 5)
                }
                bar(label: isEgg ? "ふ化まで" : fish.stage.label,
                    value: fish.stageProgress, color: Palette.cyan)
                bar(label: fish.hunger > 0 ? "おなか" : "ぺこぺこ",
                    value: fish.hunger, color: fish.hunger < 0.3 ? Palette.pink : Palette.lime)
            }

            Spacer(minLength: 2)

            VStack(spacing: 6) {
                Button {
                    game.feedFish(fish.id)
                } label: {
                    Text("エサ").font(AppFont.body(12))
                }
                .buttonStyle(ChunkyButtonStyle(fill: Palette.lime, corner: 10, depth: 3))
                .frame(width: 52, height: 30)
                .disabled(game.stim < game.fishFoodCost)
                .accessibilityLabel("\(fish.displayName)にエサ \(Int(game.fishFoodCost))")

                HStack(spacing: 4) {
                    if !isEgg {
                        Button {
                            game.toggleSwimming(fish.id)
                        } label: {
                            Image(systemName: fish.swimming ? "eye.fill" : "eye.slash.fill")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(fish.swimming ? Palette.cyan : Palette.lavender)
                        .frame(width: 24, height: 24)
                        .accessibilityLabel(fish.swimming ? "泳がせるのをやめる" : "画面で泳がせる")
                    }
                    Menu {
                        if !isEgg {
                            Button("名前をつける", action: onRename)
                        }
                        Button("放流する（+\(game.releaseValue(fish).stimText)）", role: .destructive, action: onRelease)
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Palette.lavender)
                            .frame(width: 24, height: 24)
                    }
                    .accessibilityLabel("その他")
                }
            }
        }
        .padding(10)
        .chunkyPanel(Palette.panel, corner: 14, depth: 4)
    }

    private func bar(label: String, value: Double, color: Color) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(AppFont.body(10))
                .foregroundStyle(Palette.lavender)
                .frame(width: 44, alignment: .leading)
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Palette.well)
                    Capsule().fill(color).frame(width: max(0, g.size.width * min(1, value)))
                }
            }
            .frame(height: 6)
        }
    }
}
