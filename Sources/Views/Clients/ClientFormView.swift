import SwiftUI

/// Client create / edit. Name is required.
struct ClientFormView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let client: Client?

    @State private var name: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var defaultRate: Double = 0
    @State private var loaded = false

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        Form {
            Section("client.section.identity") {
                TextField("field.name", text: $name)
                TextField("field.email", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                TextField("field.phone", text: $phone)
                    .keyboardType(.phonePad)
            }
            Section("client.section.billing") {
                HStack {
                    Text("field.defaultRate")
                    Spacer()
                    TextField("field.defaultRate", value: $defaultRate, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
        .navigationTitle(client == nil ? "client.titleNew" : "client.titleEdit")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("common.save") { save() }
                    .disabled(!canSave)
            }
        }
        .onAppear {
            guard !loaded else { return }
            loaded = true
            if let c = client {
                name = c.name
                email = c.email ?? ""
                phone = c.phone ?? ""
                defaultRate = c.defaultRate
            } else {
                defaultRate = store.settings.defaultRate
            }
        }
    }

    private func save() {
        var result = client ?? Client(name: "", email: nil, phone: nil,
                                      defaultRate: 0, archivedAt: nil)
        result.name = name.trimmingCharacters(in: .whitespaces)
        result.email = email.isEmpty ? nil : email
        result.phone = phone.isEmpty ? nil : phone
        result.defaultRate = defaultRate
        store.upsert(result)
        dismiss()
    }
}
