import SwiftUI

// MARK: - Client list: search, outstanding balances, swipe-to-delete.

struct ClientListView: View {
    @Environment(DataStore.self) private var store
    @Environment(ThemeManager.self) private var theme

    @State private var query = ""
    @State private var showingEditor = false
    @State private var pendingDelete: Client?
    @State private var confirmingDelete = false

    private var filtered: [Client] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return store.clients }
        return store.clients.filter {
            $0.name.lowercased().contains(q) || $0.email.lowercased().contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.clients.isEmpty {
                    EmptyState(
                        icon: "person.2",
                        title: "No clients yet",
                        body: "Add your first client to start sending invoices in seconds.",
                        actionTitle: "Add client",
                        action: { showingEditor = true }
                    )
                    .padding(.horizontal, 20)
                } else if filtered.isEmpty {
                    EmptyState(
                        icon: "magnifyingglass",
                        title: "No matches",
                        body: "Try a different name or email."
                    )
                    .padding(.horizontal, 20)
                } else {
                    List(filtered) { client in
                        NavigationLink {
                            ClientDetailView(client: client)
                        } label: {
                            clientRow(client)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                pendingDelete = client
                                confirmingDelete = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(theme.colors.canvas)
                }
            }
            .navigationTitle("Clients")
            .searchable(text: $query, prompt: "Search name or email")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingEditor = true } label: {
                        Image(systemName: "plus")
                            .font(.body).fontWeight(.semibold)
                            .foregroundStyle(theme.colors.deep)
                    }
                }
            }
            .sheet(isPresented: $showingEditor) {
                ClientEditorView(client: nil)
            }
            .confirmationDialog(
                "Delete client?",
                isPresented: $confirmingDelete,
                presenting: pendingDelete
            ) { client in
                Button("Delete", role: .destructive) {
                    store.deleteClient(client)
                }
                Button("Cancel", role: .cancel) {}
            } message: { client in
                Text("\(client.name) will be removed. Their documents stay.")
            }
        }
    }

    // MARK: - Row

    private func clientRow(_ client: Client) -> some View {
        let totals = store.clientTotals(client)
        return HStack(spacing: 14) {
            AvatarView(name: client.name, size: 46)
            VStack(alignment: .leading, spacing: 3) {
                Text(client.name)
                    .font(.body).fontWeight(.semibold)
                    .foregroundStyle(theme.colors.ink)
                if !client.email.isEmpty {
                    Text(client.email)
                        .font(.subheadline)
                        .foregroundStyle(theme.colors.textSecondary)
                }
            }
            Spacer()
            if totals.outstanding > 0 {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("OUTSTANDING")
                        .font(.caption2).fontWeight(.bold)
                        .foregroundStyle(theme.colors.textSecondary)
                    Text(store.formatMoney(totals.outstanding))
                        .font(.subheadline).fontWeight(.bold)
                        .foregroundStyle(theme.colors.warning)
                }
            }
        }
        .padding(.vertical, 6)
    }
}
