import Foundation
import StoreKit

enum SubscriptionLimits {
    static let freeClientLimit = 2
    static let freePdfExportLimit = 3
    static let proProductID = "com.starestate.tradesmanhourslog.pro"
}

/// Gates premium features. Purchase is stubbed but the free-tier limits are enforced.
@MainActor
final class SubscriptionManager: ObservableObject {
    @Published var isPro: Bool = false
    @Published var purchaseInFlight: Bool = false
    @Published var lastError: String?

    private unowned let store: AppStore

    init(store: AppStore) {
        self.store = store
        self.isPro = store.isPro
    }

    func refreshFromStore() {
        isPro = store.isPro
    }

    /// Whether another PDF export is permitted under the current tier.
    var canExportPDF: Bool {
        isPro || store.pdfExportCount < SubscriptionLimits.freePdfExportLimit
    }

    var remainingFreeExports: Int {
        max(0, SubscriptionLimits.freePdfExportLimit - store.pdfExportCount)
    }

    func recordPDFExport() {
        store.pdfExportCount += 1
        store.save()
    }

    /// Whether another active client can be created under the current tier.
    var canAddClient: Bool {
        store.canAddClient
    }

    /// Stubbed purchase flow. In a real build this would call
    /// `Product.products(for:)` then `product.purchase()` and verify the
    /// transaction. Here we unlock locally and persist the entitlement.
    func purchasePro() async {
        purchaseInFlight = true
        lastError = nil
        defer { purchaseInFlight = false }

        // Real StoreKit 2 call would look like:
        //   let products = try await Product.products(for: [SubscriptionLimits.proProductID])
        //   guard let product = products.first else { return }
        //   let result = try await product.purchase()
        //   ... verify result ...
        // For this build we simulate a successful purchase.
        try? await Task.sleep(nanoseconds: 400_000_000)
        unlockPro()
    }

    func restorePurchases() async {
        purchaseInFlight = true
        defer { purchaseInFlight = false }
        // Real implementation: try await AppStore.sync() then re-check entitlements.
        try? await Task.sleep(nanoseconds: 300_000_000)
        // Entitlement state is read from persisted store.
        isPro = store.isPro
    }

    private func unlockPro() {
        store.isPro = true
        store.save()
        isPro = true
    }
}
