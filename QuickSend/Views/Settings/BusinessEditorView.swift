import SwiftUI

// MARK: - Business profile editor.

struct BusinessEditorView: View {
    @Environment(DataStore.self) var store: DataStore
    @Environment(ThemeManager.self) var theme: ThemeManager
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var address = ""
    @State private var website = ""
    @State private var currency = "USD"

    private let currencies = ["USD", "EUR", "GBP", "PKR", "AED", "INR"]

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                WiseCard {
                    VStack(spacing: 14) {
                        WiseField(label: "Business name", text: $name, placeholder: "Usman Studio")
                        WiseField(label: "Email", text: $email, placeholder: "hello@studio.com", keyboard: .emailAddress)
                        WiseField(label: "Phone", text: $phone, placeholder: "+1 555 000 1234", keyboard: .phonePad)
                        WiseField(label: "Address", text: $address, placeholder: "Street, City")
                        WiseField(label: "Website", text: $website, placeholder: "studio.com", keyboard: .URL)
                        VStack(alignment: .leading, spacing: 7) {
                            Text("CURRENCY")
                                .font(.caption).fontWeight(.bold)
                                .foregroundStyle(theme.colors.textSecondary)
                            Picker("Currency", selection: $currency) {
                                ForEach(currencies, id: \.self) { Text($0) }
                            }
                            .pickerStyle(.menu)
                            .padding(13)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(theme.colors.card)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(theme.colors.hair, lineWidth: 1)
                            )
                        }
                    }
                }
                WisePrimaryButton(title: "Save") { save() }
            }
            .padding()
        }
        .background(theme.colors.canvas)
        .navigationTitle("Business")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: populate)
    }

    private func populate() {
        let b = store.business
        name = b.name; email = b.email; phone = b.phone
        address = b.address; website = b.website; currency = b.currency
    }

    private func save() {
        store.business.name = name.trimmingCharacters(in: .whitespaces)
        store.business.email = email.trimmingCharacters(in: .whitespaces)
        store.business.phone = phone.trimmingCharacters(in: .whitespaces)
        store.business.address = address.trimmingCharacters(in: .whitespaces)
        store.business.website = website.trimmingCharacters(in: .whitespaces)
        store.business.currency = currency
        store.save()
        Haptics.success()
        dismiss()
    }
}
