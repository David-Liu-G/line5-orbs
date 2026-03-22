import GameKit

@MainActor
class GameCenterManager: ObservableObject {
    static let shared = GameCenterManager()

    @Published var isAuthenticated = false
    @Published var localPlayer = GKLocalPlayer.local

    // Leaderboard IDs - configure these in App Store Connect
    static let highScoreLeaderboardID = "com.line5.game.highscore"

    // Achievement IDs
    static let firstClearAchievementID = "com.line5.game.firstclear"
    static let score100AchievementID = "com.line5.game.score100"
    static let score500AchievementID = "com.line5.game.score500"
    static let score1000AchievementID = "com.line5.game.score1000"

    private init() {}

    func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            if let vc = viewController {
                // Present the Game Center login view controller
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootVC = windowScene.windows.first?.rootViewController {
                    rootVC.present(vc, animated: true)
                }
                return
            }

            if let error = error {
                print("GameCenter auth error: \(error.localizedDescription)")
                return
            }

            Task { @MainActor in
                self?.isAuthenticated = GKLocalPlayer.local.isAuthenticated
                self?.localPlayer = GKLocalPlayer.local

                if GKLocalPlayer.local.isAuthenticated {
                    print("GameCenter: Authenticated as \(GKLocalPlayer.local.displayName)")
                }
            }
        }
    }

    // MARK: - Leaderboards

    func submitScore(_ score: Int) {
        guard isAuthenticated else { return }

        Task {
            do {
                try await GKLeaderboard.submitScore(
                    score,
                    context: 0,
                    player: GKLocalPlayer.local,
                    leaderboardIDs: [Self.highScoreLeaderboardID]
                )
                print("GameCenter: Score \(score) submitted")
            } catch {
                print("GameCenter: Failed to submit score: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Achievements

    func reportAchievement(id: String, percentComplete: Double = 100.0) {
        guard isAuthenticated else { return }

        Task {
            let achievement = GKAchievement(identifier: id)
            achievement.percentComplete = percentComplete
            achievement.showsCompletionBanner = true

            do {
                try await GKAchievement.report([achievement])
                print("GameCenter: Achievement \(id) reported")
            } catch {
                print("GameCenter: Failed to report achievement: \(error.localizedDescription)")
            }
        }
    }

    func checkAchievements(score: Int, linesCleared: Int) {
        if linesCleared >= 1 {
            reportAchievement(id: Self.firstClearAchievementID)
        }
        if score >= 100 {
            reportAchievement(id: Self.score100AchievementID)
        }
        if score >= 500 {
            reportAchievement(id: Self.score500AchievementID)
        }
        if score >= 1000 {
            reportAchievement(id: Self.score1000AchievementID)
        }
    }

    // MARK: - Show Game Center UI

    func showLeaderboard() {
        guard isAuthenticated else { return }

        let gcVC = GKGameCenterViewController(leaderboardID: Self.highScoreLeaderboardID,
                                               playerScope: .global,
                                               timeScope: .allTime)
        gcVC.gameCenterDelegate = GameCenterDismisser.shared

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(gcVC, animated: true)
        }
    }

    func showAchievements() {
        guard isAuthenticated else { return }

        let gcVC = GKGameCenterViewController(state: .achievements)
        gcVC.gameCenterDelegate = GameCenterDismisser.shared

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(gcVC, animated: true)
        }
    }
}

// Helper to dismiss GKGameCenterViewController
class GameCenterDismisser: NSObject, GKGameCenterControllerDelegate {
    static let shared = GameCenterDismisser()
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
}
