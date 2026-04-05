import Foundation

struct GridPos: Hashable {
    let r: Int
    let c: Int
}

enum MoveResult {
    case linesCleared(removed: Set<GridPos>, points: Int)
    case ballsSpawned(positions: [GridPos], postRemoved: Set<GridPos>, postPoints: Int)
    case gameOver
}

class GameLogic {
    var grid: [[Int]] // -1 = empty, 0..5 = color
    var score: Int = 0
    var nextColors: [Int] = []
    var isGameOver: Bool = false
    var totalLinesCleared: Int = 0

    init() {
        grid = Array(repeating: Array(repeating: -1, count: gridCols), count: gridRows)
    }

    func reset() {
        grid = Array(repeating: Array(repeating: -1, count: gridCols), count: gridRows)
        score = 0
        isGameOver = false
        totalLinesCleared = 0

        generateNextColors()
        _ = spawnBalls()
        generateNextColors()
    }

    func generateNextColors() {
        nextColors = (0..<ballsPerTurn).map { _ in Int.random(in: 0..<numColors) }
    }

    func emptyCells() -> [GridPos] {
        var result: [GridPos] = []
        for r in 0..<gridRows {
            for c in 0..<gridCols {
                if grid[r][c] == -1 { result.append(GridPos(r: r, c: c)) }
            }
        }
        return result
    }

    @discardableResult
    func spawnBalls() -> [GridPos] {
        var empty = emptyCells()
        let count = min(ballsPerTurn, empty.count)
        var spawned: [GridPos] = []
        for i in 0..<count {
            let idx = Int.random(in: 0..<empty.count)
            let pos = empty.remove(at: idx)
            let color = i < nextColors.count ? nextColors[i] : Int.random(in: 0..<numColors)
            grid[pos.r][pos.c] = color
            spawned.append(pos)
        }
        return spawned
    }

    func findPath(from start: GridPos, to end: GridPos) -> [GridPos]? {
        var visited = Array(repeating: Array(repeating: false, count: gridCols), count: gridRows)
        var parent: [[GridPos?]] = Array(repeating: Array(repeating: nil, count: gridCols), count: gridRows)
        var queue: [GridPos] = [start]
        visited[start.r][start.c] = true

        let dirs = [(0, 1), (0, -1), (1, 0), (-1, 0)]

        while !queue.isEmpty {
            let pos = queue.removeFirst()
            if pos == end {
                var path: [GridPos] = []
                var cur: GridPos? = end
                while let p = cur {
                    path.insert(p, at: 0)
                    cur = parent[p.r][p.c]
                }
                return path
            }
            for (dr, dc) in dirs {
                let nr = pos.r + dr
                let nc = pos.c + dc
                guard nr >= 0, nr < gridRows, nc >= 0, nc < gridCols,
                      !visited[nr][nc],
                      grid[nr][nc] == -1 || (nr == end.r && nc == end.c)
                else { continue }
                visited[nr][nc] = true
                parent[nr][nc] = pos
                queue.append(GridPos(r: nr, c: nc))
            }
        }
        return nil
    }

    func findLines() -> Set<GridPos> {
        var toRemove = Set<GridPos>()
        for r in 0..<gridRows {
            for c in 0..<gridCols {
                let color = grid[r][c]
                if color == -1 { continue }
                for (dr, dc) in directions {
                    var cells = [GridPos(r: r, c: c)]
                    var nr = r + dr, nc = c + dc
                    while nr >= 0, nr < gridRows, nc >= 0, nc < gridCols, grid[nr][nc] == color {
                        cells.append(GridPos(r: nr, c: nc))
                        nr += dr; nc += dc
                    }
                    if cells.count >= lineMin {
                        toRemove.formUnion(cells)
                    }
                }
            }
        }
        return toRemove
    }

    func removeLines(_ positions: Set<GridPos>) -> Int {
        for pos in positions {
            grid[pos.r][pos.c] = -1
        }
        let count = positions.count
        let extra = max(0, count - lineMin)
        let points = 10 + extra * extra * 10
        score += points
        totalLinesCleared += 1
        return points
    }

    /// Check if two occupied cells can swap (path exists treating each other's cell as empty)
    func canSwap(from a: GridPos, to b: GridPos) -> Bool {
        // Temporarily clear both cells for pathfinding
        let colorA = grid[a.r][a.c]
        let colorB = grid[b.r][b.c]
        grid[a.r][a.c] = -1
        grid[b.r][b.c] = -1
        let path = findPath(from: a, to: b)
        grid[a.r][a.c] = colorA
        grid[b.r][b.c] = colorB
        return path != nil
    }

    func performSwap(from a: GridPos, to b: GridPos) -> MoveResult {
        let colorA = grid[a.r][a.c]
        let colorB = grid[b.r][b.c]
        grid[a.r][a.c] = colorB
        grid[b.r][b.c] = colorA

        // Check lines at both positions
        let removed = findLines()
        if !removed.isEmpty {
            let points = removeLines(removed)
            return .linesCleared(removed: removed, points: points)
        }

        // No lines — spawn
        let spawned = spawnBalls()
        generateNextColors()

        let postRemoved = findLines()
        if !postRemoved.isEmpty {
            let postPoints = removeLines(postRemoved)
            if emptyCells().isEmpty { isGameOver = true }
            return .ballsSpawned(positions: spawned, postRemoved: postRemoved, postPoints: postPoints)
        }

        if emptyCells().isEmpty {
            isGameOver = true
            return .gameOver
        }

        return .ballsSpawned(positions: spawned, postRemoved: [], postPoints: 0)
    }

    func performMove(from start: GridPos, to end: GridPos) -> MoveResult {
        let color = grid[start.r][start.c]
        grid[start.r][start.c] = -1
        grid[end.r][end.c] = color

        // Check lines at destination
        let removed = findLines()
        if !removed.isEmpty {
            let points = removeLines(removed)
            return .linesCleared(removed: removed, points: points)
        }

        // No lines — spawn
        let spawned = spawnBalls()
        generateNextColors()

        // Check lines from spawned balls
        let postRemoved = findLines()
        if !postRemoved.isEmpty {
            let postPoints = removeLines(postRemoved)
            if emptyCells().isEmpty {
                isGameOver = true
            }
            return .ballsSpawned(positions: spawned, postRemoved: postRemoved, postPoints: postPoints)
        }

        if emptyCells().isEmpty {
            isGameOver = true
            return .gameOver
        }

        return .ballsSpawned(positions: spawned, postRemoved: [], postPoints: 0)
    }
}
