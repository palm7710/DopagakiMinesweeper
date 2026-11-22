import SwiftUI

// 刺激モードで買うと画面に増えていく演出たち

// MARK: - DVDロゴ

/// 画面中をはねまわるロゴ。壁に当たるたびに onBounce(角かどうか) を呼ぶ
struct DVDLogoLayer: View {
    /// 何個目のロゴか（速さと出だしをずらす）
    var index: Int = 0
    var onBounce: (Bool) -> Void

    @State private var start = Date()
    @State private var lastCorner = Date.distantPast
    private let logo = CGSize(width: 96, height: 46)
    private var vx: Double { 95 + Double(index) * 17 }
    private var vy: Double { 70 + Double(index) * 11 }
    private static let colors = [Palette.pink, Palette.cyan, Palette.yellow, Palette.lime, Palette.orange, Palette.lavender]

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSince(start) + Double(index) * 3.7
                let rx = max(1, Double(geo.size.width - logo.width))
                let ry = max(1, Double(geo.size.height - logo.height))
                let dx = t * vx
                let dy = t * vy
                let xb = Int(dx / rx)
                let yb = Int(dy / ry)
                DVDBadge(color: Self.colors[(xb + yb + index) % Self.colors.count])
                    .frame(width: logo.width, height: logo.height)
                    .position(x: CGFloat(Self.tri(dx, rx)) + logo.width / 2, y: CGFloat(Self.tri(dy, ry)) + logo.height / 2)
                    .onChange(of: xb) { _, _ in bounce(corner: Self.nearEdge(dy, ry)) }
                    .onChange(of: yb) { _, _ in bounce(corner: Self.nearEdge(dx, rx)) }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func bounce(corner: Bool) {
        if corner {
            // 角では x と y の両方が同時に跳ね返るので、2回数えないようにする
            guard Date().timeIntervalSince(lastCorner) > 0.5 else { return }
            lastCorner = Date()
        }
        onBounce(corner)
    }

    /// 0 → r → 0 を行き来する三角波
    private static func tri(_ d: Double, _ r: Double) -> Double {
        let m = d.truncatingRemainder(dividingBy: 2 * r)
        return m <= r ? m : 2 * r - m
    }

    private static func nearEdge(_ d: Double, _ r: Double) -> Bool {
        let p = tri(d, r)
        return p < 10 || p > r - 10
    }
}

private struct DVDBadge: View {
    let color: Color

    var body: some View {
        VStack(spacing: -3) {
            Text("DOPA")
                .font(AppFont.display(26))
                .foregroundStyle(color)
            Ellipse()
                .fill(color)
                .frame(width: 70, height: 13)
                .overlay(
                    Text("VIDEO")
                        .font(.system(size: 8, weight: .black))
                        .tracking(3)
                        .foregroundStyle(.black)
                )
        }
        .shadow(color: color.opacity(0.8), radius: 8)
        .animation(.easeOut(duration: 0.15), value: color)
    }
}

// MARK: - ニュース速報

struct NewsTicker: View {
    private static let line = [
        "【速報】地雷、ついに意思を持つ",
        "専門家「旗は立てすぎても困らない」",
        "$DOPA 株、理由なく上昇",
        "全国で「あと1回だけ」が多発",
        "研究：マスを開けると脳汁が出る（たぶん）",
        "天気：午後から絵文字が降るでしょう",
        "ドパガキ人口、過去最多を更新",
        "【悲報】連続クリア、また途切れる",
        "街の声「最後に空を見たのはいつだろう」"
    ].joined(separator: "　◆　") + "　◆　"

    /// 流れる速さ（pt/秒）
    var speed: Double = 60

    @State private var start = Date()
    @State private var width: CGFloat = 1

