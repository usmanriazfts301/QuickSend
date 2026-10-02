import SwiftUI

// MARK: - Documents list: filter chips, search, cards, FAB

struct DocsListView: View {
    @Environment(DataStore.self) private var store: DataStore
    @Environment(ThemeManager.self) private var theme: ThemeManager

    @State private var typeFilter: DocType? = nil
    @State private var statusFilter: DisplayStatus? = nil
    @State private var query: String = ""
    @State private var showEditor = false

    private var filtered: [InvoiceDocument] {
        store.docs.filter { d in
            if let typeFilter, d.type != typeFilter { return false }
            if let statusFilter, store.displayStatus(d) != statusFilter { return false }
            let q = query.trimmingCharacters(in: .whitespaces)
            if !q.isEmpty {
                let name = store.clientName(for: d)
                guard d.number.localizedCaseInsensitiveContains(q)
                    || name.localizedCaseInsensitiveContains(q) else { return false }
            }
            return true
        }
        .sorted { $0.issueDate > $1.issueDate }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    // Type filter
                    chipRow {
                        WiseChip(title: "All", isOn: typeFilter == nil) { typeFilter = nil }
                        ForEach(DocType.allCases) { t in
                            WiseChip(title: t.plural, isOn: typeFilter == t) { typeFilter = t }
                        }
                    }
                    // Status filter
                    chipRow {
                        WiseChip(title: "All", isOn: statusFilter == nil) { statusFilter = nil }
                        ForEach([DisplayStatus.draft, .sent, .paid, .overdue], id: \.self) { s in
                            WiseChip(title: s.label, isOn: statusFilter == s) { statusFilter = s }
                        }
                    }

                    if filtered.isEmpty {
                        EmptyState(
                            icon: "doc.text",
                            title: "No documents found",
                            body: "Try a different search or filter — or create your first document.",
                            actionTitle: store.docs.isEmpty ? "New document" : nil,
                            action: store.docs.isEmpty ? { showEditor = true } : nil
                        )
                    } else {
                        LazyVStack(spacing: 10) {
                            ForEach(filtered) { doc in
                                NavigationLink(destination: DocDetailView(doc: doc)) {
                                    docRow(doc)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 100) // clear the FAB
            }
            .background(theme.colors.canvas)
            .navigationTitle("Documents")
            .searchable(text: $query, prompt: "Search number or client")
            .overlay(alignment: .bottomTrailing) {
                Button { showEditor = true } label: {
                    Image(systemName: "plus")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(theme.colors.onAccent)
                        .frame(width: 60, height: 60)
                        .background(theme.colors.accent, in: Circle())
                }
                .buttonStyle(.plain)
                .padding(.trailing, 20)
                .padding(.bottom, 24)
                .accessibilityLabel("New document")
            }
            .sheet(isPresented: $showEditor) {
                DocEditorView()
            }
        }
    }

    // Horizontal chip scroller
    @ViewBuilder
    private func chipRow(@ViewBuilder content: () -> some View) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) { content() }
                .padding(.horizontal, 2)
                .padding(.vertical, 2)
        }
    }

    // One document row: number, client + due, total, status, chevron
    private func docRow(_ doc: InvoiceDocument) -> some View {
        let c = theme.colors
        let totals = store.docTotals(doc)
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(doc.number)
                    .font(.wiseDisplay(17))
                    .foregroundStyle(c.ink)
                Text("\(store.clientName(for: doc)) · \(relativeDay(doc.dueDate))")
                    .font(.subheadline)
                    .foregroundStyle(c.textSecondary)
                    .lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Text(store.formatMoney(totals.total))
                    .font(.body).fontWeight(.bold)
                    .foregroundStyle(c.ink)
                StatusPill(status: store.displayStatus(doc))
            }
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(c.textSecondary.opacity(0.6))
        }
        .padding(16)
        .background(c.card)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(c.hair, lineWidth: 1))
    }
}
