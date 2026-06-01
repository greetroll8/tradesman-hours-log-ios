import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var subscriptions: SubscriptionManager

    @State private var showPaywall = false

    private static let currencyCodes = ["USD", "EUR", "GBP", "RUB", "CAD", "AUD"]

    var body: some View {
        NavigationStack {
            Form {
                Section("settings.section.billing") {
                    HStack {
                        Text("field.defaultRate")
                        Spacer()
                        TextField("field.defaultRate",
                                  value: Binding(
                                    get: { store.settings.defaultRate },
                                    set: { var s = store.settings; s.defaultRate = $0; store.updateSettings(s) }),
                                  format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    Picker("settings.currency",
                           selection: Binding(
                            get: { store.settings.currency },
                            set: { var s = store.settings; s.currency = $0; store.updateSettings(s) })) {
                        ForEach(Self.currencyCodes, id: \.self) { code in
                            Text(code).tag(code)
                        }
                    }
                }

                Section("settings.section.rounding") {
                    Picker("settings.roundingRule",
                           selection: Binding(
                            get: { store.settings.rounding },
                            set: { var s = store.settings; s.rounding = $0; store.updateSettings(s) })) {
                        ForEach(RoundingRule.allCases) { rule in
                            Text(LocalizedStringKey(rule.localizationKey)).tag(rule)
                        }
                    }
                    Text("settings.roundingHint")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section("settings.section.reminders") {
                    Toggle("settings.reminderEnabled",
                           isOn: Binding(
                            get: { store.settings.reminderEnabled },
                            set: { var s = store.settings; s.reminderEnabled = $0; store.updateSettings(s) }))
                }

                Section("settings.section.subscription") {
                    if subscriptions.isPro {
                        Label("settings.proActive", systemImage: "checkmark.seal.fill")
                            .foregroundColor(.green)
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            Label("settings.upgradePro", systemImage: "star.fill")
                        }
                    }
                }

                Section("settings.section.about") {
                    LabeledContent("settings.version", value: appVersion)
                }
            }
            .navigationTitle("tab.settings")
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }
}
