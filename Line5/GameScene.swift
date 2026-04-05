import SpriteKit

class GameScene: SKScene {
    let logic = GameLogic()
    var particleManager: ParticleManager!

    var cellSize: CGFloat = 0
    var boardOrigin: CGPoint = .zero
    var boardPad: CGFloat = 6
    var cellGap: CGFloat = 3

    var cellNodes: [[SKShapeNode]] = []
    var ballNodes: [[BallNode?]] = []
    var selectedPos: GridPos?
    var isAnimating = false
    var auraTimer: TimeInterval = 0

    // Callbacks to SwiftUI
    var onScoreChanged: ((Int) -> Void)?
    var onNextColorsChanged: (([Int]) -> Void)?
    var onGameOver: ((Int) -> Void)?

    private var lastUpdateTime: TimeInterval = 0

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(hex: 0x0a0e1a)
        particleManager = ParticleManager(parent: self)
        layoutBoard()
        logic.reset()
        syncBoard(animated: false)
        notifyUI()
    }

    // MARK: - Layout

    func layoutBoard() {
        let maxBoardWidth: CGFloat = 680
        let effectiveW = min(size.width, maxBoardWidth)
        let totalGap = cellGap * CGFloat(gridCols - 1)
        cellSize = (effectiveW - 32 - boardPad * 2 - totalGap) / CGFloat(gridCols)

        let boardW = boardPad * 2 + CGFloat(gridCols) * cellSize + totalGap
        let boardH = boardPad * 2 + CGFloat(gridRows) * cellSize + CGFloat(gridRows - 1) * cellGap
        boardOrigin = CGPoint(
            x: (size.width - boardW) / 2,
            y: (size.height - boardH) / 2
        )

        // Board background
        let boardBg = SKShapeNode(rect: CGRect(x: boardOrigin.x, y: boardOrigin.y, width: boardW, height: boardH), cornerRadius: 16)
        boardBg.fillColor = UIColor(hex: 0x111827)
        boardBg.strokeColor = UIColor.white.withAlphaComponent(0.08)
        boardBg.lineWidth = 1.5
        boardBg.zPosition = 0
        addChild(boardBg)

        // Create cells
        cellNodes = []
        ballNodes = []
        for r in 0..<gridRows {
            var rowCells: [SKShapeNode] = []
            var rowBalls: [BallNode?] = []
            for c in 0..<gridCols {
                let pos = cellPosition(r: r, c: c)
                let cell = SKShapeNode(rect: CGRect(x: -cellSize/2, y: -cellSize/2, width: cellSize, height: cellSize), cornerRadius: cellSize * 0.2)
                cell.position = pos
                cell.fillColor = UIColor(hex: 0x1a2236)
                cell.strokeColor = .clear
                cell.zPosition = 1
                cell.name = "cell_\(r)_\(c)"
                addChild(cell)
                rowCells.append(cell)
                rowBalls.append(nil)
            }
            cellNodes.append(rowCells)
            ballNodes.append(rowBalls)
        }
    }

    func cellPosition(r: Int, c: Int) -> CGPoint {
        // SpriteKit Y is bottom-up, so flip rows
        let flippedR = gridRows - 1 - r
        let x = boardOrigin.x + boardPad + CGFloat(c) * (cellSize + cellGap) + cellSize / 2
        let y = boardOrigin.y + boardPad + CGFloat(flippedR) * (cellSize + cellGap) + cellSize / 2
        return CGPoint(x: x, y: y)
    }

    func gridFromPoint(_ point: CGPoint) -> GridPos? {
        for r in 0..<gridRows {
            for c in 0..<gridCols {
                let pos = cellPosition(r: r, c: c)
                let half = cellSize / 2
                if point.x >= pos.x - half && point.x <= pos.x + half &&
                   point.y >= pos.y - half && point.y <= pos.y + half {
                    return GridPos(r: r, c: c)
                }
            }
        }
        return nil
    }

    // MARK: - Board Sync

    func syncBoard(animated: Bool) {
        for r in 0..<gridRows {
            for c in 0..<gridCols {
                let color = logic.grid[r][c]
                if color != -1 && ballNodes[r][c] == nil {
                    let ball = BallNode(colorIndex: color, size: cellSize * 0.7)
                    ball.position = cellPosition(r: r, c: c)
                    ball.addGlow()
                    addChild(ball)
                    ballNodes[r][c] = ball
                    if animated { ball.playAppear() }
                } else if color == -1, let existing = ballNodes[r][c] {
                    existing.removeFromParent()
                    ballNodes[r][c] = nil
                }
            }
        }
    }

    func notifyUI() {
        onScoreChanged?(logic.score)
        onNextColorsChanged?(logic.nextColors)

        // Report to Game Center
        Task { @MainActor in
            GameCenterManager.shared.checkAchievements(
                score: logic.score,
                linesCleared: logic.totalLinesCleared
            )
        }
    }

    func reportFinalScore() {
        run(SoundManager.shared.gameOver)
        Task { @MainActor in
            GameCenterManager.shared.submitScore(logic.score)
            GameCenterManager.shared.checkAchievements(
                score: logic.score,
                linesCleared: logic.totalLinesCleared
            )
        }
    }

    // MARK: - Touch

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isAnimating, let touch = touches.first else { return }
        let point = touch.location(in: self)
        guard let pos = gridFromPoint(point) else { return }

        if logic.grid[pos.r][pos.c] != -1 {
            if let sel = selectedPos, sel != pos {
                // Tapped another ball — try swap
                if logic.canSwap(from: sel, to: pos) {
                    run(SoundManager.shared.swap)
                    deselectCurrent()
                    isAnimating = true
                    animateSwap(from: sel, to: pos)
                } else {
                    // Can't swap — just select the new ball
                    deselectCurrent()
                    run(SoundManager.shared.select)
                    selectedPos = pos
                    cellNodes[pos.r][pos.c].fillColor = UIColor(hex: 0x2a2050)
                    ballNodes[pos.r][pos.c]?.playBounce()
                    particleManager.spawnSelect(at: cellPosition(r: pos.r, c: pos.c), colorIndex: logic.grid[pos.r][pos.c])
                }
            } else {
                // Select ball
                deselectCurrent()
                run(SoundManager.shared.select)
                selectedPos = pos
                cellNodes[pos.r][pos.c].fillColor = UIColor(hex: 0x2a2050)
                ballNodes[pos.r][pos.c]?.playBounce()
                particleManager.spawnSelect(at: cellPosition(r: pos.r, c: pos.c), colorIndex: logic.grid[pos.r][pos.c])
            }
        } else if let sel = selectedPos {
            // Try move to empty cell
            if let path = logic.findPath(from: sel, to: pos) {
                run(SoundManager.shared.move)
                deselectCurrent()
                isAnimating = true
                animateMove(from: sel, path: path)
            }
        }
    }

    func deselectCurrent() {
        if let sel = selectedPos {
            cellNodes[sel.r][sel.c].fillColor = UIColor(hex: 0x1a2236)
            ballNodes[sel.r][sel.c]?.stopBounce()
            selectedPos = nil
        }
    }

    // MARK: - Move Animation

    func animateMove(from start: GridPos, path: [GridPos]) {
        guard let ball = ballNodes[start.r][start.c] else { isAnimating = false; return }
        let colorIdx = logic.grid[start.r][start.c]

        // Build action sequence along path
        var actions: [SKAction] = []
        for i in 1..<path.count {
            let target = cellPosition(r: path[i].r, c: path[i].c)
            actions.append(SKAction.move(to: target, duration: 0.04))
            let pathStep = path[i]
            actions.append(SKAction.run { [weak self] in
                self?.particleManager.spawnTrail(at: target, colorIndex: colorIdx)
            })
        }

        let dest = path.last!
        ball.run(SKAction.sequence(actions)) { [weak self] in
            guard let self = self else { return }

            // Update ball node positions
            self.ballNodes[start.r][start.c] = nil
            self.ballNodes[dest.r][dest.c] = ball

            // Execute logic
            let result = self.logic.performMove(from: start, to: dest)
            self.notifyUI()

            switch result {
            case .linesCleared(let removed, _):
                self.animateRemoval(positions: removed) {
                    self.isAnimating = false
                }

            case .ballsSpawned(let spawned, let postRemoved, _):
                self.syncSpawned(spawned) {
                    if !postRemoved.isEmpty {
                        self.animateRemoval(positions: postRemoved) {
                            self.isAnimating = false
                            if self.logic.isGameOver {
                                self.reportFinalScore()
                            self.onGameOver?(self.logic.score)
                            }
                        }
                    } else {
                        self.isAnimating = false
                        if self.logic.isGameOver {
                            self.reportFinalScore()
                            self.onGameOver?(self.logic.score)
                        }
                    }
                }
                self.notifyUI()

            case .gameOver:
                self.syncBoard(animated: true)
                self.isAnimating = false
                self.reportFinalScore()
                            self.onGameOver?(self.logic.score)
            }
        }
    }

    func animateSwap(from a: GridPos, to b: GridPos) {
        guard let ballA = ballNodes[a.r][a.c], let ballB = ballNodes[b.r][b.c] else {
            isAnimating = false
            return
        }

        let colorA = logic.grid[a.r][a.c]
        let colorB = logic.grid[b.r][b.c]

        // Find path with both cells cleared (same as canSwap logic)
        logic.grid[a.r][a.c] = -1
        logic.grid[b.r][b.c] = -1
        let pathAtoB = logic.findPath(from: a, to: b) ?? [a, b]
        logic.grid[a.r][a.c] = colorA
        logic.grid[b.r][b.c] = colorB

        let pathBtoA = Array(pathAtoB.reversed())

        // Build path-following actions for ball A (a → b)
        var actionsA: [SKAction] = []
        for i in 1..<pathAtoB.count {
            let target = cellPosition(r: pathAtoB[i].r, c: pathAtoB[i].c)
            actionsA.append(SKAction.move(to: target, duration: 0.04))
            actionsA.append(SKAction.run { [weak self] in
                self?.particleManager.spawnTrail(at: target, colorIndex: colorA)
            })
        }

        // Build path-following actions for ball B (b → a)
        var actionsB: [SKAction] = []
        for i in 1..<pathBtoA.count {
            let target = cellPosition(r: pathBtoA[i].r, c: pathBtoA[i].c)
            actionsB.append(SKAction.move(to: target, duration: 0.04))
            actionsB.append(SKAction.run { [weak self] in
                self?.particleManager.spawnTrail(at: target, colorIndex: colorB)
            })
        }

        // Bump ballB z-position so they don't overlap weirdly
        ballB.zPosition += 1

        ballA.run(SKAction.sequence(actionsA))
        ballB.run(SKAction.sequence(actionsB)) { [weak self] in
            guard let self = self else { return }
            ballB.zPosition -= 1

            // Update node references
            self.ballNodes[a.r][a.c] = ballB
            self.ballNodes[b.r][b.c] = ballA

            // Execute logic
            let result = self.logic.performSwap(from: a, to: b)
            self.notifyUI()

            switch result {
            case .linesCleared(let removed, _):
                self.animateRemoval(positions: removed) {
                    self.isAnimating = false
                }

            case .ballsSpawned(let spawned, let postRemoved, _):
                self.syncSpawned(spawned) {
                    if !postRemoved.isEmpty {
                        self.animateRemoval(positions: postRemoved) {
                            self.isAnimating = false
                            if self.logic.isGameOver {
                                self.reportFinalScore()
                                self.onGameOver?(self.logic.score)
                            }
                        }
                    } else {
                        self.isAnimating = false
                        if self.logic.isGameOver {
                            self.reportFinalScore()
                            self.onGameOver?(self.logic.score)
                        }
                    }
                }
                self.notifyUI()

            case .gameOver:
                self.syncBoard(animated: true)
                self.isAnimating = false
                self.reportFinalScore()
                self.onGameOver?(self.logic.score)
            }
        }
    }

    func animateRemoval(positions: Set<GridPos>, completion: @escaping () -> Void) {
        var remaining = positions.count
        if remaining == 0 { completion(); return }
        run(SoundManager.shared.clear)

        for pos in positions {
            if let ball = ballNodes[pos.r][pos.c] {
                particleManager.spawnExplosion(at: cellPosition(r: pos.r, c: pos.c), colorIndex: ball.colorIndex)
                ball.playRemove {
                    self.ballNodes[pos.r][pos.c] = nil
                    remaining -= 1
                    if remaining == 0 { completion() }
                }
            } else {
                remaining -= 1
                if remaining == 0 { completion() }
            }
        }
    }

    func syncSpawned(_ positions: [GridPos], completion: @escaping () -> Void) {
        if !positions.isEmpty { run(SoundManager.shared.spawn) }
        for pos in positions {
            let color = logic.grid[pos.r][pos.c]
            if color != -1 {
                let ball = BallNode(colorIndex: color, size: cellSize * 0.7)
                ball.position = cellPosition(r: pos.r, c: pos.c)
                ball.addGlow()
                addChild(ball)
                ballNodes[pos.r][pos.c] = ball
                ball.playAppear()
                particleManager.spawnSelect(at: cellPosition(r: pos.r, c: pos.c), colorIndex: color)
            }
        }
        // Wait for appear animation
        run(SKAction.wait(forDuration: 0.35)) {
            completion()
        }
    }

    // MARK: - Restart

    func restartGame() {
        // Remove all balls
        for r in 0..<gridRows {
            for c in 0..<gridCols {
                ballNodes[r][c]?.removeFromParent()
                ballNodes[r][c] = nil
            }
        }
        selectedPos = nil
        isAnimating = false
        logic.reset()
        syncBoard(animated: true)
        notifyUI()
    }

    // MARK: - Update Loop

    override func update(_ currentTime: TimeInterval) {
        let dt = lastUpdateTime == 0 ? 0 : currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        if dt > 0.1 { return } // skip large gaps

        particleManager.update(dt: dt)

        // Spawn aura particles for selected ball
        if let sel = selectedPos, logic.grid[sel.r][sel.c] != -1 {
            auraTimer += dt
            if auraTimer > 0.05 {
                auraTimer = 0
                particleManager.spawnAura(at: cellPosition(r: sel.r, c: sel.c), colorIndex: logic.grid[sel.r][sel.c])
            }
        }
    }
}
