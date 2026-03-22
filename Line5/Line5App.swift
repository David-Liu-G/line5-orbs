import SwiftUI

@main
struct Line5App: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .onAppear {
                    GameCenterManager.shared.authenticate()
                }
        }
    }
}
