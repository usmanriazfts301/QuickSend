import SwiftUI

// MARK: - Client editor: create or edit. `client == nil` means a new client.

struct ClientEditorView: View {
    @Environment(DataStore.self) private var store
    @Environment(ThemeManager.self) private var theme
    @Environment(\.dismiss) private var dismiss

    let editing: Client?

    @State private var name: String
    @State private var email: String
    @State private var phone: String
    @State private var address: String
    @State private var notes: String
    @State private var toastMsg: String?

    init(client: Client?) {
        self.editing = client
        _name = State(initialValue: client?.name ?? "")
        _email = State(initialValue: client?.email ?? "")
        _phone = State(initialValue: client?.phone ?? "")
        _address = State(initialValue: client?.address ?? "")
        _notes = State(initialValue: client?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    WiseField(label: "Name", text: $name, placeholder: "Sarah Mitchell")
                    WiseField(label: "Email", text: $email, placeholder: "sarah@studio.com",
                              keyboard: .emailAddress)
                    WiseField(label: "Phone", text: $phone, placeholder: "+1 415 555 0132",
                              keyboard: .phonePad)
                    WiseField(label: "Address", text: $address, placeholder: "Street, City")
                    WiseField(label: "Notes", text: $notes, placeholder: "Anything worth remembering")
                }
                .padding(20)
            }
            .background(theme.colors.canvas)
            .navigationTitle(editing == nil ? "New client" : "Edit client")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    WiseLinkButton(title: "Cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                WisePrimaryButton(title: "Save client", icon: "checkmark") {
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
        if var existing = editing {
            existing.name = trimmed
            existing.email = email.trimmingCharacters(in: .whitespacesAndNewlines)
            existing.phone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
            existing.address = address.trimmingCharacters(in: .whitespacesAndNewlines)
            existing.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            store.updateClient(existing)
        } else {
            store.addClient(Client(
                name: trimmed,
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                phone: phone.trimmingCharacters(in: .whitespacesAndNewlines),
                address: address.trimmingCharacters(in: .whitespacesAndNewlines),
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
            ))
        }
        dismiss()
    }

    private func showToast(_ text: String) {
        toastMsg = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            if toastMsg == text { toastMsg = nil }
        }
    }
}
