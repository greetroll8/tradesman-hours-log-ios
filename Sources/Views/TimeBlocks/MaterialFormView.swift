import SwiftUI

/// Material entry / edit with validation: quantity > 0, unit cost >= 0, markup 0-300.
struct MaterialFormView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let jobId: UUID
    let timeBlockId: UUID?
    let material: Material?

    @State private var name: String = ""
    @State private var quantity: Double = 1
    @State private var unitCost: Double = 0
    @State private var markup: Double = 0
    @State private var billable: Bool = true

    private var validationError: LocalizedStringKey? {
        if name.trimmingCharacters(in: .whitespaces).isEmpty { return "mat.error.name" }
        if quantity <= 0 { return "mat.error.quantity" }
        if unitCost < 0 { return "mat.error.unitCost" }
        if markup < 0 || markup > 300 { return "mat.error.markup" }
        return nil
    }

    private var lineTotal: Double {
        quantity * unitCost * (1 + markup / 100)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("mat.section.item") {
                    TextField("field.name", text: $name)
                    HStack {
                        Text("field.quantity")
                        Spacer()
                        TextField("field.quantity", value: $quantity, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("field.unitCost")
                        Spacer()
                        TextField("field.unitCost", value: $unitCost, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section("mat.section.markup") {
                    Stepper(value: $markup, in: 0...300, step: 5) {
                        Text("mat.markupValue \(Int(markup))")
                    }
                    Toggle("field.billable", isOn: $billable)
                }

                Section("mat.section.total") {
                    HStack {
                        Text("mat.lineTotal")
                        Spacer()
                        AmountText(amount: lineTotal, currency: store.settings.currency)
                            .fontWeight(.semibold)
                    }
                }

                if let err = validationError {
                    Section {
                        Label(err, systemImage: "exclamationmark.triangle")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle(material == nil ? "mat.titleNew" : "mat.titleEdit")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save") { save() }
                        .disabled(validationError != nil)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let m = material else { return }
        name = m.name
        quantity = m.quantity
        unitCost = m.unitCost
        markup = m.markup
        billable = m.billable
    }

    private func save() {
        var result = material ?? Material(jobId: jobId, timeBlockId: timeBlockId,
                                          name: "", quantity: 1, unitCost: 0,
                                          markup: 0, billable: true)
        result.jobId = jobId
        if material == nil { result.timeBlockId = timeBlockId }
        result.name = name.trimmingCharacters(in: .whitespaces)
        result.quantity = quantity
        result.unitCost = unitCost
        result.markup = markup
        result.billable = billable
        store.upsert(result)
        dismiss()
    }
}
