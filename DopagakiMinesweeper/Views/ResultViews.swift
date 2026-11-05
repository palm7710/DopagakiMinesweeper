import SwiftUI

// MARK: - クリア画面

struct ClearView: View {
    let result: RoundResult
    var onNext: () -> Void
    var onTitle: () -> Void

    @Environment(PlayerProgress.self) private var progress
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    @State private var shownScore = 0

    var body: some View {
        ZStack {
            Palette.base.ignoresSafeArea()
            if !reduceMotion { ConfettiView() }

            ScrollView {
                VStack(spacing: 16) {
                    PopText(text: "CLEAR!!", size: 62, color: .white, stroke: 3,
                            shadows: [Palette.pink, Palette.cyan, .black], shadowStep: 4)
                        .rotationEffect(.degrees(-4))
                        .scaleEffect(appeared ? 1 : 2.2)
                        .opacity(appeared ? 1 : 0)
                        .padding(.top, 24)

                    HStack(spacing: 14) {
                        rankBadge
                        VStack(alignment: .leading, spacing: 6) {
                            if result.isNewRecord {
                                Text("NEW RECORD!").font(AppFont.body(13)).sticker(Palette.lime, rotation: -4)
                            }
                            PopText(text: shownScore.formatted(), size: 34, color: Palette.yellow, shadowStep: 3)
                            Text(result.isNewRecord
                                 ? "自己ベスト +\((result.score - result.previousBest).formatted())"
                                 : "ベスト \(result.previousBest.formatted())")
                                .font(AppFont.body(13))
                                .foregroundStyle(Palette.lavender)
                        }
                    }

                    statsPanel
                    xpBlock
                    coinCard

                    Button(action: onNext) {
                        Text("つぎのステージ").font(AppFont.display(28))
                    }
                    .buttonStyle(ChunkyButtonStyle(fill: Palette.yellow, corner: 22, depth: 8, border: 4))
                    .frame(height: 76)
                    .padding(.top, 8)

                    HStack(spacing: 10) {
                        ShareLink(item: shareText) {
                            Label("スコアをシェア", systemImage: "square.and.arrow.up")
                                .font(AppFont.body(15))
                        }
                        .buttonStyle(ChunkyButtonStyle(fill: Palette.cyan))

                        Button(action: onTitle) {
                            Text("タイトルへ").font(AppFont.body(15))
                        }
                        .buttonStyle(ChunkyButtonStyle(fill: Palette.panel, textColor: .white))
                    }
                    .frame(height: 56)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .foregroundStyle(.white)
        .task {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.55)) { appeared = true }
            await countUpScore()
        }
    }

    private var rankBadge: some View {
        ZStack {
            Starburst()
                .fill(Palette.yellow)
                .overlay(Starburst().stroke(Color.black, lineWidth: 4))
            PopText(text: result.rank, size: 72, color: Palette.pink, stroke: 3, shadows: [], shadowStep: 0)
        }
        .frame(width: 140, height: 140)
        .scaleEffect(appeared ? 1 : 0.1)
        .rotationEffect(.degrees(appeared ? 0 : -200))
        .animation(.spring(response: 0.6, dampingFraction: 0.5).delay(0.2), value: appeared)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("ランク \(result.rank)")
    }

    private var statsPanel: some View {
        VStack(spacing: 0) {
            statRow("タイム", GameView.formatTime(result.time), .white)
            divider
            statRow("最大コンボ", "x\(result.maxCombo)", Palette.pinkSoft)
            divider
            statRow("一撃連鎖", "\(result.biggestChain)マス", Palette.cyan)
            divider
            statRow("フィーバー", "\(result.feverCount)回", Palette.yellow)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .chunkyPanel(Palette.panel)
    }

    private var divider: some View {
        Rectangle().fill(Palette.divider).frame(height: 2)
    }

    private func statRow(_ label: String, _ value: String, _ color: Color) -> some View {
        HStack {
            Text(label).font(AppFont.body(14)).foregroundStyle(Palette.lavender)
            Spacer()
            Text(value).font(AppFont.display(20)).foregroundStyle(color)
        }
        .frame(height: 40)
        .accessibilityElement(children: .combine)
    }

    private var xpBlock: some View {
        VStack(spacing: 6) {
            HStack {
                Text("+\(result.xpGained.formatted()) XP")
                    .font(AppFont.display(18))
                    .foregroundStyle(Palette.lime)
                Spacer()
                if result.leveledUp {
                    Text("LEVEL UP! \(result.levelFrom)→\(result.levelTo)")
                        .font(AppFont.display(14))
                        .sticker(Palette.pink, rotation: 3)
                        .phaseAnimator([1.0, 1.08]) { view, s in
                            view.scaleEffect(s)
                        } animation: { _ in .easeInOut(duration: 0.3) }
                }
            }
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Palette.well)
                    Capsule().fill(Palette.lime)
                        .frame(width: appeared ? g.size.width * progress.levelProgress : 0)
                        .animation(.easeOut(duration: 0.8).delay(0.4), value: appeared)
                }
                .overlay(Capsule().strokeBorder(Color.black, lineWidth: 3))
                .clipShape(Capsule())
            }
            .frame(height: 18)
        }
    }

    private var coinCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "dollarsign.circle.fill")
                .font(.system(size: 30, weight: .black))
                .foregroundStyle(.black)
                .frame(width: 56, height: 56)
                .background(RoundedRectangle(cornerRadius: 12).fill(Palette.orange))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.black, lineWidth: 3))
            VStack(alignment: .leading, spacing: 2) {
                Text("コインゲット！").font(AppFont.body(12)).foregroundStyle(Palette.yellow)
                Text("+\(result.coinsGained.formatted()) コイン").font(AppFont.body(17))
            }
            Spacer()
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16).fill(Palette.well))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Palette.yellow, lineWidth: 3))
    }

    private var shareText: String {
        "ドパガキマインスイーパーで \(result.score.formatted())点！ランク\(result.rank)・最大コンボx\(result.maxCombo) #ドパガキマインスイーパー"
    }

    @MainActor
    private func countUpScore() async {
        let steps = 30
        for i in 1...steps {
            try? await Task.sleep(for: .milliseconds(25))
            shownScore = result.score * i / steps
            if i.isMultiple(of: 3) { Haptics.impact(.light, intensity: 0.6) }
        }
        shownScore = result.score
    }
}

