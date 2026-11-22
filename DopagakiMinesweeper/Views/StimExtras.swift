import SwiftUI

// 刺激モードの追加演出：弾幕、フェス、投げ銭、ペット、鳥、ヒビ、スロット、広告、ログボ、実績

// MARK: - 弾幕コメント

struct DanmakuLayer: View {
    let comments: [Danmaku]

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                let now = timeline.date
                let laneHeight = max(24, (geo.size.height - 240) / 10)
                ZStack(alignment: .topLeading) {
                    Color.clear
                    ForEach(comments) { c in
                        let elapsed = now.timeIntervalSince(c.born)
                        if elapsed >= 0 {
                            Text(c.text)
                                .font(.system(size: c.size, weight: .heavy, design: .rounded))
                                .foregroundStyle(c.color)
                                .shadow(color: .black, radius: 0, x: 1.5, y: 1.5)
                                .fixedSize()
                                .offset(x: geo.size.width + 10 - CGFloat(elapsed * c.speed),
                                        y: 110 + CGFloat(c.lane) * laneHeight)
                        }
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - 脳汁2倍フェス

struct FestBanner: View {
    let active: Bool
    let seconds: Int

    var body: some View {
        Group {
            if active {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                    Text("脳汁2倍フェス開催中！")
                    Spacer(minLength: 4)
                    Text("残り \(Self.mmss(seconds))").monospacedDigit()
                }
                .font(AppFont.display(14))
                .foregroundStyle(.black)
                .padding(.horizontal, 10)
                .frame(height: 30)
                .chunkyPanel(Palette.yellow, corner: 10, depth: 3)
                .phaseAnimator([1.0, 1.03]) { view, scale in
                    view.scaleEffect(scale)
                } animation: { _ in .easeInOut(duration: 0.3) }
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                    Text("次の脳汁2倍フェスまで")
                    Text(Self.mmss(seconds))
                        .monospacedDigit()
                        .foregroundStyle(Palette.yellow)
                }
                .font(AppFont.body(12))
                .foregroundStyle(Palette.lavender)
                .frame(height: 20)
            }
        }
        .accessibilityElement(children: .combine)
    }

    static func mmss(_ s: Int) -> String {
        String(format: "%02d:%02d", s / 60, s % 60)
    }
}

// MARK: - 投げ銭

struct SuperChatCard: View {
    let chat: SuperChat

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.white.opacity(0.85))
                    .frame(width: 22, height: 22)
                    .overlay(Image(systemName: "person.fill").font(.system(size: 11)).foregroundStyle(Color.black))
                VStack(alignment: .leading, spacing: 0) {
                    Text(chat.name).font(AppFont.body(11)).lineLimit(1)
                    Text("¥\(chat.yen.formatted())").font(AppFont.display(15))
                }
                Spacer(minLength: 4)
                Text("+\(chat.reward.stimText)")
                    .font(AppFont.body(12))
                    .sticker(.white, rotation: 4)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(chat.color)

            Text(chat.message)
                .font(AppFont.body(12, weight: .bold))
                .lineLimit(1)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(chat.color.opacity(0.7))
        }
        .foregroundStyle(.black)
        .frame(width: 210)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.black, lineWidth: 3))
        .shadow(color: .black.opacity(0.5), radius: 0, x: 3, y: 3)
        .accessibilityElement(children: .combine)
        .accessibilityHint("タップで受け取る")
    }
}

// MARK: - 謎の生き物

