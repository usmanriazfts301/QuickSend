import SwiftUI

@main
struct QuickSendApp: App {
    @State private var store = DataStore()
    @State private var theme = ThemeManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(theme)
                .tint(theme.colors.accent)
                .onAppear { Notify.requestAuthorization() }
        }
    }
}

/// Routes onboarding vs main app.
struct RootView: View {
    @Environment(DataStore.self) private var store

    var body: some View {
        if store.isOnboarded {
            MainTabView()
        } else {
            OnboardingView()
        }
    }
}
