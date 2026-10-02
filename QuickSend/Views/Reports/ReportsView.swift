import SwiftUI

// MARK: - Reports: collected / outstanding / overdue + monthly bar chart.

struct ReportsView: View {
    @Environment(DataStore.self) var store: DataStore
    @Environment(ThemeManager.self) var theme: ThemeManager

    private var stats: (collected: Double, outstanding: Double, overdue: Double, monthly: [(String, Double)]) {
        store.revenueStats()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    statCard(title: "Collected", value: stats.collected, color: theme.colors.success, icon: "banknote")
                    statCard(title: "Outstanding", value: stats.outstanding, color: theme.colors.deep, icon: "hourglass")
                    statCard(title: "Overdue", value: stats.overdue, color: theme.colors.danger, icon: "exclamationmark.circle")

                    WiseCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("PAYMENTS BY MONTH")
                                .font(.caption).fontWeight(.bold)
                                .foregroundStyle(theme.colors.textSecondary)
                            if stats.monthly.isEmpty {
                                Text("No payments recorded yet — they’ll show up here once clients start paying.")
                                    .font(.subheadline)
                                    .foregroundStyle(theme.colors.textSecondary)
                                    .padding(.vertical, 12)
                            } else {
                                MonthBarChart(data: stats.monthly)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if store.business.plan == "Essentials" {
                        upsellCard
                    }
                }
                .padding()
            }
            .background(theme.colors.canvas)
            .navigationTitle("Reports")
        }
    }

    // MARK: - Stat card

    private func statCard(title: String, value: Double, color: Color, icon: String) -> some View {
        WiseCard {
            HStack(spacing: 14) {
                IconTile(icon: icon, size: 48)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title.uppercased())
                        .font(.caption).fontWeight(.bold)
                        .foregroundStyle(theme.colors.textSecondary)
                    Text(store.formatMoney(value))
                        .font(.wiseDisplay(30))
                        .foregroundStyle(color)
                }
                Spacer()
            }
        }
    }

    // MARK: - Plus/Premium upsell (Essentials only)

    private var upsellCard: some View {
        WiseCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Go Plus")
                    .font(.wiseDisplay(22))
                    .foregroundStyle(theme.colors.ink)
                Text("Get paid faster with the full toolkit:")
                    .font(.subheadline)
                    .foregroundStyle(theme.colors.textSecondary)
                ForEach([
                    "Online payments + QR codes",
                    "Read receipts & overdue alerts",
                    "Receipt scanning & expenses",
                    "Revenue reports & analytics",
                ], id: \.self) { f in
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark")
                            .fontWeight(.bold)
                            .foregroundStyle(theme.colors.success)
                        Text(f).font(.subheadline)
                    }
                }
                Text("Plus $9.99/mo · Premium $19.99/mo — switch anytime in Settings.")
                    .font(.caption)
                    .foregroundStyle(theme.colors.textSecondary)
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Flat monthly bar chart (no gradients)

private struct MonthBarChart: View {
    @Environment(ThemeManager.self) private var theme: ThemeManager
    let data: [(String, Double)]

    var body: some View {
        let maxV = max(data.map(\.1).max() ?? 1, 0.01)
        HStack(alignment: .bottom, spacing: 10) {
            ForEach(data, id: \.0) { month, value in
                VStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(theme.colors.accent)
                        .frame(height: max(6, 150 * value / maxV))
                    Text(month)
                        .font(.caption2).fontWeight(.semibold)
                        .foregroundStyle(theme.colors.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 186)
    }
}