struct PetCreature: View {
    let hunger: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// 2: ごきげん 1: ふつう 0: はらぺこ
    private var mood: Int {
        if hunger > 0.6 { return 2 }
        return hunger >= 0.3 ? 1 : 0
    }

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let hop = mood == 0 ? 0 : -abs(sin(t * (mood == 2 ? 5 : 2.5))) * 4
            let shiver = mood == 0 ? sin(t * 30) * 1.5 : 0
            Canvas { ctx, size in
                Self.draw(ctx, size: size, mood: mood, t: t)
            }
            .offset(x: CGFloat(shiver), y: CGFloat(hop))
        }
        .frame(width: 48, height: 42)
        .accessibilityHidden(true)
    }

    private static func draw(_ ctx: GraphicsContext, size: CGSize, mood: Int, t: Double) {
        let cx = Double(size.width) / 2
        let cy = Double(size.height) / 2 + 4
        let bodyColor = mood == 0 ? Color(hex: 0x8FA8FF) : Palette.lavender

        // アンテナ
        var antenna = Path()
        antenna.move(to: CGPoint(x: cx, y: cy - 15))
        antenna.addQuadCurve(to: CGPoint(x: cx + 6, y: cy - 23), control: CGPoint(x: cx - 2, y: cy - 22))
        ctx.stroke(antenna, with: .color(.black), lineWidth: 2)
        ctx.fill(Path(ellipseIn: CGRect(x: cx + 3, y: cy - 27, width: 7, height: 7)), with: .color(Palette.pink))

        // 体
        let body = Path(ellipseIn: CGRect(x: cx - 20, y: cy - 16, width: 40, height: 30))
        ctx.fill(body, with: .color(bodyColor))
        ctx.stroke(body, with: .color(.black), lineWidth: 2.5)

        // 目
        for ex in [cx - 8, cx + 8] {
            let ey = cy - 3
            if mood == 2 {
                var eye = Path()
                eye.move(to: CGPoint(x: ex - 3.5, y: ey + 1))
                eye.addQuadCurve(to: CGPoint(x: ex + 3.5, y: ey + 1), control: CGPoint(x: ex, y: ey - 5))
                ctx.stroke(eye, with: .color(.black), lineWidth: 2)
            } else {
                ctx.fill(Path(ellipseIn: CGRect(x: ex - 2.8, y: ey - 2.8, width: 5.6, height: 5.6)), with: .color(.black))
            }
            if mood == 0 {
                let drop = (t * 14 + ex).truncatingRemainder(dividingBy: 8)
                ctx.fill(Path(ellipseIn: CGRect(x: ex - 1.5, y: ey + 3 + drop, width: 3, height: 5)), with: .color(Palette.cyan))
            }
        }

        // 口
        var mouth = Path()
        switch mood {
        case 2:
            mouth.move(to: CGPoint(x: cx - 5, y: cy + 4))
            mouth.addQuadCurve(to: CGPoint(x: cx + 5, y: cy + 4), control: CGPoint(x: cx, y: cy + 11))
            mouth.closeSubpath()
            ctx.fill(mouth, with: .color(Palette.pink))
            ctx.stroke(mouth, with: .color(.black), lineWidth: 1.5)
        case 1:
            mouth.move(to: CGPoint(x: cx - 3, y: cy + 6))
            mouth.addLine(to: CGPoint(x: cx + 3, y: cy + 6))
            ctx.stroke(mouth, with: .color(.black), lineWidth: 1.5)
        default:
            mouth.move(to: CGPoint(x: cx - 4, y: cy + 8))
            mouth.addQuadCurve(to: CGPoint(x: cx + 4, y: cy + 8), control: CGPoint(x: cx, y: cy + 3))
            ctx.stroke(mouth, with: .color(.black), lineWidth: 1.5)
        }
    }
}

// MARK: - 勉強しろ鳥

struct StudyBirdView: View {
    let line: String
    let anger: Int
    var count: Int = 1
    var onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            VStack(alignment: .trailing, spacing: 8) {
                Text(line)
                    .font(AppFont.body(14))
                    .foregroundStyle(.black)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.black, lineWidth: 3))
                    .id(line)
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
                Button(action: onDismiss) {
                    Text("あとで").font(AppFont.body(14))
                }
                .buttonStyle(ChunkyButtonStyle(fill: Palette.lime, corner: 12, depth: 4))
                .frame(width: 96, height: 40)
            }
            HStack(spacing: -34) {
                ForEach(0..<max(1, count), id: \.self) { _ in
                    StudyBirdFigure(anger: anger)
                        .frame(width: 80, height: 88)
                }
            }
            .scaleEffect(count > 1 ? 0.8 : 1, anchor: .bottomTrailing)
        }
        .frame(maxWidth: count > 1 ? 340 : 290)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: line)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("勉強しろ鳥：\(line)")
    }
}

