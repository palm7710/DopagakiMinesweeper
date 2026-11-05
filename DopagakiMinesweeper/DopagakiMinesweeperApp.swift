import SwiftUI

@main
struct DopagakiMinesweeperApp: App {
    @State private var progress = PlayerProgress()

    init() {
        AppFont.registerBundledFonts()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(progress)
                .preferredColorScheme(.dark)
        }
    }
}

struct RootView: View {
    @Environment(PlayerProgress.self) private var progress
    @AppStorage("difficulty") private var difficulty: Difficulty = .easy
    @State private var game: GameViewModel?

    var body: some View {
        ZStack {
            Palette.base.ignoresSafeArea()
            if let game {
                GameView(game: game) {
                    withAnimation(.snappy) { self.game = nil }
                }
                .transition(.move(edge: .trailing))
            } else {
                TitleView(difficulty: $difficulty) {
                    progress.markPlayedToday()
                    withAnimation(.snappy) {
                        game = GameViewModel(difficulty: difficulty, progress: progress)
                    }
                }
                .transition(.move(edge: .leading))
            }
        }
    }
}
