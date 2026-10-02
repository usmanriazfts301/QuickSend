import SwiftUI

// MARK: - Notification feed: read receipts, payments, overdue alerts.

struct NotificationsView: View {
    @Environment(DataStore.self) var store: DataStore
    @Environment(ThemeManager.self) var theme: ThemeManager

    private var items: [AppNotification] {
        store.notifications.sorted { $0.date > $1.date }
    }

    /// SF Symbol per notification kind.
    private func icon(for kind: String) -> String {
        switch kind {
        case "opened": return "eye"
        case "paid": return "banknote"
        case "overdue": return "exclamationmark.triangle"
        default: return "info.circle"
        }
    }

    var body: some View {
        Group {
            if items.isEmpty {
                ScrollView {
                    EmptyState(
                        icon: "bell",
                        title: "All quiet",
                        body: "Read receipts, payment alerts and overdue reminders will land here."
                    )
                }
            } else {
                ScrollView {
                    VStack(spacing: 10) {
                        if store.unreadCount > 0 {
                            HStack {
                                Spacer()
                                WiseLinkButton(title: "Mark all read") {
                                    store.markAllNotificationsRead()
                                    Haptics.tap()
                                }
                            }
                        }
                        ForEach(items) { n in
                            Button { markRead(n) } label: {
                                WiseCard {
                                    HStack(spacing: 13) {
                                        IconTile(icon: icon(for: n.kind), size: 44)
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(n.title)
                                                .font(.subheadline).fontWeight(.bold)
                                                .foregroundStyle(theme.colors.ink)
                                            Text(n.body)
                                                .font(.subheadline)
                                                .foregroundStyle(theme.colors.textSecondary)
                                            Text(relativeDay(n.date))
                                                .font(.caption)
                                                .foregroundStyle(theme.colors.textSecondary)
                                        }
                                        Spacer()
                                        if !n.read {
                                            Circle()
                                                .fill(theme.colors.accent)
                                                .frame(width: 10, height: 10)
                                        }
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
        }
        .background(theme.colors.canvas)
        .navigationTitle("Notifications")
    }

    private func markRead(_ n: AppNotification) {
        guard let i = store.notifications.firstIndex(where: { $0.id == n.id }),
              !store.notifications[i].read else { return }
        store.notifications[i].read = true
        store.save()
        Haptics.tap()
    }
}
