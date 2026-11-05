import SwiftUI

struct TitleView: View {
    @Binding var difficulty: Difficulty
    var onPlay: () -> Void

    @Environment(PlayerProgress.self) private var progress
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var spin = 0.0
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 18) {
            topBar
            logo
            sampleTiles
            Spacer(minLength: 0)
            playButton
            difficultyPicker
            levelBar
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(Palette.base.ignoresSafeArea())
        .foregroundStyle(.white)
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .presentationDetents([.medium])
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 24).repeatForever(autoreverses: false)) { spin = 360 }
        }
    }

    // MARK: 上部

    private var topBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                Text("連続 \(progress.streak)日")
            }
            .font(AppFont.body(14))
            .sticker(Palette.pink, corner: 999)

            HStack(spacing: 6) {
                Image(systemName: "dollarsign.circle.fill")
                Text(progress.coins.formatted())
            }
            .font(AppFont.body(14))
            .foregroundStyle(Palette.yellow)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(Palette.panel))
            .overlay(Capsule().strokeBorder(Color.black, lineWidth: 3))

            Spacer()

            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill").font(.system(size: 18, weight: .bold))
            }
            .buttonStyle(ChunkyButtonStyle(fill: Palette.panel, textColor: .white, corner: 12, depth: 4))
            .frame(width: 44, height: 44)
            .accessibilityLabel("設定")
        }
    }

    // MARK: ロゴ

    private var logo: some View {
        ZStack {
            Starburst()
                .fill(Palette.pink)
                .overlay(Starburst().stroke(Color.black, lineWidth: 4))
                .frame(width: 320, height: 320)
                .rotationEffect(.degrees(spin))

            VStack(spacing: 10) {
                PopText(text: "ドパガキ", size: 70, color: Palette.yellow, stroke: 3, shadowStep: 6)
                PopText(text: "マインスイーパー", size: 34, color: .white, stroke: 2,
                        shadows: [Palette.cyan], shadowStep: 4)
            }
            .rotationEffect(.degrees(-6))

            Text("脳汁 100%")
                .font(AppFont.body(15))
                .sticker(Palette.cyan, rotation: 8)
                .offset(x: 105, y: 95)
        }
        .frame(height: 280)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("ドパガキマインスイーパー")
    }

    private var sampleTiles: some View {
        HStack(spacing: 6) {
            CellView(cell: Cell(id: 0), size: 42)
            CellView(cell: Cell(id: 1, adjacent: 1, isOpen: true), size: 42)
            CellView(cell: Cell(id: 2, adjacent: 2, isOpen: true), size: 42)
            CellView(cell: Cell(id: 3, isFlagged: true), size: 42)
            CellView(cell: Cell(id: 4, adjacent: 3, isOpen: true), size: 42)
            CellView(cell: Cell(id: 5), size: 42)
        }
        .accessibilityHidden(true)
    }

    // MARK: 下部

    private var playButton: some View {
        Button {
            SoundEngine.shared.play(.fanfare)
            Haptics.impact(.heavy)
            onPlay()
        } label: {
            VStack(spacing: 2) {
                Text("あそぶ！").font(AppFont.display(36))
                Text("STAGE \(progress.stage) ・ \(difficulty.label)").font(AppFont.body(13))
            }
        }
        .buttonStyle(ChunkyButtonStyle(fill: Palette.yellow, corner: 22, depth: 8, border: 4))
        .frame(height: 92)
    }

    private var difficultyPicker: some View {
        HStack(spacing: 10) {
            ForEach(Difficulty.allCases) { d in
                let selected = d == difficulty
                Button {
                    difficulty = d
                    SoundEngine.shared.play(.button)
                    Haptics.impact(.rigid)
                } label: {
                    HStack(spacing: 4) {
                        if selected { Image(systemName: "checkmark").font(.system(size: 13, weight: .black)) }
                        Text(d.label).font(AppFont.body(15))
                    }
                }
                .buttonStyle(ChunkyButtonStyle(fill: selected ? d.color : Palette.panel,
                                               textColor: selected ? .black : .white))
                .frame(height: 56)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
    }

    private var levelBar: some View {
        HStack(spacing: 10) {
            Text("LV.\(progress.level)")
                .font(AppFont.display(18))
                .foregroundStyle(Palette.yellow)
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Palette.well)
                    Capsule().fill(Palette.lime)
                        .frame(width: max(0, g.size.width * progress.levelProgress))
                }
                .overlay(Capsule().strokeBorder(Color.black, lineWidth: 3))
                .clipShape(Capsule())
            }
            .frame(height: 16)
            Text("あと \(progress.xpToNext) XP")
                .font(AppFont.body(13))
                .foregroundStyle(Palette.lavender)
        }
    }
}

struct SettingsView: View {
    @Environment(PlayerProgress.self) private var progress

    var body: some View {
        NavigationStack {
            Form {
                Toggle("効果音", isOn: binding(\.soundOn))
                Toggle("振動", isOn: binding(\.hapticsOn))
                Toggle("画面の揺れ", isOn: binding(\.shakeOn))
                Section {
                    LabeledContent("ベストスコア", value: progress.bestScore.formatted())
                    LabeledContent("ステージ", value: "\(progress.stage)")
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func binding(_ keyPath: ReferenceWritableKeyPath<PlayerProgress, Bool>) -> Binding<Bool> {
        Binding(
            get: { progress[keyPath: keyPath] },
            set: {
                progress[keyPath: keyPath] = $0
                progress.save()
            }
        )
    }
}
