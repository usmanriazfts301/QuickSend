import SwiftUI
import UIKit

// MARK: - Client detail: contact actions, totals, document history.
// NOTE: DocDetailView is provided by QuickSend/Views/Docs/DocDetailView.swift
// and is referenced here by name/signature: DocDetailView(doc: InvoiceDocument).

struct ClientDetailView: View {
    @Environment(DataStore.self) private var store
    @Environment(ThemeManager.self) private var theme
    @Environment(\.dismiss) private var dismiss

    let clientID: UUID
    init(client: Client) { self.clientID = client.id }

    /// Live lookup — the detail always reflects the latest store state.
    private var client: Client {
        store.clients.first(where: { $0.id == clientID }) ?? Client(name: "—")
    }

    @State private var showingEditor = false
    @State private var confirmingDelete = false
    @State private var toastMsg: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header
                contactCard
                statsRow
                historySection
            }
            .padding(20)
        }
        .background(theme.colors.canvas)
        .navigationTitle("Client")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Edit") { showingEditor = true }
                    Button("Delete", role: .destructive) { confirmingDelete = true }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(theme.colors.deep)
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            ClientEditorView(client: client)
        }
        .confirmationDialog(
            "Delete client?",
            isPresented: $confirmingDelete
        ) {
            Button("Delete", role: .destructive) {
                store.deleteClient(client)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("\(client.name) will be removed. Their documents stay.")
        }
        .toast($toastMsg)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 12) {
            AvatarView(name: client.name, size: 76)
            Text(client.name)
                .font(.wiseDisplay(28))
                .foregroundStyle(theme.colors.ink)
                .multilineTextAlignment(.center)
            if !client.notes.isEmpty {
                Text(client.notes)
                    .font(.subheadline)
                    .foregroundStyle(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // MARK: - Contact actions

    private var contactCard: some View {
        WiseCard {
            VStack(spacing: 4) {
                if !client.phone.isEmpty {
                    contactRow(icon: "phone", title: "Phone", value: client.phone) {
                        openPhone(client.phone)
                    }
                    Divider().background(theme.colors.hair)
                }
                if !client.email.isEmpty {
                    contactRow(icon: "envelope", title: "Email", value: client.email) {
                        openEmail(client.email)
                    }
                    Divider().background(theme.colors.hair)
                }
                if !client.address.isEmpty {
                    contactRow(icon: "mappin", title: "Address", value: client.address) {
                        UIPasteboard.general.string = client.address
                        showToast("Address copied")
                    }
                }
            }
        }
    }

    private func contactRow(icon: String, title: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                IconTile(icon: icon, size: 42)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title.uppercased())
                        .font(.caption2).fontWeight(.bold)
                        .foregroundStyle(theme.colors.textSecondary)
                    Text(value)
                        .font(.body)
                        .foregroundStyle(theme.colors.ink)
                        .lineLimit(2)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption).fontWeight(.semibold)
                    .foregroundStyle(theme.colors.textSecondary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Stats

    private var statsRow: some View {
        let totals = store.clientTotals(client)
        return HStack(spacing: 12) {
            statCard(title: "BILLED", value: store.formatMoney(totals.billed))
            statCard(title: "OUTSTANDING", value: store.formatMoney(totals.outstanding),
                     valueColor: totals.outstanding > 0 ? theme.colors.warning : nil)
        }
    }

    private func statCard(title: String, value: String, valueColor: Color? = nil) -> some View {
        WiseCard {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.caption2).fontWeight(.bold)
                    .foregroundStyle(theme.colors.textSecondary)
                Text(value)
                    .font(.wiseDisplay(24))
                    .foregroundStyle(valueColor ?? theme.colors.ink)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - History

    private var historySection: some View {
        let docs = store.clientDocs(client)
        return VStack(alignment: .leading, spacing: 12) {
            Text("HISTORY")
                .font(.caption).fontWeight(.bold)
                .foregroundStyle(theme.colors.textSecondary)
                .padding(.horizontal, 4)
            if docs.isEmpty {
                WiseCard {
                    Text("No documents yet for this client.")
                        .font(.subheadline)
                        .foregroundStyle(theme.colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                }
            } else {
                WiseCard {
                    VStack(spacing: 0) {
                        ForEach(docs) { doc in
                            NavigationLink {
                                DocDetailView(doc: doc)
                            } label: {
                                historyRow(doc)
                            }
                            .buttonStyle(.plain)
                            if doc.id != docs.last?.id {
                                Divider().background(theme.colors.hair)
                            }
                        }
                    }
                }
            }
        }
    }

    private func historyRow(_ doc: InvoiceDocument) -> some View {
        let totals = store.docTotals(doc)
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(doc.number)
                    .font(.body).fontWeight(.semibold)
                    .foregroundStyle(theme.colors.ink)
                Text(doc.type.label)
                    .font(.caption)
                    .foregroundStyle(theme.colors.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Text(store.formatMoney(totals.total))
                    .font(.subheadline).fontWeight(.bold)
                    .foregroundStyle(theme.colors.ink)
                StatusPill(status: store.displayStatus(doc))
            }
            Image(systemName: "chevron.right")
                .font(.caption).fontWeight(.semibold)
                .foregroundStyle(theme.colors.textSecondary)
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    // MARK: - Actions

    private func openPhone(_ raw: String) {
        let digits = raw.filter { $0.isNumber || $0 == "+" }
        guard let url = URL(string: "tel://\(digits)") else { return }
        UIApplication.shared.open(url)
    }

    private func openEmail(_ address: String) {
        let encoded = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? address
        guard let url = URL(string: "mailto:\(encoded)") else { return }
        UIApplication.shared.open(url)
    }

    private func showToast(_ text: String) {
        toastMsg = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            if toastMsg == text { toastMsg = nil }
        }
    }
}
