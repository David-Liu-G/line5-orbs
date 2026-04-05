import SwiftUI
import GoogleMobileAds

@MainActor
class AdManager: ObservableObject {
    static let shared = AdManager()

    private var interstitialAd: GADInterstitialAd?
    private var gameCount = 0

    static let bannerAdUnitID = "ca-app-pub-3913995959553749/5143302659"
    static let interstitialAdUnitID = "ca-app-pub-3913995959553749/1834816298"

    private init() {}

    func configure() {
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        loadInterstitial()
    }

    private func loadInterstitial() {
        GADInterstitialAd.load(withAdUnitID: Self.interstitialAdUnitID, request: GADRequest()) { [weak self] ad, error in
            if let error {
                print("Interstitial load failed: \(error.localizedDescription)")
                return
            }
            self?.interstitialAd = ad
        }
    }

    /// Call on every game restart. Shows interstitial every 3rd game.
    func onGameRestart() {
        guard !StoreManager.shared.isAdRemoved else { return }
        gameCount += 1
        guard gameCount % 3 == 0 else { return }

        guard let ad = interstitialAd,
              let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = windowScene.windows.first?.rootViewController else {
            loadInterstitial()
            return
        }

        ad.present(fromRootViewController: root)
        interstitialAd = nil
        loadInterstitial()
    }
}

// MARK: - Banner Ad View

struct BannerAdView: UIViewRepresentable {
    func makeUIView(context: Context) -> GADBannerView {
        let banner = GADBannerView(adSize: GADAdSizeBanner)
        banner.adUnitID = AdManager.bannerAdUnitID
        banner.backgroundColor = .clear
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            banner.rootViewController = root
        }
        banner.load(GADRequest())
        return banner
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {}
}
