import SwiftUI

/// A tappable quick-action chip used on the Today screen.
struct QuickChip: View {
    let titleKey: LocalizedStringKey
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(titleKey, systemImage: systemImage)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.accentColor.opacity(0.15))
                .foregroundColor(.accentColor)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// A labeled currency amount.
struct AmountText: View {
    let amount: Double
    let currency: String

    var body: some View {
        Text(Formatters.currency(amount, code: currency))
            .monospacedDigit()
    }
}

/// Empty-state placeholder.
struct EmptyStateView: View {
    let titleKey: LocalizedStringKey
    let systemImage: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 42))
                .foregroundColor(.secondary)
            Text(titleKey)
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}
