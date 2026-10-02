import SwiftUI

// MARK: - Record a payment against a document

struct RecordPaymentView: View {
    @Environment(DataStore.self) private var store: DataStore
    @Environment(ThemeManager.self) private var theme: ThemeManager
    @Environment(\.dismiss) private var dismiss

    let doc: InvoiceDocument

    @State private var amountText: String
    @State private var method: String = "Card"
    @State private var date: Date = Date()
    @State private var message: String? = nil

    private let methods = ["Card", "ACH", "PayPal", "Venmo", "Cash"]

    private var balance: Double { store.docTotals(doc).balance }

    init(doc: InvoiceDocument) {
        self.doc = doc
        _amountText = State(initialValue: String(format: "%.2f", docTotals(of: doc).balance))
    }

    var body: some View {
        let c = theme.colors
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    WiseCard {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("OUTSTANDING BALANCE")
                                .font(.caption).fontWeight(.bold)
                                .foregroundStyle(c.textSecondary)
                            Text(store.formatMoney(balance))
                                .font(.wiseDisplay(34))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    WiseCard {
                        VStack(spacing: 14) {
                            WiseField(label: "Amount", text: $amountText,
                                      placeholder: "0.00", keyboard: .decimalPad)
                            VStack(alignment: .leading, spacing: 7) {
                                Text("METHOD")
                                    .font(.caption).fontWeight(.bold)
                                    .foregroundStyle(c.textSecondary)
                                Picker("Method", selection: $method) {
                                    ForEach(methods, id: \.self) { m in
                                        Text(m).tag(m)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                            VStack(alignment: .leading, spacing: 7) {
                                Text("DATE")
                                    .font(.caption).fontWeight(.bold)
                                    .foregroundStyle(c.textSecondary)
                                DatePicker("", selection: $date, displayedComponents: .date)
                                    .labelsHidden()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }

                    // The single primary CTA on this screen.
                    WisePrimaryButton(title: "Record payment", icon: "checkmark") {
                        record()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(c.canvas)
            .navigationTitle("Record payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .toast($message)
        }
    }

    private func record() {
        guard let amount = Double(amountText), amount > 0 else {
            message = "Enter a valid amount"
            return
        }
        store.recordPayment(doc: doc, amount: amount, method: method, date: date)
        Haptics.success()
        dismiss()
    }
}
