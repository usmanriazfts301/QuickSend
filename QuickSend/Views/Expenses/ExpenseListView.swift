import SwiftUI
import UIKit

// MARK: - Expense list: monthly total, category filters, CSV export, swipe-to-delete.

struct ExpenseListView: View {
    @Environment(DataStore.self) var store: DataStore
    @Environment(ThemeManager.self) var theme: ThemeManager

    @State private var filter = "All"
    @State private var showingEditor = false
    @State private var editing: Expense? = nil
    @State private var csvURL: URL? = nil

    private var categories: [String] {
        ["All"] + Set(store.expenses.map(\.category)).sorted()
    }

    private var filtered: [Expense] {
        let all = store.expenses.sorted { $0.date > $1.date }
        return filter == "All" ? all : all.filter { $0.category == filter }
    }

    private var monthTotal: Double {
        let cal = Calendar.current
        return store.expenses
            .filter { cal.isDate($0.date, equalTo: Date(), toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.expenses.isEmpty {
                    ScrollView {
                        EmptyState(
                            icon: "receipt",
                            title: "No expenses yet",
                            body: "Snap a receipt and QuickSend reads the total for you. Perfect for tax time.",
                            actionTitle: "Add expense",
                            action: { showingEditor = true }
                        )
                    }
                } else {
                    List {
                        // Header: month total + category filters
                        Section {
                            WiseCard {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("SPENT THIS MONTH")
                                        .font(.caption).fontWeight(.bold)
                                        .foregroundStyle(theme.colors.textSecondary)
                                    Text(store.formatMoney(monthTotal))
                                        .font(.wiseDisplay(34))
                                        .foregroundStyle(theme.colors.ink)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(categories, id: \.self) { c in
                                        WiseChip(title: c, isOn: filter == c) {
                                            filter = c
                                            Haptics.tap()
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))

                        // Expense rows
                        Section {
                            ForEach(filtered) { e in
                                Button { editing = e } label: { row(e) }
                                    .buttonStyle(.plain)
                            }
                            .onDelete(perform: delete)
                        }
                        .listRowBackground(theme.colors.card)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(theme.colors.canvas)
            .navigationTitle("Expenses")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 18) {
                        if let csvURL {
                            ShareLink(item: csvURL) {
                                Label("Export CSV", systemImage: "square.and.arrow.up")
                            }
                        }
                        Button { showingEditor = true } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingEditor) { ExpenseEditorView() }
            .sheet(item: $editing) { ExpenseEditorView(expense: $0) }
            .onAppear { csvURL = makeExpensesCSV(store.expenses) }
            .onChange(of: store.expenses.count) { _, _ in csvURL = makeExpensesCSV(store.expenses) }
        }
    }

    // MARK: - Row

    private func row(_ e: Expense) -> some View {
        HStack(spacing: 12) {
            if let name = e.receiptName,
               let ui = UIImage(contentsOfFile: store.fileURL(for: name).path) {
                Image(uiImage: ui)
                    .resizable().scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                IconTile(icon: "receipt", size: 44)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(e.vendor).fontWeight(.semibold)
                    .foregroundStyle(theme.colors.ink)
                Text("\(e.category) · \(shortDate(e.date))")
                    .font(.caption)
                    .foregroundStyle(theme.colors.textSecondary)
            }
            Spacer()
            Text(store.formatMoney(e.amount))
                .fontWeight(.bold)
                .foregroundStyle(theme.colors.ink)
        }
        .padding(.vertical, 6)
    }

    private func delete(at offsets: IndexSet) {
        for i in offsets { store.deleteExpense(filtered[i]) }
        Haptics.tap()
    }
}
