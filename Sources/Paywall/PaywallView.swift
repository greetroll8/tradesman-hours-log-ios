import SwiftUI

struct PaywallView: View {
    @EnvironmentObject var subscriptions: SubscriptionManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.accentColor)
                        .padding(.top, 24)

                    Text("paywall.title")
                        .font(.title.bold())
                        .multilineTextAlignment(.center)

                    Text("paywall.subtitle")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 14) {
                        FeatureRow(textKey: "paywall.feature.clients")
                        FeatureRow(textKey: "paywall.feature.exports")
                        FeatureRow(textKey: "paywall.feature.support")
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    if let err = subscriptions.lastError {
                        Text(err).foregroundColor(.red).font(.caption)
                    }

                    Button {
                        Task {
                            await subscriptions.purchasePro()
                            if subscriptions.isPro { dismiss() }
                        }
                    } label: {
                        Group {
                            if subscriptions.purchaseInFlight {
                                ProgressView()
                            } else {
                                Text("paywall.unlock")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal)
                    .disabled(subscriptions.purchaseInFlight)

                    Button("paywall.restore") {
                        Task { await subscriptions.restorePurchases() }
                    }
                    .font(.subheadline)
                }
                .padding(.bottom, 24)
            }
            .navigationTitle("paywall.navTitle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.close") { dismiss() }
                }
            }
        }
    }
}

private struct FeatureRow: View {
    let textKey: LocalizedStringKey
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.accentColor)
            Text(textKey)
            Spacer()
        }
    }
}
