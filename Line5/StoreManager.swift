import StoreKit

@MainActor
class StoreManager: ObservableObject {
    static let shared = StoreManager()

    @Published var isAdRemoved = false
    @Published var product: Product?
    @Published var isPurchasing = false

    private let productID = "com.line5.game.removeads"

    var displayPrice: String {
        product?.displayPrice ?? "$1.99"
    }

    private init() {
        isAdRemoved = UserDefaults.standard.bool(forKey: "adRemoved")
        Task {
            await loadProduct()
            listenForTransactions()
        }
        Task {
            await checkEntitlements()
        }
    }

    private func loadProduct() async {
        do {
            let products = try await Product.products(for: [productID])
            product = products.first
        } catch {
            print("[StoreManager] Failed to load products: \(error)")
        }
    }

    private func checkEntitlements() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == productID {
                setAdRemoved(true)
                return
            }
        }
    }

    func purchase() async {
        guard let product, !isPurchasing else { return }
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    setAdRemoved(true)
                }
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            print("Purchase failed: \(error)")
        }
    }

    func restore() async {
        do {
            try await AppStore.sync()
        } catch {
            print("Restore failed: \(error)")
        }
        await checkEntitlements()
    }

    private func listenForTransactions() {
        Task.detached {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result,
                   transaction.productID == self.productID {
                    await MainActor.run { self.setAdRemoved(true) }
                    await transaction.finish()
                }
            }
        }
    }

    private func setAdRemoved(_ value: Bool) {
        isAdRemoved = value
        UserDefaults.standard.set(value, forKey: "adRemoved")
    }
}
