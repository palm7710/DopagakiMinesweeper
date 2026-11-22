import SwiftUI

/// 刺激モードの画面。買ったものが増えるほどうるさくなる
struct StimGameView: View {
    let game: StimGame
    var onExit: () -> Void

    @Environment(PlayerProgress.self) private var progress
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showShop = false
    @State private var showConfetti = false
    @AppStorage("fishInFront") private var fishInFront = false

    private var shakeAmount: CGFloat {
        (progress.shakeOn && !reduceMotion) ? 10 : 0
    }

    var body: some View {
        ZStack {
            background

            VStack(spacing: 8) {
                header
                FestBanner(active: game.festActive, seconds: game.festSeconds)
                if game.owns(.ticker) {
                    NewsTicker(speed: 60 * min(3, 1 + 0.3 * Double(game.level(.ticker) - 1)))
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                BoardView(game: game)
                    .frame(maxHeight: .infinity)
                    .scaleEffect(game.lastCell ? 1.04 : 1)
                    .animation(.easeInOut(duration: 1.2), value: game.lastCell)
                toolbar
            }
            .padding(.horizontal, 12)
            .padding(.top, 4)
            .padding(.bottom, 8)
            .foregroundStyle(.white)
            .modifier(ShakeEffect(amount: shakeAmount, animatableData: CGFloat(game.shakeCount)))
            .animation(.linear(duration: 0.45), value: game.shakeCount)

            effectLayer
            interactiveLayer
            popupLayer
            fullScreenPrompts

            if game.showEnding {
                StimEndingView(game: game, onExit: onExit)
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: game.owns(.ticker))
        .animation(.easeInOut(duration: 0.4), value: game.lastCell)
        .sheet(isPresented: $showShop) {
            StimShopView(game: game)
                .presentationDetents([.medium, .large])
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                .presentationBackground(Palette.base)
                .presentationCornerRadius(28)
        }
        .onAppear { game.start() }
        .onDisappear { game.stop() }
        .onChange(of: game.showEnding) { _, ended in
            if ended { showShop = false }
        }
        .onChange(of: game.isBlocked) { _, blocked in
            if blocked { showShop = false }
        }
        .onChange(of: game.celebrateCount) { _, _ in
            showConfetti = true
            Task {
                try? await Task.sleep(for: .seconds(2.2))
                showConfetti = false
            }
        }
    }

    // MARK: - 重ねる層

    /// さわれない演出（赤いふち、弾幕、小窓、DVDロゴ、ヒビ）
    private var effectLayer: some View {
        ZStack {
            if game.lastCell {
                LastCellVignette().transition(.opacity)
            }
            if game.owns(.aquarium) && fishInFront {
                FishTankLayer(fish: game.swimmingFish)
            }
            if game.owns(.danmaku) {
                DanmakuLayer(comments: game.danmaku)
            }
            floatingWidgets
            ForEach(0..<min(game.level(.dvd), 5), id: \.self) { i in
                DVDLogoLayer(index: i) { corner in game.dvdBounce(corner: corner) }
                    .ignoresSafeArea()
            }
            if !game.cracks.isEmpty {
                CrackLayer(cracks: game.cracks).transition(.opacity)
            }
        }
        .allowsHitTesting(false)
    }

    /// タップできる演出（投げ銭、鳥、通知）
    private var interactiveLayer: some View {
        ZStack {
            superChatStack
            birdLayer
            notificationStack
        }
    }

    /// 一瞬だけ出る演出（スロット、ガチャ、紙吹雪、実績）
    private var popupLayer: some View {
        ZStack {
            if let spin = game.slotSpin {
                SlotOverlay(spin: spin)
                    .transition(.scale(scale: 0.5).combined(with: .opacity))
            }
            if let result = game.gachaResult {
                GachaOverlay(result: result)
                    .transition(.scale(scale: 0.4).combined(with: .opacity))
            }
            if showConfetti && !reduceMotion {
                ConfettiView()
                    .id(game.celebrateCount)
            }
            if let toast = game.achievementToast {
                VStack {
                    AchievementToastView(toast: toast)
                        .padding(.top, 54)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - 背景

    private var background: some View {
        ZStack {
            (game.festActive ? Palette.feverBG : Palette.base)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.5), value: game.festActive)
            if game.owns(.rainbow) {
                GamingBackground(speed: 90 * Double(min(game.level(.rainbow), 5)))
            }
            if game.owns(.emojiRain) {
                EmojiRainLayer(count: 24 * min(game.level(.emojiRain), 4))
            }
            if game.owns(.rain) {
                RainLayer(count: 70 * min(game.level(.rain), 4))
            }
            if game.owns(.aquarium) && !fishInFront {
                FishTankLayer(fish: game.swimmingFish)
            }
        }
    }

    // MARK: - 上部

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            Button {
                game.stop()
                onExit()
            } label: {
                Image(systemName: "house.fill").font(.system(size: 17, weight: .bold))
            }
            .buttonStyle(ChunkyButtonStyle(fill: Palette.panel, textColor: .white, corner: 12, depth: 4))
            .frame(width: 44, height: 44)
            .accessibilityLabel("タイトルへ戻る")

            VStack(spacing: 0) {
                HStack(spacing: 6) {
                    Text("刺激")
                        .font(AppFont.body(11))
                        .tracking(2)
                        .foregroundStyle(Palette.lavender)
                    if game.prestigePoints > 0 {
                        Text("転生 x\(game.prestigeMultiplier.formatted(.number.precision(.fractionLength(1))))")
                            .font(AppFont.body(10))
                            .foregroundStyle(Palette.cyan)
                    }
                }
                PopText(text: game.stim.stimText, size: 34, color: Palette.yellow, shadows: [Palette.pink], shadowStep: 3)
                Text("毎秒 +\(game.perSecond.stimText)")
                    .font(AppFont.body(12))
                    .foregroundStyle(game.festActive ? Palette.yellow : Palette.cyan)
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("刺激 \(Int(game.stim))、毎秒 \(game.perSecond.stimText)")

            Button {
                showShop = true
                SoundEngine.shared.play(.button)
                Haptics.impact(.rigid)
            } label: {
                VStack(spacing: 0) {
                    Image(systemName: "cart.fill").font(.system(size: 17, weight: .black))
                    Text("ショップ").font(AppFont.body(10))
                }
            }
            .buttonStyle(ChunkyButtonStyle(fill: Palette.yellow, corner: 12, depth: 4))
            .frame(width: 60, height: 50)
            .overlay(alignment: .topTrailing) {
                if affordableCount > 0 {
                    Text("\(affordableCount)")
                        .font(AppFont.body(11))
                        .foregroundStyle(.white)
                        .frame(minWidth: 20, minHeight: 20)
                        .background(Circle().fill(Palette.pink))
                        .overlay(Circle().strokeBorder(Color.black, lineWidth: 2))
                        .offset(x: 8, y: -8)
                        .transition(.scale)
                }
            }
            .accessibilityLabel("ショップ。買えるもの \(affordableCount)個")
        }
    }

    private var affordableCount: Int {
        StimItem.allCases.filter { game.isRevealed($0) && game.canBuy($0) }.count
    }

    // MARK: - 下のボタン

    private var toolbar: some View {
        HStack(spacing: 8) {
            Button {
                game.toggleFlagMode()
            } label: {
                toolLabel(icon: "flag.fill", text: game.flagMode ? "旗 ON" : "旗 OFF")
            }
            .buttonStyle(ChunkyButtonStyle(fill: game.flagMode ? Palette.yellow : Palette.panel,
                                           textColor: game.flagMode ? .black : .white))
            .accessibilityLabel(game.flagMode ? "旗モード オン" : "旗モード オフ")
            .accessibilityAddTraits(game.flagMode ? .isSelected : [])

            VStack(spacing: 2) {
                Text("x\(game.streakMultiplier.formatted(.number.precision(.fractionLength(2))))")
                    .font(AppFont.display(17))
                Text(game.clearStreak > 0 ? "\(game.clearStreak)連続" : "連続クリア")
                    .font(AppFont.body(10))
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .chunkyPanel(game.clearStreak > 0 ? Palette.lime : Palette.lavender, corner: 16, depth: 5)
            .accessibilityElement(children: .combine)

            if game.owns(.gacha) {
                Button {
                    game.rollGacha()
                } label: {
                    toolLabel(icon: "die.face.5.fill", text: "ガチャ \(game.gachaCost.stimText)")
                }
                .buttonStyle(ChunkyButtonStyle(fill: Palette.orange))
                .disabled(game.stim < game.gachaCost || game.gachaResult != nil)
                .transition(.scale.combined(with: .opacity))
            }

            if game.owns(.pet) {
                petButton
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(height: 64)
        .padding(.bottom, 5)
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: game.owns(.gacha))
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: game.owns(.pet))
    }

    private var petCount: Int { min(max(game.level(.pet), 1), 3) }

    private var petButton: some View {
        let hungry = game.petHunger < 0.3
        return Button {
            game.feedPet()
        } label: {
            VStack(spacing: 0) {
                HStack(spacing: -14) {
                    ForEach(0..<petCount, id: \.self) { _ in
                        PetCreature(hunger: game.petHunger)
                    }
                }
                .scaleEffect(petCount == 1 ? 1 : (petCount == 2 ? 0.75 : 0.6))
                .frame(height: 42)
                .phaseAnimator([1.0, 1.3, 1.0], trigger: game.petFedCount) { view, scale in
                        view.scaleEffect(scale)
                    } animation: { _ in .spring(response: 0.18, dampingFraction: 0.5) }
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Palette.well)
                        Capsule()
                            .fill(hungry ? Palette.pink : Palette.lime)
                            .frame(width: max(0, g.size.width * game.petHunger))
                    }
                }
                .frame(height: 5)
                .padding(.horizontal, 10)
                Text("ごはん \(game.petFoodCost.stimText)")
                    .font(AppFont.body(9))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .buttonStyle(ChunkyButtonStyle(fill: hungry ? Palette.pink : Palette.lavender))
        .overlay(alignment: .top) {
            if hungry {
                Text(game.petHunger <= 0 ? "しくしく…" : "おなかすいた")
                    .font(AppFont.body(10))
                    .sticker(.white, rotation: -6)
                    .offset(y: -22)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: hungry)
        .accessibilityLabel("謎の生き物。おなか \(Int(game.petHunger * 100))パーセント。ごはん \(Int(game.petFoodCost))")
    }

    private func toolLabel(icon: String, text: String) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon).font(.system(size: 18, weight: .black))
            Text(text).font(AppFont.body(11)).lineLimit(1).minimumScaleFactor(0.7)
        }
    }

    // MARK: - 浮いている小窓

    private var floatingWidgets: some View {
        VStack {
            HStack {
                Spacer()
                if game.owns(.stocks) {
                    StockWidget(history: game.stockHistory, price: game.stockPrice, holdings: game.level(.stocks))
                        .rotationEffect(.degrees(3))
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.top, 118)
            .padding(.horizontal, 8)
            Spacer()
            HStack(alignment: .bottom) {
                if game.owns(.runner) {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(0..<min(game.level(.runner), 3), id: \.self) { i in
                            RunnerStream()
                                .rotationEffect(.degrees(i.isMultiple(of: 2) ? -3 : 3))
                                .offset(x: CGFloat(i) * 14)
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 84)
        }
        .allowsHitTesting(false)
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: game.owns(.runner))
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: game.owns(.stocks))
    }

    private var superChatStack: some View {
        VStack(alignment: .trailing, spacing: 6) {
            Spacer()
            ForEach(game.superChats) { chat in
                Button {
                    game.collect(chat)
                } label: {
                    SuperChatCard(chat: chat)
                }
                .buttonStyle(.plain)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.trailing, 10)
        .padding(.bottom, 150)
    }

    @ViewBuilder
    private var birdLayer: some View {
        if game.birdVisible {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    StudyBirdView(line: game.birdLine, anger: game.birdAnger, count: game.birdCount) {
                        game.dismissBird()
                    }
                }
                Spacer()
            }
            .padding(.trailing, 8)
            .transition(.move(edge: .trailing).combined(with: .opacity))
            .zIndex(1)
        }
    }

    private var notificationStack: some View {
        VStack(spacing: 6) {
            ForEach(game.notifications) { note in
                Button {
                    game.collect(note)
                } label: {
                    NotificationBanner(note: note)
                }
                .buttonStyle(.plain)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.top, 58)
    }

    // MARK: - 全画面のお知らせ（広告・ログボ・おかえり）

    @ViewBuilder
    private var fullScreenPrompts: some View {
        if let session = game.adSession {
            FakeAdView(
                session: session,
                offerText: game.clearStreak > 0
                    ? "\(game.clearStreak)連続クリアの倍率 x\(game.streakMultiplier.formatted(.number.precision(.fractionLength(2)))) を守れます"
                    : "この盤面の続きから再開できます",
                onWatch: { game.watchAd() },
                onDecline: { game.declineAd() },
                onClose: { game.finishAd() }
            )
            .transition(.opacity)
            .zIndex(5)
        } else if let bonus = game.loginBonus {
            LoginBonusView(bonus: bonus) { game.claimLoginBonus() }
                .transition(.scale(scale: 0.8).combined(with: .opacity))
                .zIndex(5)
        } else if let reward = game.offlineReward {
            OfflineRewardView(reward: reward,
                              onClaim: { game.claimOffline(double: false) },
                              onDouble: { game.claimOffline(double: true) })
                .transition(.scale(scale: 0.8).combined(with: .opacity))
                .zIndex(5)
        }
    }
}

// MARK: - ショップ

struct StimShopView: View {
    enum Tab: String, CaseIterable, Identifiable {
        case shop = "ショップ"
        case aquarium = "水槽"
        case achievements = "実績"
        case prestige = "転生"

        var id: String { rawValue }
    }

    let game: StimGame
    @Environment(\.dismiss) private var dismiss
    @State private var tab: Tab = .shop
    @State private var quantity: BuyQuantity = .one

    /// 解放済みの商品と、その次の「？？？」1つだけを並べる
    private var visibleItems: [StimItem] {
        var result: [StimItem] = []
        for item in StimItem.allCases {
            result.append(item)
            if !game.isRevealed(item) { break }
        }
        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                PopText(text: "刺激ショップ", size: 24, color: .white, shadows: [Palette.pink], shadowStep: 3)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "brain.head.profile")
                    Text(game.stim.stimText).monospacedDigit()
                }
                .font(AppFont.display(16))
                .foregroundStyle(Palette.yellow)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(Palette.well))
                .overlay(Capsule().strokeBorder(Color.black, lineWidth: 3))
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark").font(.system(size: 14, weight: .black))
                }
                .buttonStyle(ChunkyButtonStyle(fill: Palette.panel, textColor: .white, corner: 10, depth: 3))
                .frame(width: 36, height: 36)
                .accessibilityLabel("閉じる")
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 10)

            HStack(spacing: 8) {
                ForEach(Tab.allCases) { t in
                    Button {
                        tab = t
                        SoundEngine.shared.play(.button)
                    } label: {
                        Text(t.rawValue).font(AppFont.body(14))
                    }
                    .buttonStyle(ChunkyButtonStyle(fill: tab == t ? Palette.yellow : Palette.panel,
                                                   textColor: tab == t ? .black : .white,
                                                   corner: 12, depth: 4))
                    .frame(height: 40)
                    .accessibilityAddTraits(tab == t ? .isSelected : [])
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)

            ScrollView {
                Group {
                    switch tab {
                    case .shop:
                        VStack(spacing: 12) {
                            quantityPicker
                            ForEach(visibleItems) { item in
                                if game.isRevealed(item) {
                                    ShopRow(item: item, game: game, quantity: quantity.value)
                                } else {
                                    lockedRow
                                }
                            }
                        }
                    case .aquarium:
                        AquariumPanel(game: game)
                    case .achievements:
                        AchievementsList(game: game)
                    case .prestige:
                        PrestigePanel(game: game)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .foregroundStyle(.white)
    }

    private var quantityPicker: some View {
        HStack(spacing: 8) {
            Text("まとめ買い").font(AppFont.body(12)).foregroundStyle(Palette.lavender)
            ForEach(BuyQuantity.allCases) { q in
                Button {
                    quantity = q
                    SoundEngine.shared.play(.button)
                } label: {
                    Text(q.label).font(AppFont.body(13))
                }
                .buttonStyle(ChunkyButtonStyle(fill: quantity == q ? Palette.cyan : Palette.panel,
                                               textColor: quantity == q ? .black : .white,
                                               corner: 10, depth: 3))
                .frame(height: 34)
                .accessibilityAddTraits(quantity == q ? .isSelected : [])
            }
        }
    }

    private var lockedRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "questionmark")
                .font(.system(size: 20, weight: .black))
                .frame(width: 46, height: 46)
                .background(RoundedRectangle(cornerRadius: 12).fill(Palette.well))
            VStack(alignment: .leading, spacing: 2) {
                Text("？？？").font(AppFont.display(16))
                Text("もっと刺激を集めると解放").font(AppFont.body(12, weight: .bold)).foregroundStyle(Palette.lavender)
            }
            Spacer()
        }
        .padding(12)
        .chunkyPanel(Palette.panel.opacity(0.6), corner: 16, depth: 4)
        .accessibilityElement(children: .combine)
    }
}

