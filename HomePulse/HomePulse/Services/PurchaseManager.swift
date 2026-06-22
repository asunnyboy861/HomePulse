import Foundation
import StoreKit
import Combine

final class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()

    @Published var isPro: Bool = false
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var loadError: String?

    private let productIds: Set<String> = [
        "com.zzoutuo.HomePulse.pro.lifetime",
        "com.zzoutuo.HomePulse.pro.yearly",
        "com.zzoutuo.HomePulse.pro.monthly"
    ]

    private var transactionListener: Task<Void, Never>?

    private init() {
        transactionListener = listenForTransactions()
        Task {
            await loadProducts()
            await checkPurchased()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    func loadProducts() async {
        isLoading = true
        loadError = nil

        do {
            let storeProducts = try await Product.products(for: productIds)
            products = storeProducts.sorted { $0.price < $1.price }
            isLoading = false
        } catch {
            loadError = "Unable to load purchase options."
            isLoading = false
        }
    }

    func purchase(_ product: Product) async -> Bool {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await checkPurchased()
                    await transaction.finish()
                    return true
                }
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            loadError = "Purchase failed: \(error.localizedDescription)"
        }
        return false
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await checkPurchased()
        } catch {
            loadError = "Restore failed: \(error.localizedDescription)"
        }
    }

    private func checkPurchased() async {
        for productId in productIds {
            if let result = await Transaction.currentEntitlement(for: productId) {
                if case .verified(let transaction) = result {
                    isPro = transaction.revocationDate == nil
                    return
                }
            }
        }
        isPro = false
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    Task { @MainActor [weak self] in
                        await self?.checkPurchased()
                    }
                }
            }
        }
    }

    var lifetimeProduct: Product? {
        products.first { $0.id == "com.zzoutuo.HomePulse.pro.lifetime" }
    }

    var yearlyProduct: Product? {
        products.first { $0.id == "com.zzoutuo.HomePulse.pro.yearly" }
    }

    var monthlyProduct: Product? {
        products.first { $0.id == "com.zzoutuo.HomePulse.pro.monthly" }
    }
}
