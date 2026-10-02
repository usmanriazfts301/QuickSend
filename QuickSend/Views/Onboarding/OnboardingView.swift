import SwiftUI

// MARK: - 3-slide onboarding. Completing (or skipping) flips isOnboarded.

struct OnboardingView: View {
    @Environment(DataStore.self) var store: DataStore
    @Environment(ThemeManager.self) var theme: ThemeManager

    @State private var page = 0

    private let slides: [(icon: String, title: String, body: String)] = [
        ("doc.badge.plus", "Send invoices in 90 seconds",
         "Pick a client, tap your catalog items, and send a beautiful invoice before your coffee cools."),
        ("creditcard", "Get paid online",
         "Cards, ACH, PayPal and Venmo — every invoice carries its own QR code for one-tap payment."),
        ("eye", "Know the moment they open it",
         "Read receipts, paid alerts and automatic overdue nudges. No more chasing."),
    ]

    var body: some View {
        ZStack(alignment: .topTrailing) {
            theme.colors.canvas.ignoresSafeArea()

            TabView(selection: $page) {
                ForEach(slides.indices, id: \.self) { i in
                    slide(slides[i])
                        .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            // Skip on the first two slides only
            if page < slides.count - 1 {
                WiseLinkButton(title: "Skip", action: finish)
                    .padding(.top, 60)
                    .padding(.trailing, 24)
            }
        }
    }

    private func slide(_ s: (icon: String, title: String, body: String)) -> some View {
        VStack(spacing: 0) {
            Spacer()
            IconTile(icon: s.icon, size: 110)
                .padding(.bottom, 36)
            Text(s.title)
                .font(.wiseDisplay(34))
                .foregroundStyle(theme.colors.ink)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
                .padding(.bottom, 16)
            Text(s.body)
                .font(.body)
                .foregroundStyle(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 44)
            Spacer()
            // One primary CTA, only on the final slide
            if s.icon == slides.last?.icon {
                WisePrimaryButton(title: "Get started", action: finish)
                    .padding(.horizontal, 32)
            } else {
                Color.clear.frame(height: 54) // keeps layout rhythm identical
            }
            Spacer().frame(height: 72) // room for the page dots
        }
    }

    private func finish() {
        Haptics.success()
        store.isOnboarded = true
        store.save()
    }
}