    var body: some View {
        HStack(spacing: 0) {
            Text("速報")
                .font(AppFont.display(13))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .frame(maxHeight: .infinity)
                .background(Palette.pink)
            GeometryReader { _ in
                TimelineView(.animation) { timeline in
                    let t = timeline.date.timeIntervalSince(start)
                    let offset = -CGFloat((t * speed).truncatingRemainder(dividingBy: Double(width)))
                    HStack(spacing: 0) {
                        tickerText
                            .background(GeometryReader { g in
                                Color.clear.onAppear { width = max(1, g.size.width) }
                            })
                        tickerText
                    }
                    .offset(x: offset)
                    .frame(maxHeight: .infinity)
                }
            }
            .clipped()
        }
        .frame(height: 26)
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Palette.yellow, lineWidth: 2))
        .accessibilityLabel("ニュース速報")
    }

    private var tickerText: some View {
        Text(Self.line)
            .font(AppFont.body(13))
            .foregroundStyle(Palette.yellow)
            .lineLimit(1)
            .fixedSize()
    }
}

// MARK: - ゲーム実況（すみっこで流れる横スクロールゲーム）

struct RunnerStream: View {
    @State private var start = Date()
    @State private var viewers = Int.random(in: 1_200...9_000)

    var body: some View {
        VStack(spacing: 0) {
            TimelineView(.animation) { timeline in
                Canvas { ctx, size in
                    Self.draw(ctx, size: size, t: timeline.date.timeIntervalSince(start))
                }
            }
            .frame(width: 140, height: 84)

            HStack(spacing: 4) {
                Circle().fill(Color.red).frame(width: 6, height: 6)
                Text("LIVE").foregroundStyle(.red)
                Spacer(minLength: 0)
                Image(systemName: "eye.fill")
                Text(viewers.formatted())
            }
            .font(.system(size: 9, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .frame(width: 140, height: 16)
            .background(Color.black)
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.black, lineWidth: 3))
        .shadow(color: .black.opacity(0.5), radius: 0, x: 3, y: 3)
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1.5))
                viewers = max(300, viewers + Int.random(in: -120...180))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private static func draw(_ ctx: GraphicsContext, size: CGSize, t: Double) {
        let w = Double(size.width)
        let h = Double(size.height)
        let groundY = h * 0.78

        // 空
        ctx.fill(Path(CGRect(origin: .zero, size: size)),
                 with: .linearGradient(Gradient(colors: [Palette.tile, Palette.pink]),
                                       startPoint: .zero, endPoint: CGPoint(x: 0, y: h)))
        // 遠くのビル
        for i in 0..<6 {
            let bw = 18.0
            let x = (Double(i) * 28 - (t * 20).truncatingRemainder(dividingBy: 28)) - 10
            let bh = 18 + Double((i * 7) % 5) * 5
            ctx.fill(Path(CGRect(x: x, y: groundY - bh, width: bw, height: bh)),
                     with: .color(Palette.tileDark.opacity(0.8)))
        }
        // 地面
        ctx.fill(Path(CGRect(x: 0, y: groundY, width: w, height: h - groundY)), with: .color(Palette.well))
        for i in 0..<8 {
            let x = Double(i) * 24 - (t * 120).truncatingRemainder(dividingBy: 24)
            ctx.fill(Path(CGRect(x: x, y: groundY + 4, width: 12, height: 3)), with: .color(Palette.yellow))
        }

        // コイン
        for i in 0..<4 {
            let period = 2.2
            let p = ((t + Double(i) * 0.55) / period).truncatingRemainder(dividingBy: 1)
            let x = w + 10 - p * (w + 20)
            let y = groundY - 34 + sin(Double(i) * 1.7) * 6
            ctx.fill(Path(ellipseIn: CGRect(x: x - 4, y: y - 4, width: 8, height: 8)), with: .color(Palette.yellow))
        }

        // 障害物と、それを飛び越える主人公
        let period = 1.6
        let phase = (t / period).truncatingRemainder(dividingBy: 1)
        let ox = w + 10 - phase * (w + 30)
        ctx.fill(Path(roundedRect: CGRect(x: ox, y: groundY - 14, width: 12, height: 14), cornerRadius: 2),
                 with: .color(Palette.lime))

        let runnerX = 30.0
        let hitPhase = (w + 10 - runnerX) / (w + 30)
        let jumpWindow = 0.22
        var jump = 0.0
        let dp = phase - (hitPhase - jumpWindow)
        if dp >= 0 && dp <= jumpWindow * 2 {
            jump = sin(dp / (jumpWindow * 2) * .pi) * 26
        }
        let by = groundY - 18 - jump
        let leg = jump > 0 ? 0 : sin(t * 22) * 4
        // 足
        ctx.stroke(Path { p in
            p.move(to: CGPoint(x: runnerX - 2, y: by + 12))
            p.addLine(to: CGPoint(x: runnerX - 2 + leg, y: by + 18))
            p.move(to: CGPoint(x: runnerX + 3, y: by + 12))
            p.addLine(to: CGPoint(x: runnerX + 3 - leg, y: by + 18))
        }, with: .color(.black), lineWidth: 3)
        // 体と頭
        ctx.fill(Path(roundedRect: CGRect(x: runnerX - 5, y: by, width: 11, height: 13), cornerRadius: 3),
                 with: .color(Palette.cyan))
        ctx.fill(Path(ellipseIn: CGRect(x: runnerX - 5, y: by - 10, width: 11, height: 11)), with: .color(Palette.yellow))
        ctx.fill(Path(CGRect(x: runnerX + 1, y: by - 7, width: 3, height: 3)), with: .color(.black))

        // スコア
        ctx.draw(Text("SCORE \(Int(t * 137))").font(.system(size: 9, weight: .black, design: .monospaced))
                    .foregroundColor(.white),
                 at: CGPoint(x: 6, y: 8), anchor: .leading)
    }
}

