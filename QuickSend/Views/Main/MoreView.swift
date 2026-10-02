import SwiftUI

// MARK: - "More" hub: business card + links to Reports, Notifications, Settings.

struct MoreView: View {
    @Environment(DataStore.self) var store: DataStore
    @Environment(ThemeManager.self) var theme: ThemeManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    // Business identity card
                    WiseCard {
                        HStack(spacing: 14) {
                            AvatarView(name: store.business.name.isEmpty ? "?" : store.business.name, size: 52)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(store.business.name.isEmpty ? "QuickSend" : store.business.name)
                                    .font(.wiseDisplay(20))
                                    .foregroundStyle(theme.colors.ink)
                                Text(store.business.plan)
                                    .font(.caption).fontWeight(.bold)
                                    .foregroundStyle(theme.colors.deep)
                                    .padding(.horizontal, 10).padding(.vertical, 4)
                                    .background(theme.colors.secondaryBg, in: Capsule())
                            }
                            Spacer()
                        }
                    }

                    // Navigation rows
                    WiseCard {
                        VStack(spacing: 4) {
                            navRow(icon: "chart.bar", title: "Reports", destination: ReportsView())
                            Divider().background(theme.colors.hair)
                            navRow(icon: "bell", title: "Notifications", destination: NotificationsView(),
                                   badge: store.unreadCount)
                            Divider().background(theme.colors.hair)
                            navRow(icon: "gear", title: "Settings", destination: SettingsView())
                        }
                    }
                }
                .padding()
            }
            .background(theme.colors.canvas)
            .navigationTitle("More")
        }
    }

    private func navRow<D: View>(icon: String, title: String, destination: D, badge: Int = 0) -> some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 14) {
                IconTile(icon: icon, size: 44)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(theme.colors.ink)
                Spacer()
                if badge > 0 {
                    Text("\(badge)")
                        .font(.caption).fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 9).padding(.vertical, 4)
                        .background(theme.colors.deep, in: Capsule())
                }
                Image(systemName: "chevron.right")
                    .foregroundStyle(theme.colors.textSecondary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}
