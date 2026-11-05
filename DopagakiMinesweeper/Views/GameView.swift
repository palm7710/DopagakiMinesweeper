import SwiftUI

struct GameView: View {
    let game: GameViewModel
    var onExit: () -> Void

    @Environment(PlayerProgress.self) private var progress
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var shakeAmount: CGFloat {
        (progress.shakeOn && !reduceMotion) ? 10 : 0
    }

    var body: some View {
        ZStack {
            (game.isFever ? Palette.feverBG : Palette.base)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.3), value: game.isFever)

            VStack(spacing: 12) {
                hud
                scoreBlock
                feverBar
                if game.isFever {
                    feverBanner
                        .transition(.scale(scale: 0.6).combined(with: .opacity))
                }
                BoardView(game: game)
                    .frame(maxHeight: .infinity)
                toolbar
            }
            .padding(.horizontal, 12)
            .padding(.top, 4)
            .padding(.bottom, 8)
            .foregroundStyle(.white)
            .modifier(ShakeEffect(amount: shakeAmount, animatableData: CGFloat(game.shakeCount)))
            .animation(.linear(duration: 0.45), value: game.shakeCount)
            .animation(.spring(response: 0.35, dampingFraction: 0.6), value: game.isFever)

            if let result = game.result {
                resultView(result)
                    .transition(.asymmetric(insertion: .scale(scale: 1.15).combined(with: .opacity),
                                            removal: .opacity))
                    .zIndex(1)
            }
        }
    }

    // MARK: - HUD

    private var hud: some View {
        HStack {
            Button {
                game.commitPendingResult()
                onExit()
            } label: {
                Image(systemName: "house.fill").font(.system(size: 17, weight: .bold))
            }
            .buttonStyle(ChunkyButtonStyle(fill: Palette.panel, textColor: .white, corner: 12, depth: 4))
            .frame(width: 44, height: 44)
            .accessibilityLabel("タイトルへ戻る")

            Spacer()

            TimelineView(.periodic(from: .now, by: 0.1)) { context in
                Text(Self.formatTime(game.elapsed(at: context.date)))
                    .font(AppFont.display(22))
                    .monospacedDigit()
            }

            Spacer()

            HStack(spacing: 4) {
                MineIcon(color: Palette.pinkSoft).frame(width: 18, height: 18)
                Text("\(game.minesLeft)")
                    .font(AppFont.display(18))
                    .foregroundStyle(Palette.pinkSoft)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(Palette.well))
            .overlay(Capsule().strokeBorder(Color.black, lineWidth: 3))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("残り地雷 \(game.minesLeft)")
        }
    }

    private var scoreBlock: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 2) {
                Text("SCORE")
                    .font(AppFont.body(12))
                    .tracking(2)
                    .foregroundStyle(Palette.lavender)
                PopText(text: game.score.formatted(), size: 42, color: Palette.yellow)
                    .phaseAnimator([1.0, 1.12, 1.0], trigger: game.score) { view, scale in
                        view.scaleEffect(scale)
                    } animation: { _ in .spring(response: 0.12, dampingFraction: 0.6) }
            }
            .frame(maxWidth: .infinity)

            if game.combo >= 2 {
                Text("x\(game.combo) COMBO!!")
                    .font(AppFont.display(18))
                    .phaseAnimator([1.0, 1.25, 1.0], trigger: game.combo) { view, scale in
                        view.scaleEffect(scale)
                    } animation: { _ in .spring(response: 0.12, dampingFraction: 0.5) }
                    .sticker(Palette.pink, rotation: 10)
                    .offset(y: 6)
                    .transition(.scale(scale: 0.2).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.55), value: game.combo >= 2)
    }

    private var feverBar: some View {
        HStack(spacing: 8) {
            Text("FEVER")
                .font(AppFont.display(14))
                .foregroundStyle(game.isFever ? Palette.yellow : Palette.cyan)
            HStack(spacing: 3) {
                ForEach(0..<10, id: \.self) { i in
                    let lit = Double(i) < game.feverGauge * 10
                    RoundedRectangle(cornerRadius: 4)
                        .fill(lit ? (game.isFever ? Palette.yellow : Palette.cyan) : Palette.well)
                        .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(Color.black, lineWidth: 2))
                        .frame(height: 14)
                }
            }
            .animation(.snappy, value: game.feverGauge)
            Text(game.isFever ? "MAX" : "\(Int(game.feverGauge * 100))%")
                .font(AppFont.body(13))
                .foregroundStyle(game.isFever ? Palette.yellow : Palette.cyan)
                .frame(width: 40, alignment: .trailing)
        }
        .padding(.horizontal, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(game.isFever ? "フィーバー中" : "フィーバーゲージ \(Int(game.feverGauge * 100))パーセント")
    }

    private var feverBanner: some View {
        Text("FEVER TIME!! スコア x2")
            .font(AppFont.display(20))
            .tracking(2)
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .chunkyPanel(Palette.yellow, corner: 12, depth: 4)
            .phaseAnimator([1.0, 1.04]) { view, scale in
                view.scaleEffect(scale)
            } animation: { _ in .easeInOut(duration: 0.25) }
            .rotationEffect(.degrees(-1.5))
    }

    // MARK: - 下のボタン

    private var toolbar: some View {
        HStack(spacing: 10) {
            Button {
                game.toggleFlagMode()
            } label: {
                toolLabel(icon: "flag.fill", text: game.flagMode ? "旗モード ON" : "旗モード OFF")
            }
            .buttonStyle(ChunkyButtonStyle(fill: game.flagMode ? Palette.yellow : Palette.panel,
                                           textColor: game.flagMode ? .black : .white))
            .accessibilityAddTraits(game.flagMode ? .isSelected : [])

            Button {
                game.useRadar()
            } label: {
                toolLabel(icon: "scope", text: "レーダー ×\(game.radarLeft)")
            }
            .buttonStyle(ChunkyButtonStyle(fill: Palette.cyan))
            .disabled(game.radarLeft == 0 || game.phase != .playing)

            toolLabel(icon: "heart.fill", text: "復活 ×\(game.reviveLeft)")
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .chunkyPanel(game.reviveLeft > 0 ? Palette.lime : Palette.panel, corner: 16, depth: 5)
                .accessibilityElement(children: .combine)
        }
        .frame(height: 68)
        .padding(.bottom, 5)
    }

    private func toolLabel(icon: String, text: String) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon).font(.system(size: 20, weight: .black))
            Text(text).font(AppFont.body(13))
        }
    }

    // MARK: - 結果

    @ViewBuilder
    private func resultView(_ result: RoundResult) -> some View {
        if result.won {
            ClearView(
                result: result,
                onNext: { withAnimation(.snappy) { game.restart() } },
                onTitle: onExit
            )
        } else {
            GameOverView(
                result: result,
                reviveLeft: game.reviveLeft,
                onRetry: { withAnimation(.snappy) { game.restart() } },
                onRevive: { withAnimation(.snappy) { game.revive() } },
                onTitle: {
                    game.commitPendingResult()
                    onExit()
                }
            )
        }
    }

    static func formatTime(_ t: TimeInterval) -> String {
        let minutes = Int(t) / 60
        let seconds = t - Double(minutes * 60)
        return String(format: "%02d:%04.1f", minutes, seconds)
    }
}
