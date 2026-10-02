import SwiftUI

// MARK: - Root tab bar. DocsListView / ClientListView / CatalogView are
// written by sibling agents — referenced here by their exact names.

struct MainTabView: View {
    @Environment(ThemeManager.self) private var theme: ThemeManager

    var body: some View {
        TabView {
            DocsListView()
                .tabItem { Label("Documents", systemImage: "doc.text") }
            ClientListView()
                .tabItem { Label("Clients", systemImage: "person.2") }
            CatalogView()
                .tabItem { Label("Items", systemImage: "cube.box") }
            ExpenseListView()
                .tabItem { Label("Expenses", systemImage: "receipt") }
            MoreView()
                .tabItem { Label("More", systemImage: "ellipsis.circle") }
        }
        .tint(theme.colors.deep)
    }
}
