import SwiftUI

struct Cell: Identifiable, Equatable {
    let id: Int
    var isMine = false
    var adjacent = 0
    var isOpen = false
    var isFlagged = false
}

/// 開いたマスと、起点からの距離（連鎖アニメの遅延に使う）
struct OpenedCell {
    let index: Int
    let depth: Int
}

enum Difficulty: String, CaseIterable, Identifiable {
    case easy, normal, hard

    var id: String { rawValue }

    var label: String {
        switch self {
        case .easy: return "かんたん"
        case .normal: return "ふつう"
        case .hard: return "ガチ"
        }
    }

    var color: Color {
        switch self {
        case .easy: return Palette.cyan
        case .normal: return Palette.pink
        case .hard: return Palette.lime
        }
    }

    var rows: Int {
        switch self {
        case .easy: return 9
        case .normal: return 11
        case .hard: return 13
        }
    }

    var cols: Int { 9 }

    var mines: Int {
        switch self {
        case .easy: return 10
        case .normal: return 17
        case .hard: return 26
        }
    }

    /// ランク判定の基準タイム（秒）
    var parSeconds: Double { Double(mines) * 4 }
}

struct Board {
    let rows: Int
    let cols: Int
    let mineCount: Int
    private(set) var cells: [Cell]
    private(set) var minesPlaced = false

    init(rows: Int, cols: Int, mines: Int) {
        self.rows = rows
        self.cols = cols
        self.mineCount = mines
        self.cells = (0..<(rows * cols)).map { Cell(id: $0) }
    }

    init(difficulty: Difficulty) {
        self.init(rows: difficulty.rows, cols: difficulty.cols, mines: difficulty.mines)
    }

    func row(of i: Int) -> Int { i / cols }
    func col(of i: Int) -> Int { i % cols }

    func neighbors(of i: Int) -> [Int] {
        let r = row(of: i), c = col(of: i)
        var result: [Int] = []
        for dr in -1...1 {
            for dc in -1...1 where !(dr == 0 && dc == 0) {
                let nr = r + dr, nc = c + dc
                if nr >= 0, nr < rows, nc >= 0, nc < cols {
                    result.append(nr * cols + nc)
                }
            }
        }
        return result
    }

    /// 初手のマスとその周囲には地雷を置かない（初手で必ず大きく開く）
    mutating func placeMines(avoiding first: Int) {
        let forbidden = Set(neighbors(of: first) + [first])
        let candidates = cells.indices.filter { !forbidden.contains($0) }.shuffled()
        for i in candidates.prefix(mineCount) {
            cells[i].isMine = true
        }
        for i in cells.indices {
            cells[i].adjacent = neighbors(of: i).filter { cells[$0].isMine }.count
        }
        minesPlaced = true
    }

    /// マスを開く。0 のマスは周囲へ連鎖する（幅優先）
    mutating func open(_ start: Int) -> [OpenedCell] {
        guard !cells[start].isOpen, !cells[start].isFlagged else { return [] }
        var result: [OpenedCell] = []
        var queue: [OpenedCell] = [OpenedCell(index: start, depth: 0)]
        cells[start].isOpen = true
        var head = 0
        while head < queue.count {
            let current = queue[head]
            head += 1
            result.append(current)
            let cell = cells[current.index]
            guard !cell.isMine, cell.adjacent == 0 else { continue }
            for n in neighbors(of: current.index)
            where !cells[n].isOpen && !cells[n].isFlagged && !cells[n].isMine {
                cells[n].isOpen = true
                queue.append(OpenedCell(index: n, depth: current.depth + 1))
            }
        }
        return result
    }

    mutating func close(_ i: Int) {
        cells[i].isOpen = false
    }

    @discardableResult
    mutating func toggleFlag(_ i: Int) -> Bool {
        guard !cells[i].isOpen else { return false }
        cells[i].isFlagged.toggle()
        return true
    }

    mutating func setFlag(_ i: Int, _ flagged: Bool) {
        guard !cells[i].isOpen else { return }
        cells[i].isFlagged = flagged
    }

    var flagCount: Int { cells.filter(\.isFlagged).count }
    var safeTotal: Int { cells.count - mineCount }
    var safeRemaining: Int { cells.filter { !$0.isMine && !$0.isOpen }.count }

    /// 数字マスの周りの旗の数が数字と一致していれば、残りを一括で開く対象を返す
    func chordTargets(_ i: Int) -> [Int] {
        let cell = cells[i]
        guard cell.isOpen, !cell.isMine, cell.adjacent > 0 else { return [] }
        let ns = neighbors(of: i)
        guard ns.filter({ cells[$0].isFlagged }).count == cell.adjacent else { return [] }
        return ns.filter { !cells[$0].isOpen && !cells[$0].isFlagged }
    }
}