/// まとめ買いの個数
enum BuyQuantity: String, CaseIterable, Identifiable {
    case one, ten, max

    var id: String { rawValue }

    var label: String {
        switch self {
        case .one: return "×1"
        case .ten: return "×10"
        case .max: return "MAX"
        }
    }

    /// nil は「買えるだけ」
    var value: Int? {
        switch self {
        case .one: return 1
        case .ten: return 10
        case .max: return nil
        }
    }
}

private struct ShopRow: View {
    let item: StimItem
    let game: StimGame
    var quantity: Int? = 1

    var body: some View {
        let level = game.level(item)
        let maxed = game.isMaxed(item)
        let quote = game.bulkQuote(item, quantity: quantity)
        let affordable = game.canBuy(item, quantity: quantity)

        HStack(spacing: 12) {
            Image(systemName: item.icon)
                .font(.system(size: 20, weight: .black))
                .foregroundStyle(.black)
                .frame(width: 46, height: 46)
                .background(RoundedRectangle(cornerRadius: 12).fill(item.color))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.black, lineWidth: 3))

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(item.name).font(AppFont.display(15)).lineLimit(1).minimumScaleFactor(0.7)
                    if item.maxLevel > 1 && level > 0 {
                        Text("×\(level)").font(AppFont.body(11)).sticker(Palette.cyan, corner: 6)
                    }
                }
                Text(item.detail)
                    .font(AppFont.body(11, weight: .bold))
                    .foregroundStyle(Palette.lavender)
                    .fixedSize(horizontal: false, vertical: true)
                if item.perSecond > 0 {
                    Text("1個につき毎秒 +\(item.perSecond.stimText)")
                        .font(AppFont.body(11))
                        .foregroundStyle(Palette.lime)
                }
                if item.maxLevel > 1 && !item.scaling.isEmpty {
                    Text("増やすと：\(item.scaling)")
                        .font(AppFont.body(10, weight: .bold))
                        .foregroundStyle(Palette.cyan)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 4)

            Button {
                game.buy(item, quantity: quantity)
            } label: {
                VStack(spacing: 0) {
                    if maxed {
                        Text("購入済み").font(AppFont.body(12))
                    } else {
                        Text(quote.count > 1 ? "買う ×\(quote.count)" : "買う").font(AppFont.body(11))
                        Text(quote.cost.stimText).font(AppFont.display(14)).monospacedDigit()
                    }
                }
            }
            .buttonStyle(ChunkyButtonStyle(fill: affordable ? Palette.yellow : Palette.panel,
                                           textColor: affordable ? .black : .white,
                                           corner: 12, depth: 4))
            .frame(width: 84, height: 50)
            .disabled(maxed || !affordable)
            .accessibilityLabel(maxed ? "購入済み" : "\(item.name)を\(quote.count)個、\(Int(quote.cost))で買う")
        }
        .padding(12)
        .chunkyPanel(item == .detox ? Palette.tileDark : Palette.panel, corner: 16, depth: 4)
    }
}

