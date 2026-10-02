import SwiftUI

// MARK: - Item catalog: saved services/products for one-tap autofill.

struct CatalogView: View {
    @Environment(DataStore.self) private var store
    @Environment(ThemeManager.self) private var theme

    @State private var editingItem: CatalogItem?
    @State private var showingNew = false
    @State private var pendingDelete: CatalogItem?
    @State private var confirmingDelete = false

    var body: some View {
        NavigationStack {
            Group {
                if store.items.isEmpty {
                    EmptyState(
                        icon: "shippingbox",
                        title: "Catalog is empty",
                        body: "Save the services and products you sell to autofill them in seconds.",
                        actionTitle: "Add item",
                        action: { showingNew = true }
                    )
                    .padding(.horizontal, 20)
                } else {
                    List(store.items) { item in
                        Button {
                            editingItem = item
                        } label: {
                            itemRow(item)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                pendingDelete = item
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
            .navigationTitle("Item catalog")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingNew = true } label: {
                        Image(systemName: "plus")
                            .font(.body).fontWeight(.semibold)
                            .foregroundStyle(theme.colors.deep)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if !store.items.isEmpty {
                    Text("Tip: tap an item while editing a document to autofill it.")
                        .font(.footnote)
                        .foregroundStyle(theme.colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(theme.colors.canvas)
                }
            }
            .sheet(isPresented: $showingNew) {
                CatalogItemEditorView(item: nil)
            }
            .sheet(item: $editingItem) { item in
                CatalogItemEditorView(item: item)
            }
            .confirmationDialog(
                "Delete item?",
                isPresented: $confirmingDelete,
                presenting: pendingDelete
            ) { item in
                Button("Delete", role: .destructive) {
                    store.deleteItem(item)
                }
                Button("Cancel", role: .cancel) {}
            } message: { item in
                Text("\(item.name) will be removed from your catalog.")
            }
        }
    }

    // MARK: - Row

    private func itemRow(_ item: CatalogItem) -> some View {
        HStack(spacing: 14) {
            IconTile(icon: "cube", size: 44)
            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.body).fontWeight(.semibold)
                    .foregroundStyle(theme.colors.ink)
                if !item.desc.isEmpty {
                    Text(item.desc)
                        .font(.subheadline)
                        .foregroundStyle(theme.colors.textSecondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(store.formatMoney(item.rate))
                    .font(.subheadline).fontWeight(.bold)
                    .foregroundStyle(theme.colors.ink)
                if item.taxRate > 0 {
                    Text("\(item.taxRate, specifier: "%.1f")% tax")
                        .font(.caption)
                        .foregroundStyle(theme.colors.textSecondary)
                }
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}
