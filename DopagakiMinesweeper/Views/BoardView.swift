import SwiftUI

struct BoardView: View {
    let game: GameViewModel

    private let gap: CGFloat = 4
    private let pad: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            let rows = game.board.rows
            let cols = game.board.cols
            let size = floor(min(
                (geo.size.width - pad * 2 - gap * CGFloat(cols - 1)) / CGFloat(cols),
                (geo.size.height - pad * 2 - 6 - gap * CGFloat(rows - 1)) / CGFloat(rows)
            ))
            let width = size * CGFloat(cols) + gap * CGFloat(cols - 1) + pad * 2
            let height = size * CGFloat(rows) + gap * CGFloat(rows - 1) + pad * 2

            VStack(spacing: gap) {
                ForEach(0..<rows, id: \.self) { r in
                    HStack(spacing: gap) {
                        ForEach(0..<cols, id: \.self) { c in
                            cellView(index: r * cols + c, size: size)
                        }
                    }
                }
            }
            .padding(pad)
            .chunkyPanel(Palette.boardBG, corner: 18, depth: 6, border: 4)
            .overlay {
                ForEach(game.popups) { popup in
                    PopupView(popup: popup)
                        .position(x: pad + CGFloat(popup.col) * (size + gap) + size / 2,
                                  y: pad + CGFloat(popup.row) * (size + gap) + size / 2)
                }
                .allowsHitTesting(false)
            }
            .frame(width: width, height: height)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
    }

    private func cellView(index i: Int, size: CGFloat) -> some View {
        let cell = game.board.cells[i]
        return CellView(
            cell: cell,
            size: size,
            freshDepth: game.freshDepth[i],
            exploded: game.explodedIndex == i,
            revealMine: game.revealMines,
            pinged: game.radarPing == i
        )
        .contentShape(Rectangle())
        .onTapGesture { game.tap(i) }
        .onLongPressGesture(minimumDuration: 0.3) { game.longPress(i) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText(cell, index: i))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: "旗を立てる・外す") { game.longPress(i) }
    }

    private func accessibilityText(_ cell: Cell, index i: Int) -> String {
        let pos = "\(game.board.row(of: i) + 1)行\(game.board.col(of: i) + 1)列"
        if cell.isFlagged { return "\(pos) 旗" }
        if !cell.isOpen { return "\(pos) 未開封" }
        if cell.isMine { return "\(pos) 地雷" }
        return cell.adjacent == 0 ? "\(pos) 空白" : "\(pos) \(cell.adjacent)"
    }
}

struct CellView: View {
    let cell: Cell
    let size: CGFloat
    var freshDepth: Int? = nil
    var exploded = false
    var revealMine = false
    var pinged = false

    private var corner: CGFloat { size * 0.2 }

    var body: some View {
        ZStack {
            if cell.isOpen {
                openFace
                    .transition(.scale(scale: 0.2).combined(with: .opacity))
            } else if cell.isFlagged {
                flagFace
                    .transition(.scale(scale: 1.5).combined(with: .opacity))
            } else if revealMine && cell.isMine {
                hiddenMineFace
                    .transition(.scale(scale: 0.4).combined(with: .opacity))
            } else {
                tileFace
            }
            if pinged {
                Circle()
                    .strokeBorder(Palette.cyan, lineWidth: 3)
                    .frame(width: size * 1.6, height: size * 1.6)
                    .transition(.scale(scale: 0.3).combined(with: .opacity))
            }
        }
        .frame(width: size, height: size)
        .animation(.spring(response: 0.32, dampingFraction: 0.55)
                    .delay(Double(freshDepth ?? 0) * 0.03), value: cell.isOpen)
        .animation(.spring(response: 0.25, dampingFraction: 0.5), value: cell.isFlagged)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: pinged)
    }

    private var tileFace: some View {
        RoundedRectangle(cornerRadius: corner)
            .fill(Palette.tileDark)
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: corner)
                    .fill(Palette.tile)
                    .padding(.bottom, size * 0.11)
                    .overlay(alignment: .top) {
                        Capsule()
                            .fill(Palette.tileLight)
                            .frame(height: max(2, size * 0.08))
                            .padding(.horizontal, size * 0.2)
                            .padding(.top, size * 0.09)
                    }
            }
            .clipShape(RoundedRectangle(cornerRadius: corner))
            .overlay(RoundedRectangle(cornerRadius: corner).strokeBorder(Color.black, lineWidth: 2))
    }

    private var openFace: some View {
        let fresh = freshDepth != nil
        let fill: Color = cell.isMine
            ? (exploded ? Palette.pink : Palette.orange)
            : (fresh ? Palette.fresh : Palette.well)
        return ZStack {
            RoundedRectangle(cornerRadius: corner).fill(fill)
            RoundedRectangle(cornerRadius: corner)
                .strokeBorder(fresh && !cell.isMine ? Palette.pink : Color.black, lineWidth: 2)
            if cell.isMine {
                MineIcon(color: .black).padding(size * 0.18)
            } else if cell.adjacent > 0 {
                Text("\(cell.adjacent)")
                    .font(AppFont.display(size * 0.55))
                    .foregroundStyle(Palette.number(cell.adjacent))
            }
        }
        .shadow(color: fresh && !cell.isMine ? Palette.pink.opacity(0.8) : .clear, radius: 6)
    }

    private var flagFace: some View {
        ZStack {
            RoundedRectangle(cornerRadius: corner).fill(Palette.yellow)
            RoundedRectangle(cornerRadius: corner).strokeBorder(Color.black, lineWidth: 2)
            Image(systemName: "flag.fill")
                .font(.system(size: size * 0.48, weight: .black))
                .foregroundStyle(Palette.pink)
                .shadow(color: .black, radius: 0, x: 1, y: 1)
        }
    }

    private var hiddenMineFace: some View {
        ZStack {
            RoundedRectangle(cornerRadius: corner).fill(Palette.well)
            RoundedRectangle(cornerRadius: corner).strokeBorder(Color.black, lineWidth: 2)
            MineIcon(color: Palette.pinkSoft).padding(size * 0.2)
        }
    }
}

struct PopupView: View {
    let popup: Popup
    @State private var popped = false
    @State private var faded = false

    var body: some View {
        content
            .scaleEffect(popped ? 1 : 0.3)
            .offset(y: faded ? -64 : (popped ? -16 : 0))
            .opacity(faded ? 0 : 1)
            .onAppear {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.45)) { popped = true }
                withAnimation(.easeIn(duration: 0.4).delay(0.55)) { faded = true }
            }
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var content: some View {
        switch popup.kind {
        case .score:
            PopText(text: popup.text, size: 26, color: .white, shadows: [Palette.pink], shadowStep: 3)
                .rotationEffect(.degrees(-8))
        case .chain:
            Text(popup.text).font(AppFont.display(16)).sticker(Palette.cyan, rotation: 6)
        case .combo:
            Text(popup.text).font(AppFont.display(18)).sticker(Palette.pink, rotation: -8)
        case .info:
            Text(popup.text).font(AppFont.display(16)).sticker(Palette.lime, rotation: -4)
        case .fever:
            PopText(text: popup.text, size: 54, color: Palette.yellow, stroke: 3,
                    shadows: [Palette.pink, .black], shadowStep: 4)
                .rotationEffect(.degrees(-6))
        }
    }
}
