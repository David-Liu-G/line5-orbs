import SwiftUI
import SpriteKit

struct ContentView: View {
    @State private var score: Int = 0
    @State private var nextColors: [Int] = []
    @State private var isGameOver = false
    @State private var finalScore: Int = 0
    @State private var showHelp = false
    @ObservedObject private var gameCenter = GameCenterManager.shared
    @ObservedObject private var storeManager = StoreManager.shared
    @State private var scene: GameScene = {
        let scene = GameScene()
        scene.scaleMode = .resizeFill
        return scene
    }()

    var body: some View {
        ZStack {
            Color(UIColor(hex: 0x0a0e1a))
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                VStack(spacing: 4) {
                    HStack {
                        // Score
                        VStack(spacing: 2) {
                            Text("SCORE")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(2)
                                .foregroundColor(.white.opacity(0.3))
                            Text("\(score)")
                                .font(.system(size: 24, weight: .black, design: .rounded))
                                .foregroundColor(Color(UIColor(hex: 0xffb6e0)))
                        }
                        .frame(minWidth: 70)

                        Spacer()

                        // Title + tagline
                        VStack(spacing: 2) {
                            Text("Line5 Orbs")
                                .font(.system(size: 26, weight: .black, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Color(UIColor(hex: 0xff6ec7)),
                                            Color(UIColor(hex: 0x7c83ff)),
                                            Color(UIColor(hex: 0x40e0d0))
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            HStack(spacing: 4) {
                                Text("Line up 5 or more to score")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white.opacity(0.3))
                                Button(action: { showHelp = true }) {
                                    Image(systemName: "questionmark.circle")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.35))
                                }
                            }
                        }

                        Spacer()

                        // Next balls
                        VStack(spacing: 2) {
                            Text("NEXT")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(2)
                                .foregroundColor(.white.opacity(0.3))
                            HStack(spacing: 6) {
                                ForEach(0..<nextColors.count, id: \.self) { i in
                                    Circle()
                                        .fill(Color(BallColor.all[nextColors[i]].primary))
                                        .frame(width: 16, height: 16)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                                        )
                                }
                            }
                        }
                        .frame(minWidth: 70)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 12)

                // Game scene
                SpriteView(scene: scene, options: [.allowsTransparency])
                    .ignoresSafeArea(edges: .horizontal)

                // Bottom bar
                HStack(spacing: 12) {
                    if gameCenter.isAuthenticated {
                        Button(action: {
                            GameCenterManager.shared.showLeaderboard()
                        }) {
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.5))
                                .frame(width: 40, height: 40)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        }
                    }

                    Button(action: {
                        isGameOver = false
                        AdManager.shared.onGameRestart()
                        scene.restartGame()
                    }) {
                        Text("New Game")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .tracking(1)
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.horizontal, 28)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    }

                    if gameCenter.isAuthenticated {
                        Button(action: {
                            GameCenterManager.shared.showAchievements()
                        }) {
                            Image(systemName: "medal.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.5))
                                .frame(width: 40, height: 40)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        }
                    }

                }
                .padding(.vertical, 16)

                // Ad section
                if !storeManager.isAdRemoved {
                    HStack {
                        Button(action: { Task { await storeManager.purchase() } }) {
                            Text("Remove Ads · \(storeManager.displayPrice)")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(Color(UIColor(hex: 0x7c83ff)))
                        }
                        .disabled(storeManager.isPurchasing)

                        Spacer()

                        Button(action: { Task { await storeManager.restore() } }) {
                            Text("Restore")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.3))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 6)

                    BannerAdView()
                        .frame(height: 50)
                }
            }

            // Game over overlay
            if isGameOver {
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                    .onTapGesture { }

                VStack(spacing: 16) {
                    Text("Game Over")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(UIColor(hex: 0xff6ec7)),
                                    Color(UIColor(hex: 0x7c83ff))
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("Score: \(finalScore)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Button(action: {
                        isGameOver = false
                        AdManager.shared.onGameRestart()
                        scene.restartGame()
                    }) {
                        Text("Play Again")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 36)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(UIColor(hex: 0xff6ec7)),
                                        Color(UIColor(hex: 0x7c83ff))
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                    }
                }
                .padding(40)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(UIColor(hex: 0x151c2e)))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                )
                .shadow(color: .black.opacity(0.5), radius: 30)
                .transition(.scale.combined(with: .opacity))
            }

            // Help overlay
            if showHelp {
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                    .onTapGesture { showHelp = false }

                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("How to Play")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(UIColor(hex: 0xff6ec7)),
                                        Color(UIColor(hex: 0x7c83ff)),
                                        Color(UIColor(hex: 0x40e0d0))
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        Spacer()
                        Button(action: { showHelp = false }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        helpRow(icon: "hand.tap.fill", text: "Tap an orb to select it, then tap an empty cell to move it there.")
                        helpRow(icon: "arrow.left.arrow.right", text: "Tap a selected orb, then tap another orb to swap them — if there's a clear path between them.")
                        helpRow(icon: "arrow.triangle.turn.up.right.diamond.fill", text: "Orbs can only move through empty cells — no jumping over others.")
                        helpRow(icon: "line.3.horizontal", text: "Align 5 or more same-color orbs in a row, column, or diagonal to clear them and score points.")
                        helpRow(icon: "plus.circle.fill", text: "After each move, 3 new orbs appear. Plan ahead!")
                        helpRow(icon: "xmark.octagon.fill", text: "Game over when the board is full. Try to keep space open!")
                    }

                    HStack {
                        Spacer()
                        Button(action: { showHelp = false }) {
                            Text("Got it!")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 10)
                                .background(
                                    LinearGradient(
                                        colors: [
                                            Color(UIColor(hex: 0xff6ec7)),
                                            Color(UIColor(hex: 0x7c83ff))
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                        }
                        Spacer()
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(UIColor(hex: 0x151c2e)))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 24)
                .shadow(color: .black.opacity(0.5), radius: 30)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear {
            scene.onScoreChanged = { s in
                withAnimation(.easeOut(duration: 0.2)) { score = s }
            }
            scene.onNextColorsChanged = { colors in
                nextColors = colors
            }
            scene.onGameOver = { s in
                finalScore = s
                withAnimation(.spring(response: 0.4)) { isGameOver = true }
            }
        }
    }

    private func helpRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Color(UIColor(hex: 0x7c83ff)))
                .frame(width: 24)
            Text(text)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