// MARK: - 株チャート

struct StockWidget: View {
    let history: [Double]
    let price: Double
    var holdings: Int = 1

    private var up: Bool {
        guard history.count >= 2 else { return true }
        return history[history.count - 1] >= history[history.count - 2]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Text(holdings > 1 ? "$DOPA ×\(holdings)" : "$DOPA").font(.system(size: 10, weight: .black, design: .rounded))
                Spacer(minLength: 0)
                Image(systemName: up ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                    .font(.system(size: 8))
                Text(price.formatted(.number.precision(.fractionLength(1))))
                    .font(.system(size: 10, weight: .black, design: .monospaced))
            }
            .foregroundStyle(up ? Palette.lime : Palette.pink)

            GeometryReader { g in
                let lo = (history.min() ?? 0) - 2
                let hi = (history.max() ?? 1) + 2
                Path { p in
                    for (i, v) in history.enumerated() {
                        let x = g.size.width * CGFloat(i) / CGFloat(max(1, history.count - 1))
                        let y = g.size.height * (1 - CGFloat((v - lo) / (hi - lo)))
                        if i == 0 { p.move(to: CGPoint(x: x, y: y)) } else { p.addLine(to: CGPoint(x: x, y: y)) }
                    }
                }
                .stroke(up ? Palette.lime : Palette.pink, style: StrokeStyle(lineWidth: 1.5, lineJoin: .round))
            }
        }
        .padding(6)
        .frame(width: 112, height: 58)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.85)))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Palette.divider, lineWidth: 2))
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("DOPA 株価 \(Int(price))")
    }
}

// MARK: - 背景系

struct EmojiRainLayer: View {
    private struct Drop {
        let emoji: String
        let x: Double
        let speed: Double
        let size: Double
        let phase: Double
        let spin: Double
    }

    /// 描く絵文字の数（最大100）
    var count: Int = 24