// MARK: - エンディング

struct StimEndingView: View {
    let game: StimGame
    var onExit: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathe = false
    @State private var confirmPrestige = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x0B1830), Color(hex: 0x123A4A)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.35), lineWidth: 1.5))
                    .frame(width: 180, height: 180)
                    .scaleEffect(breathe ? 1 : 0.7)
                    .overlay(
                        Text(breathe ? "はいて" : "すって")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.8))
                            .contentTransition(.opacity)
                    )

                VStack(spacing: 10) {
                    Text("スマホを置いて、深呼吸。")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                    Text("あなたは \(game.cellsOpened.formatted()) マスを開け、\n\(game.lifetimeEarned.stimText) の刺激を浴びました。")
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.75))
                    Text("盤面クリア \(game.clears) 回 ・ 実績 \(game.achievements.count) 個")
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .foregroundStyle(.white)

                Spacer()

                VStack(spacing: 12) {
                    Button("タイトルへ", action: onExit)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Capsule().strokeBorder(Color.white.opacity(0.5), lineWidth: 1.5))

                    Button("転生して、もう一度ドパる") { confirmPrestige = true }
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(minHeight: 44)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 24)
            }
        }
        .task {
            guard !reduceMotion else { return }
            while !Task.isCancelled {
                withAnimation(.easeInOut(duration: 4)) { breathe.toggle() }
                try? await Task.sleep(for: .seconds(4))
            }
        }
        .confirmationDialog("転生して最初からはじめますか？（転生ポイント +\(game.prestigeGain)）",
                            isPresented: $confirmPrestige, titleVisibility: .visible) {
            Button("転生する", role: .destructive) {
                withAnimation(.easeInOut(duration: 0.6)) { game.prestige() }
            }
            Button("やめる", role: .cancel) {}
        }
    }
}