/// 眼鏡をかけた、まるい教育熱心な鳥
struct StudyBirdFigure: View {
    let anger: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let shake = sin(t * 40) * Double(min(anger, 4))
            let bob = sin(t * 3) * 2
            Canvas { ctx, size in
                Self.draw(ctx, size: size, anger: anger)
            }
            .offset(x: CGFloat(shake), y: CGFloat(bob))
        }
        .accessibilityHidden(true)
    }

    private static func draw(_ ctx: GraphicsContext, size: CGSize, anger: Int) {
        let w = Double(size.width)
        let h = Double(size.height)
        let cx = w / 2
        let cy = h * 0.52
        let bodyColor = anger >= 2 ? Palette.pink : Palette.orange

        // 足
        for fx in [cx - 10, cx + 10] {
            var foot = Path()
            foot.move(to: CGPoint(x: fx, y: cy + 30))
            foot.addLine(to: CGPoint(x: fx, y: cy + 38))
            foot.addLine(to: CGPoint(x: fx + 6, y: cy + 40))
            ctx.stroke(foot, with: .color(Palette.yellow), lineWidth: 3)
        }
        // 体
        let body = Path(ellipseIn: CGRect(x: cx - 32, y: cy - 34, width: 64, height: 68))
        ctx.fill(body, with: .color(bodyColor))
        ctx.stroke(body, with: .color(.black), lineWidth: 3)
        // おなか
        ctx.fill(Path(ellipseIn: CGRect(x: cx - 18, y: cy + 2, width: 36, height: 28)), with: .color(.white))
        // 羽
        for side in [-1.0, 1.0] {
            let wing = Path(ellipseIn: CGRect(x: cx + side * 30 - 8, y: cy - 4, width: 16, height: 26))
            ctx.fill(wing, with: .color(bodyColor))
            ctx.stroke(wing, with: .color(.black), lineWidth: 2.5)
        }
        // 眼鏡と目
        for ex in [cx - 12, cx + 12] {
            let ey = cy - 12
            ctx.fill(Path(ellipseIn: CGRect(x: ex - 9, y: ey - 9, width: 18, height: 18)), with: .color(.white))
            ctx.stroke(Path(ellipseIn: CGRect(x: ex - 10, y: ey - 10, width: 20, height: 20)), with: .color(.black), lineWidth: 3)
            ctx.fill(Path(ellipseIn: CGRect(x: ex - 3.5, y: ey - 2, width: 7, height: 7)), with: .color(.black))
            if anger > 0 {
                var brow = Path()
                let tilt = ex < cx ? 1.0 : -1.0
                brow.move(to: CGPoint(x: ex - 9, y: ey - 14 - 3 * tilt))
                brow.addLine(to: CGPoint(x: ex + 9, y: ey - 14 + 3 * tilt))
                ctx.stroke(brow, with: .color(.black), lineWidth: 3)
            }
        }
        var bridge = Path()
        bridge.move(to: CGPoint(x: cx - 2, y: cy - 12))
        bridge.addLine(to: CGPoint(x: cx + 2, y: cy - 12))
        ctx.stroke(bridge, with: .color(.black), lineWidth: 3)
        // くちばし
        var beak = Path()
        beak.move(to: CGPoint(x: cx - 6, y: cy - 2))
        beak.addLine(to: CGPoint(x: cx + 6, y: cy - 2))
        beak.addLine(to: CGPoint(x: cx, y: cy + 7))
        beak.closeSubpath()
        ctx.fill(beak, with: .color(Palette.yellow))
        ctx.stroke(beak, with: .color(.black), lineWidth: 2)
    }
}

// MARK: - 画面のヒビ

struct CrackLayer: View {
    let cracks: [ScreenCrack]