    @State private var start = Date()
    @State private var drops: [Drop] = (0..<100).map { _ in
        Drop(emoji: ["🧠", "💥", "🔥", "💰", "✨", "😂", "💣", "🚩", "🎰", "📈", "❤️", "👀"].randomElement()!,
             x: .random(in: 0...1),
             speed: .random(in: 40...110),
             size: .random(in: 16...30),
             phase: .random(in: 0...1),
             spin: .random(in: -2...2))
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { ctx, size in
                let t = timeline.date.timeIntervalSince(start)
                let width = Double(size.width)
                let travel = Double(size.height) + 60
                for d in drops.prefix(count) {
                    let y: Double = (t * d.speed + d.phase * travel).truncatingRemainder(dividingBy: travel) - 30
                    let x: Double = d.x * width + sin(t + d.phase * 6) * 12
                    var c = ctx
                    c.translateBy(x: x, y: y)
                    c.rotate(by: .radians(t * d.spin))
                    c.draw(Text(d.emoji).font(.system(size: CGFloat(d.size))), at: .zero)
                }
            }
        }
        .opacity(0.5)
        .allowsHitTesting(false)
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

struct RainLayer: View {
    /// 雨粒の数（最大280）
    var count: Int = 70

    @State private var start = Date()
    @State private var drops: [(x: Double, speed: Double, phase: Double, len: Double)] = (0..<280).map { _ in
        (.random(in: 0...1.2), .random(in: 500...800), .random(in: 0...1), .random(in: 10...22))
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { ctx, size in
                let t = timeline.date.timeIntervalSince(start)
                let width = Double(size.width)
                let travel = Double(size.height) + 40
                var path = Path()
                for d in drops.prefix(count) {
                    let y: Double = (t * d.speed + d.phase * travel).truncatingRemainder(dividingBy: travel) - 20
                    let x: Double = d.x * width - y * 0.18
                    path.move(to: CGPoint(x: x, y: y))
                    path.addLine(to: CGPoint(x: x - d.len * 0.18, y: y + d.len))
                }
                ctx.stroke(path, with: .color(Palette.cyan.opacity(0.35)), lineWidth: 1.2)
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

struct GamingBackground: View {
    /// 色が回る速さ（度/秒）
    var speed: Double = 90

    @State private var start = Date()

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSince(start)
            LinearGradient(colors: [Palette.pink, Palette.cyan, Palette.lime, Palette.yellow, Palette.pink],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .hueRotation(.degrees(t * speed))
                .opacity(0.45)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - 通知

struct NotificationBanner: View {
    let note: StimNotification

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: note.icon)
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(.black)
                .frame(width: 32, height: 32)
                .background(RoundedRectangle(cornerRadius: 8).fill(note.color))
            VStack(alignment: .leading, spacing: 1) {
                HStack {
                    Text(note.app).font(AppFont.body(12))
                    Spacer()
                    Text("いま").font(AppFont.body(11, weight: .bold)).foregroundStyle(Palette.lavender)
                }
                Text(note.message)
                    .font(AppFont.body(13, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Text("+\(note.reward.stimText)")
                .font(AppFont.display(13))
                .sticker(Palette.yellow, rotation: 6)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 16).fill(Palette.panel.opacity(0.97)))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.black, lineWidth: 3))
        .shadow(color: .black.opacity(0.5), radius: 0, x: 0, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityHint("タップで刺激をもらう")
    }
}

// MARK: - ガチャ結果

struct GachaOverlay: View {
    let result: GachaResult
    @State private var spin = 0.0

    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
            Starburst(points: 16)
                .fill(result.rarity.color)
                .overlay(Starburst(points: 16).stroke(Color.black, lineWidth: 4))
                .frame(width: 280, height: 280)
                .rotationEffect(.degrees(spin))
            VStack(spacing: 6) {
                PopText(text: result.rarity.rawValue, size: result.rarity == .ssr ? 84 : 64,
                        color: .white, stroke: 3, shadows: [Palette.pink, .black], shadowStep: 4)
                Text("+\(result.reward.stimText) 刺激")
                    .font(AppFont.display(20))
                    .sticker(Palette.yellow, rotation: -4)
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) { spin = 360 }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("ガチャ \(result.rarity.rawValue) \(Int(result.reward)) 刺激")
    }
}
