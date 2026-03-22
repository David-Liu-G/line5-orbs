import SwiftUI
import SpriteKit

struct ContentView: View {
    @State private var score: Int = 0
    @State private var nextColors: [Int] = []
    @State private var isGameOver = false
    @State private var finalScore: Int = 0
    @ObservedObject private var gameCenter = GameCenterManager.shared
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

                    // Title
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
}