    var body: some View {
        Canvas { ctx, size in
            for crack in cracks {
                let path = Self.crackPath(crack, in: size)
                ctx.stroke(path, with: .color(.black.opacity(0.55)), lineWidth: 3)
                ctx.stroke(path, with: .color(.white.opacity(0.9)), lineWidth: 1.2)
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private static func crackPath(_ crack: ScreenCrack, in size: CGSize) -> Path {
        var rng = SplitMix64(seed: crack.seed)
        let cx = crack.x * Double(size.width)
        let cy = crack.y * Double(size.height)
        var path = Path()
        let rays = Int.random(in: 7...11, using: &rng)
        for k in 0..<rays {
            var angle = Double(k) / Double(rays) * 2 * .pi + Double.random(in: -0.25...0.25, using: &rng)
            var x = cx
            var y = cy
            path.move(to: CGPoint(x: x, y: y))
            let segments = Int.random(in: 3...6, using: &rng)
            for _ in 0..<segments {
                angle += Double.random(in: -0.35...0.35, using: &rng)
                let length = Double.random(in: 14...34, using: &rng) * crack.scale
                x += cos(angle) * length
                y += sin(angle) * length
                path.addLine(to: CGPoint(x: x, y: y))
                if Double.random(in: 0..<1, using: &rng) < 0.25 {
                    let side = Bool.random(using: &rng) ? 1.0 : -1.0
                    let branch = angle + Double.random(in: 0.5...0.9, using: &rng) * side
                    path.addLine(to: CGPoint(x: x + cos(branch) * length * 0.8, y: y + sin(branch) * length * 0.8))
                    path.move(to: CGPoint(x: x, y: y))
                }
            }
        }
        let r = 6 * crack.scale
        path.addEllipse(in: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
        return path
    }
}

/// シードを決めると毎回同じ乱数を出す（ヒビの形を固定するため）
struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

// MARK: - スロット

struct SlotOverlay: View {
    let spin: SlotSpin

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSince(spin.started)
            let done = t > 1.5
            VStack(spacing: 8) {
                Text(done ? (spin.win ? "JACKPOT!!" : "ハズレ…") : "SLOT")
                    .font(AppFont.display(18))
                    .foregroundStyle(done && spin.win ? Palette.yellow : Color.white)
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { i in
                        reel(i, t: t)
                    }
                }
            }
            .padding(14)
            .chunkyPanel(done && spin.win ? Palette.pink : Palette.panel, corner: 20, depth: 6, border: 4)
            .scaleEffect(done && spin.win ? 1.1 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: done)
        }
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("スロット \(spin.symbols.joined(separator: " "))")
    }

    private func reel(_ i: Int, t: Double) -> some View {
        let stopped = t > 0.4 * Double(i + 1)
        let symbols = SlotSpin.reelSymbols
        let spinning = symbols[Int(t * 18 + Double(i) * 2) % symbols.count]
        return Text(stopped ? spin.symbols[i] : spinning)
            .font(.system(size: 36))
            .frame(width: 58, height: 64)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.black, lineWidth: 3))
            .offset(y: stopped ? 0 : CGFloat(sin(t * 40 + Double(i))) * 3)
    }
}

// MARK: - ラスト1マスの赤いふち

struct LastCellVignette: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let beat = pow(max(0, sin(t * .pi * 2 / 0.75)), 8)
            RadialGradient(colors: [.clear, Palette.pink.opacity(0.2 + 0.35 * beat)],
                           center: .center, startRadius: 140, endRadius: 520)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - 広告（もちろん中身はうそ）

struct FakeAdView: View {
    let session: AdSession
    let offerText: String
    var onWatch: () -> Void
    var onDecline: () -> Void
    var onClose: () -> Void

    @State private var skipOffset: CGSize = .zero
    @State private var skipTaps = 0

    private static let ads: [(name: String, copy: String, note: String, icon: String, color: Color)] = [
        ("地雷保険 ボムガード", "今なら旗が1本無料!!", "※地雷は防げません", "shield.lefthalf.filled", Palette.cyan),
        ("旗の達人 通信講座", "3日で旗が立てられる!", "※個人の感想です", "flag.2.crossed.fill", Palette.lime),
        ("脳汁サプリ ドパミンZ", "飲むだけでコンボ+1!?", "※食品です。コンボは増えません", "pills.fill", Palette.pink)
    ]

