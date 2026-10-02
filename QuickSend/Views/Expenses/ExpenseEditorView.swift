import SwiftUI
import UIKit
import PhotosUI

// MARK: - Expense editor: fields, receipt photo, on-device OCR scan.

struct ExpenseEditorView: View {
    @Environment(DataStore.self) var store: DataStore
    @Environment(ThemeManager.self) var theme: ThemeManager
    @Environment(\.dismiss) private var dismiss

    let expense: Expense?

    @State private var vendor = ""
    @State private var amountText = ""
    @State private var category = "General"
    @State private var date = Date()
    @State private var notes = ""
    @State private var pickedItem: PhotosPickerItem? = nil
    @State private var pickedImage: UIImage? = nil
    @State private var removeReceipt = false
    @State private var isScanning = false
    @State private var toastMsg: String? = nil

    private let categories = ["General", "Travel", "Software", "Equipment", "Meals", "Office", "Other"]

    init(expense: Expense? = nil) { self.expense = expense }

    /// Image currently attached (newly picked, or the stored one unless flagged for removal).
    private var workingImage: UIImage? {
        if let pickedImage { return pickedImage }
        if removeReceipt { return nil }
        if let name = expense?.receiptName {
            return UIImage(contentsOfFile: store.fileURL(for: name).path)
        }
        return nil
    }

    private var canSave: Bool {
        !vendor.trimmingCharacters(in: .whitespaces).isEmpty && (Double(amountText) ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    WiseCard {
                        VStack(spacing: 14) {
                            WiseField(label: "Vendor", text: $vendor, placeholder: "e.g. Apple Store")
                            WiseField(label: "Amount", text: $amountText, placeholder: "0.00", keyboard: .decimalPad)
                            VStack(alignment: .leading, spacing: 7) {
                                Text("CATEGORY")
                                    .font(.caption).fontWeight(.bold)
                                    .foregroundStyle(theme.colors.textSecondary)
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                    ForEach(categories, id: \.self) { c in
                                        WiseChip(title: c, isOn: category == c) {
                                            category = c
                                            Haptics.tap()
                                        }
                                    }
                                }
                            }
                            DatePicker("Date", selection: $date, displayedComponents: .date)
                                .font(.subheadline)
                            WiseField(label: "Notes", text: $notes, placeholder: "Optional note")
                        }
                    }
                    receiptSection
                }
                .padding()
            }
            .background(theme.colors.canvas)
            .navigationTitle(expense == nil ? "New expense" : "Edit expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.bold)
                        .disabled(!canSave)
                }
            }
            .onAppear(perform: populate)
            .onChange(of: pickedItem != nil) { _, _ in loadPicked() }
            .toast($toastMsg)
        }
    }

    // MARK: - Receipt section

    private var receiptSection: some View {
        WiseCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("RECEIPT")
                    .font(.caption).fontWeight(.bold)
                    .foregroundStyle(theme.colors.textSecondary)
                if let img = workingImage {
                    HStack(spacing: 14) {
                        Image(uiImage: img)
                            .resizable().scaledToFill()
                            .frame(width: 88, height: 88)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        VStack(alignment: .leading, spacing: 10) {
                            PhotosPicker(selection: $pickedItem, matching: .images) {
                                Text("Replace").fontWeight(.semibold)
                                    .foregroundStyle(theme.colors.deep)
                            }
                            Button("Remove", role: .destructive) {
                                pickedImage = nil
                                removeReceipt = true
                                Haptics.tap()
                            }
                            .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                    Button {
                        scanReceipt()
                    } label: {
                        HStack {
                            if isScanning { ProgressView().tint(theme.colors.deep) }
                            Label("Scan receipt", systemImage: "text.viewfinder")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(theme.colors.secondaryBg, in: Capsule())
                        .foregroundStyle(theme.colors.deep)
                    }
                    .buttonStyle(.plain)
                    .disabled(isScanning)
                } else {
                    PhotosPicker(selection: $pickedItem, matching: .images) {
                        VStack(spacing: 8) {
                            Image(systemName: "camera")
                                .font(.system(size: 24))
                                .foregroundStyle(theme.colors.deep)
                            Text("Add receipt photo")
                                .font(.subheadline).fontWeight(.semibold)
                                .foregroundStyle(theme.colors.deep)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 28)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [7, 6]))
                                .foregroundStyle(theme.colors.hair)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Logic

    private func populate() {
        guard let e = expense else { return }
        vendor = e.vendor
        amountText = e.amount == 0 ? "" : String(format: "%.2f", e.amount)
        category = e.category
        date = e.date
        notes = e.notes
    }

    private func loadPicked() {
        Task {
            guard let data = try? await pickedItem?.loadTransferable(type: Data.self),
                  let img = UIImage(data: data) else { return }
            await MainActor.run {
                pickedImage = img
                removeReceipt = false
            }
        }
    }

    /// On-device OCR: fills vendor + amount from the receipt photo.
    private func scanReceipt() {
        guard let img = workingImage, !isScanning else { return }
        isScanning = true
        Haptics.tap()
        recognizeReceiptTotal(img) { total in
            recognizeVendor(img) { v in
                DispatchQueue.main.async {
                    isScanning = false
                    if let total, total > 0 {
                        amountText = String(format: "%.2f", total)
                    }
                    if let v, !v.trimmingCharacters(in: .whitespaces).isEmpty {
                        vendor = v
                    }
                    let shown = total ?? 0
                    toastMsg = total != nil ? "Scanned: \(store.formatMoney(shown))" : "Couldn't read a total"
                    Haptics.success()
                }
            }
        }
    }

    private func save() {
        guard canSave else { return }
        var e = expense ?? Expense(vendor: "", category: "General")
        e.vendor = vendor.trimmingCharacters(in: .whitespaces)
        e.amount = Double(amountText) ?? 0
        e.category = category
        e.date = date
        e.notes = notes.trimmingCharacters(in: .whitespaces)

        if let img = pickedImage,
           let data = img.jpegData(compressionQuality: 0.85),
           let name = store.saveImageData(data, ext: "jpg") {
            if let old = expense?.receiptName { store.deleteMedia(named: old) }
            e.receiptName = name
        } else if removeReceipt, let old = expense?.receiptName {
            store.deleteMedia(named: old)
            e.receiptName = nil
        }

        if expense == nil { store.addExpense(e) } else { store.updateExpense(e) }
        Haptics.success()
        dismiss()
    }
}