// MARK: - ゲームオーバー画面

struct GameOverView: View {
    let result: RoundResult
    let reviveLeft: Int
    var onRetry: () -> Void
    var onRevive: () -> Void
    var onTitle: () -> Void

    @State private var appeared = false

    private var isClose: Bool { result.clearRatio >= 0.7 }

    var body: some View {
        ZStack {
            Palette.gameOverBG.ignoresSafeArea()

            VStack(spacing: 18) {
                boom
                nearMissCard

                Label("最大コンボ x\(result.maxCombo) で散った…", systemImage: "flame.fill")
                    .font(AppFont.body(14))
                    .foregroundStyle(Color(hex: 0xFFB3D4))

                Spacer(minLength: 0)

                Button {
                    Haptics.impact(.heavy)
                    onRetry()
                } label: {
                    VStack(spacing: 2) {
                        Text("もう一回！").font(AppFont.display(34))
                        Text("タップで即リスタート").font(AppFont.body(13))
                    }
                }
                .buttonStyle(ChunkyButtonStyle(fill: Palette.yellow, corner: 24, depth: 8, border: 4))
                .frame(height: 92)

                if reviveLeft > 0 {
                    Button(action: onRevive) {
                        Label("復活してつづける（残り\(reviveLeft)）", systemImage: "heart.fill")
                            .font(AppFont.body(16))
                    }
                    .buttonStyle(ChunkyButtonStyle(fill: Palette.lime, corner: 18))
                    .frame(height: 60)
                }

                Button("タイトルへ", action: onTitle)
                    .font(AppFont.body(14))
                    .foregroundStyle(Palette.yellow)
                    .frame(minHeight: 44)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        .foregroundStyle(.white)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.45)) { appeared = true }
        }
    }

    private var boom: some View {
        ZStack {
            Starburst(points: 14)
                .fill(Palette.orange)
                .overlay(Starburst(points: 14).stroke(Color.black, lineWidth: 4))
                .frame(width: 320, height: 320)
                .rotationEffect(.degrees(8))
            Starburst()
                .fill(Palette.yellow)
                .overlay(Starburst().stroke(Color.black, lineWidth: 4))
                .frame(width: 210, height: 210)
                .rotationEffect(.degrees(-10))
                .offset(x: 30, y: 10)
            PopText(text: "ドカーン!!", size: 58, color: Palette.pink, stroke: 3, shadowStep: 5)
                .rotationEffect(.degrees(-8))
        }
        .frame(height: 280)
        .scaleEffect(appeared ? 1 : 0.2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("ゲームオーバー")
    }

    private var nearMissCard: some View {
        VStack(spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(isClose ? "おしい！" : "ドンマイ！")
                    .font(AppFont.display(22))
                    .foregroundStyle(Palette.yellow)
                Spacer()
                Text("あと ").font(AppFont.body(15))
                + Text("\(result.remainingSafe)").font(AppFont.display(26)).foregroundStyle(Palette.cyan)
                + Text(" マスでクリア").font(AppFont.body(15))
            }
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Palette.panel)
                    Capsule().fill(Palette.cyan)
                        .frame(width: appeared ? g.size.width * result.clearRatio : 0)
                        .animation(.easeOut(duration: 0.7).delay(0.2), value: appeared)
                }
                .overlay(Capsule().strokeBorder(Color.black, lineWidth: 3))
                .clipShape(Capsule())
            }
            .frame(height: 20)
            HStack {
                Text("スコア \(result.score.formatted())")
                Spacer()
                Text("ベスト \(max(result.previousBest, result.score).formatted())")
            }
            .font(AppFont.body(13))
            .foregroundStyle(Palette.lavender)
        }
        .padding(16)
        .chunkyPanel(Palette.well)
    }
}