    private var ad: (name: String, copy: String, note: String, icon: String, color: Color) {
        Self.ads[Int(session.id.uuid.0) % Self.ads.count]
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.75).ignoresSafeArea()
            if let started = session.started {
                adBody(started)
            } else {
                offer
            }
        }
    }

    private var offer: some View {
        VStack(spacing: 14) {
            Image(systemName: "play.tv.fill")
                .font(.system(size: 40, weight: .black))
                .foregroundStyle(Palette.yellow)
            Text("広告を見て復活する？").font(AppFont.display(22))
            Text(offerText)
                .font(AppFont.body(13))
                .foregroundStyle(Palette.lavender)
                .multilineTextAlignment(.center)
            Button(action: onWatch) {
                Text("見る（5秒）").font(AppFont.display(20))
            }
            .buttonStyle(ChunkyButtonStyle(fill: Palette.yellow, corner: 16, depth: 6))
            .frame(height: 60)
            Button(action: onDecline) {
                Text("あきらめる").font(AppFont.body(15))
            }
            .buttonStyle(ChunkyButtonStyle(fill: Palette.panel, textColor: .white, corner: 14, depth: 4))
            .frame(height: 46)
        }
        .foregroundStyle(.white)
        .padding(22)
        .frame(maxWidth: 320)
        .chunkyPanel(Palette.base, corner: 24, depth: 8, border: 4)
        .padding(24)
    }

    private func adBody(_ started: Date) -> some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSince(started)
            let remaining = max(0, AdSession.length - t)
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 16) {
                    Spacer()
                    Text("PR").font(AppFont.body(11)).sticker(.white)
                    Image(systemName: ad.icon)
                        .font(.system(size: 90, weight: .black))
                        .foregroundStyle(ad.color)
                        .shadow(color: .black, radius: 0, x: 4, y: 4)
                        .rotationEffect(.degrees(sin(t * 6) * 8))
                        .scaleEffect(1 + 0.08 * sin(t * 9))
                    PopText(text: ad.name, size: 30, color: .white, stroke: 3, shadows: [ad.color, .black], shadowStep: 3)
                    Text(ad.copy).font(AppFont.display(18)).sticker(Palette.yellow, rotation: -3)
                    Text("★★★★☆  レビュー 4.2（うそ）")
                        .font(AppFont.body(13))
                        .foregroundStyle(Palette.yellow)
                    Text(ad.note)
                        .font(AppFont.body(10, weight: .bold))
                        .foregroundStyle(.white.opacity(0.6))
                    Spacer()
                    ProgressView(value: min(1, t / AdSession.length))
                        .tint(Palette.yellow)
                        .padding(.horizontal, 30)
                        .padding(.bottom, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    LinearGradient(colors: [ad.color.opacity(0.9), Palette.base], startPoint: .top, endPoint: .bottom)
                        .hueRotation(.degrees(t * 40))
                )
                .foregroundStyle(.white)

                if remaining > 0 {
                    Button {
                        skipTaps += 1
                        Haptics.impact(.light)
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                            skipOffset = CGSize(width: CGFloat.random(in: -200...0), height: CGFloat.random(in: 0...420))
                        }
                    } label: {
                        Text(skipTaps == 0 ? "スキップ ▶︎" : "できません（あと\(Int(remaining.rounded(.up)))秒）")
                            .font(AppFont.body(12))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .buttonStyle(ChunkyButtonStyle(fill: .white, corner: 10, depth: 3))
                    .frame(width: skipTaps == 0 ? 100 : 190, height: 36)
                    .offset(skipOffset)
                    .padding(.top, 60)
                    .padding(.trailing, 16)
                } else {
                    Button(action: onClose) {
                        Image(systemName: "xmark").font(.system(size: 16, weight: .black))
                    }
                    .buttonStyle(ChunkyButtonStyle(fill: .white, corner: 18, depth: 3))
                    .frame(width: 40, height: 40)
                    .padding(.top, 60)
                    .padding(.trailing, 16)
                    .accessibilityLabel("広告を閉じる")
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - ログインボーナス

struct LoginBonusView: View {
    let bonus: LoginBonus
    var onClaim: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()
            VStack(spacing: 14) {
                PopText(text: "ログインボーナス", size: 28, color: Palette.yellow, stroke: 2,
                        shadows: [Palette.pink, .black], shadowStep: 3)
                Text("\(bonus.streak)日連続ログイン中！")
                    .font(AppFont.body(14))
                    .foregroundStyle(Palette.lavender)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                    ForEach(0..<7, id: \.self) { i in
                        dayCell(i)
                    }
                }
                Text("7日目はなんと10倍！ 明日も来てね")
                    .font(AppFont.body(12))
                    .foregroundStyle(Palette.cyan)
                Button(action: onClaim) {
                    Text("受け取る").font(AppFont.display(22))
                }
                .buttonStyle(ChunkyButtonStyle(fill: Palette.yellow, corner: 18, depth: 6))
                .frame(height: 60)
            }
            .foregroundStyle(.white)
            .padding(20)
            .frame(maxWidth: 340)
            .chunkyPanel(Palette.base, corner: 24, depth: 8, border: 4)
            .padding(20)
        }
    }

    private func dayCell(_ i: Int) -> some View {
        let today = i == bonus.dayIndex
        let past = i < bonus.dayIndex
        let icon = past ? "checkmark.circle.fill" : (i == 6 ? "gift.fill" : "brain.head.profile")
        let fill: Color = today ? Palette.yellow : (past ? Palette.well : Palette.panel)
        return VStack(spacing: 2) {
            Text("\(i + 1)日目").font(AppFont.body(10))
            Image(systemName: icon).font(.system(size: 18, weight: .black))
            Text(bonus.rewards[i].stimText)
                .font(AppFont.body(10))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .foregroundStyle(today ? Color.black : Color.white)
        .frame(maxWidth: .infinity, minHeight: 64)
        .background(RoundedRectangle(cornerRadius: 10).fill(fill))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.black, lineWidth: 2.5))
        .scaleEffect(today ? 1.08 : 1)
        .opacity(past ? 0.6 : 1)
    }
}

