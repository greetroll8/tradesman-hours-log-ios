import SwiftUI

@main
struct TradesmanHoursLogApp: App {
    @StateObject private var store: AppStore
    @StateObject private var timer = TimerController()
    @StateObject private var subscriptions: SubscriptionManager

    init() {
        let store = AppStore()
        _store = StateObject(wrappedValue: store)
        _subscriptions = StateObject(wrappedValue: SubscriptionManager(store: store))
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
                .environmentObject(timer)
                .environmentObject(subscriptions)
        }
    }
}
