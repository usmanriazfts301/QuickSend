import SwiftUI

// MARK: - Catalog item editor: create or edit. `item == nil` means a new item.

struct CatalogItemEditorView: View {
    @Environment(DataStore.self) private var store
    @Environment(ThemeManager.self) private var theme
    @Environment(\.dismiss) private var dismiss

    let editing: CatalogItem?

    @State private var name: String
    @State private var desc: String
    @State private var rateText: String
    @State private var taxText: String
    @State private var toastMsg: String?

    init(item: CatalogItem?) {
        self.editing = item
        _name = State(initialValue: item?.name ?? "")
        _desc = State(initialValue: item?.desc ?? "")
        _rateText = State(initialValue: item.map { Self.numberString($0.rate) } ?? "")
        _taxText = State(initialValue: item.map { Self.numberString($0.taxRate) } ?? "")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    WiseField(label: "Name", text: $name, placeholder: "Brand identity design")
                    WiseField(label: "Description", text: $desc, placeholder: "What this covers")
                    WiseField(label: "Rate", text: $rateText, placeholder: "0.00",
                              keyboard: .decimalPad)
                    WiseField(label: "Tax rate (%)", text: $taxText, placeholder: "0",
                              keyboard: .decimalPad)
                }
                .padding(20)
            }
            .background(theme.colors.canvas)
            .navigationTitle(editing == nil ? "New item" : "Edit item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    WiseLinkButton(title: "Cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                WisePrimaryButton(title: "Save item", icon: "checkmark") {
                    save()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(theme.colors.canvas)
            }
            .toast($toastMsg)
        }
    }

    // MARK: - Save

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            showToast("Please enter a name")
            return
        }
        let rate = Double(rateText.replacingOccurrences(of: ",", with: ".")) ?? 0
        let tax = Double(taxText.replacingOccurrences(of: ",", with: ".")) ?? 0
        if var existing = editing {
            existing.name = trimmed
            existing.desc = desc.trimmingCharacters(in: .whitespacesAndNewlines)
            existing.rate = max(0, rate)
            existing.taxRate = max(0, tax)
            store.updateItem(existing)
        } else {
            store.addItem(CatalogItem(
                name: trimmed,
                desc: desc.trimmingCharacters(in: .whitespacesAndNewlines),
                rate: max(0, rate),
                taxRate: max(0, tax)
            ))
        }
        dismiss()
    }

    private static func numberString(_ v: Double) -> String {
        v == 0 ? "" : String(format: "%g", v)
    }

    private func showToast(_ text: String) {
        toastMsg = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            if toastMsg == text { toastMsg = nil }
        }
    }
}