// MARK: - おかえり（放置収益）

struct OfflineRewardView: View {
    let reward: OfflineReward
    var onClaim: () -> Void
    var onDouble: () -> Void

    private var durationText: String {
        let total = Int(reward.seconds)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        return hours > 0 ? "\(hours)時間\(minutes)分" : "\(max(1, minutes))分"
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()
            VStack(spacing: 12) {
                PopText(text: "おかえり！", size: 40, color: .white, stroke: 3,
                        shadows: [Palette.pink, .black], shadowStep: 4)
                    .rotationEffect(.degrees(-4))
                Text("\(durationText)のあいだに")
                    .font(AppFont.body(14))
                    .foregroundStyle(Palette.lavender)
                PopText(text: "+\(reward.amount.stimText)", size: 44, color: Palette.yellow, shadowStep: 4)
                Text(reward.seconds > 8 * 3600 ? "刺激がたまってました（最大8時間ぶん）" : "刺激がたまってました")
                    .font(AppFont.body(14))
                Button(action: onDouble) {
                    HStack(spacing: 6) {
                        Image(systemName: "play.tv.fill")
                        Text("広告を見て2倍").font(AppFont.display(18))
                    }
                }
                .buttonStyle(ChunkyButtonStyle(fill: Palette.pink, textColor: .white, corner: 16, depth: 6))
                .frame(height: 58)
                .padding(.top, 6)
                Button(action: onClaim) {
                    Text("そのまま受け取る").font(AppFont.body(15))
                }
                .buttonStyle(ChunkyButtonStyle(fill: Palette.yellow, corner: 14, depth: 4))
                .frame(height: 46)
            }
            .foregroundStyle(.white)
            .padding(22)
            .frame(maxWidth: 330)
            .chunkyPanel(Palette.base, corner: 24, depth: 8, border: 4)
            .padding(20)
        }
    }
}

// MARK: - 実績解除

struct AchievementToastView: View {
    let toast: AchievementToast

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Starburst(points: 10)
                    .fill(Palette.yellow)
                    .overlay(Starburst(points: 10).stroke(Color.black, lineWidth: 2.5))
                Image(systemName: "trophy.fill")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(.black)
            }
            .frame(width: 48, height: 48)
            VStack(alignment: .leading, spacing: 1) {
                Text("実績解除！").font(AppFont.body(11)).foregroundStyle(Palette.yellow)
                Text(toast.achievement.title).font(AppFont.display(17))
                Text(toast.achievement.detail)
                    .font(AppFont.body(11, weight: .bold))
                    .foregroundStyle(Palette.lavender)
                    .lineLimit(1)
            }
            Spacer(minLength: 4)
            Text("+\(toast.reward.stimText)")
                .font(AppFont.display(14))
                .sticker(Palette.lime, rotation: 6)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .chunkyPanel(Palette.panel, corner: 18, depth: 5)
        .padding(.horizontal, 12)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - ショップの「実績」タブ

struct AchievementsList: View {
    let game: StimGame

    var body: some View {
        VStack(spacing: 12) {
            Text("\(game.achievements.count) / \(StimAchievement.allCases.count) 解除")
                .font(AppFont.display(16))
                .foregroundStyle(Palette.yellow)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(StimAchievement.allCases) { a in
                    card(a)
                }
            }
        }
    }

    private func card(_ a: StimAchievement) -> some View {
        let unlocked = game.achievements.contains(a)
        return VStack(alignment: .leading, spacing: 4) {
            Image(systemName: unlocked ? a.icon : "lock.fill")
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(unlocked ? Color.black : Palette.lavender)
                .frame(width: 34, height: 34)
                .background(RoundedRectangle(cornerRadius: 9).fill(unlocked ? Palette.yellow : Palette.well))
            Text(unlocked ? a.title : "？？？")
                .font(AppFont.display(14))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(a.detail)
                .font(AppFont.body(10, weight: .bold))
                .foregroundStyle(Palette.lavender)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
        .padding(10)
        .chunkyPanel(unlocked ? Palette.panel : Palette.panel.opacity(0.5), corner: 14, depth: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(unlocked ? "\(a.title) 解除済み。\(a.detail)" : "未解除。\(a.detail)")
    }
}

// MARK: - ショップの「転生」タブ

struct PrestigePanel: View {
    let game: StimGame
    @State private var confirm = false

    private func multiplierText(_ points: Int) -> String {
        "x" + (1 + 0.1 * Double(points)).formatted(.number.precision(.fractionLength(1)))
    }

    var body: some View {
        let gain = game.prestigeGain
        VStack(spacing: 14) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 40, weight: .black))
                .foregroundStyle(Palette.cyan)
            Text("いまの刺激と買ったものを全部手放すかわりに、ずっと残る倍率をもらえます。実績と記録は残ります。")
                .font(AppFont.body(13, weight: .bold))
                .foregroundStyle(Palette.lavender)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                stat("いまの倍率", multiplierText(game.prestigePoints))
                stat("転生後", gain > 0 ? multiplierText(game.prestigePoints + gain) : "-")
                stat("転生回数", "\(game.prestigeCount)回")
            }

            Button {
                confirm = true
            } label: {
                VStack(spacing: 0) {
                    Text("転生する").font(AppFont.display(22))
                    Text(gain > 0 ? "転生ポイント +\(gain)" : "今回の周回で2万稼ぐと転生できます")
                        .font(AppFont.body(11))
                }
            }
            .buttonStyle(ChunkyButtonStyle(fill: gain > 0 ? Palette.cyan : Palette.panel,
                                           textColor: gain > 0 ? .black : .white, corner: 18, depth: 6))
            .frame(height: 70)
            .disabled(gain == 0)

            VStack(alignment: .leading, spacing: 6) {
                row("今回の周回で稼いだ刺激", game.totalEarned.stimText)
                row("これまでに浴びた刺激", game.lifetimeEarned.stimText)
                row("開けたマス", game.cellsOpened.formatted())
                row("盤面クリア", "\(game.clears)回")
            }
            .padding(12)
            .chunkyPanel(Palette.panel, corner: 14, depth: 4)
        }
        .confirmationDialog("転生しますか？ 刺激と買ったものはなくなります",
                            isPresented: $confirm, titleVisibility: .visible) {
            Button("転生する（+\(gain)ポイント）", role: .destructive) {
                game.prestige()
            }
            Button("やめる", role: .cancel) {}
        }
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(label).font(AppFont.body(10)).foregroundStyle(Palette.lavender)
            Text(value).font(AppFont.display(16)).foregroundStyle(Palette.yellow)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .chunkyPanel(Palette.well, corner: 12, depth: 3)
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(AppFont.body(12, weight: .bold)).foregroundStyle(Palette.lavender)
            Spacer()
            Text(value).font(AppFont.body(13)).monospacedDigit()
        }
    }
}
