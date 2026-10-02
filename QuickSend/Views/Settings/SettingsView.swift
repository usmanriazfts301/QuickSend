import SwiftUI

// MARK: - Settings: business, defaults, template, theme, plan, notifications, danger zone.

struct SettingsView: View {
    @Environment(DataStore.self) var store: DataStore
    @Environment(ThemeManager.self) var theme: ThemeManager

    @State private var confirmReset = false

    private let plans: [(name: String, price: String, features: [String])] = [
        ("Essentials", "$0", ["Unlimited invoices & estimates", "Client manager", "PDF export"]),
        ("Plus", "$9.99/mo", ["Online payments + QR codes", "Read receipts & overdue alerts", "Receipt scanning & expenses", "All invoice templates"]),
        ("Premium", "$19.99/mo", ["Everything in Plus", "Revenue reports & analytics", "Deposit requests on estimates", "Signatures & photo attachments"]),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    businessCard
                    defaultsCard
                    templateCard
                    themeCard
                    planCard
                    notificationsRow
                    dangerCard
                    aboutRow
                }
                .padding()
            }
            .background(theme.colors.canvas)
            .navigationTitle("Settings")
            .confirmationDialog("Reset demo data?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Reset", role: .destructive) {
                    store.resetDemo()
                    Haptics.success()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("All invoices, clients and expenses return to the original demo set.")
            }
        }
    }

    // MARK: - Cards

    private var businessCard: some View {
        WiseCard {
            NavigationLink(destination: BusinessEditorView()) {
                HStack(spacing: 14) {
                    AvatarView(name: store.business.name.isEmpty ? "?" : store.business.name, size: 52)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(store.business.name.isEmpty ? "Your business" : store.business.name)
                            .font(.headline)
                            .foregroundStyle(theme.colors.ink)
                        Text(store.business.email.isEmpty ? "Add business details" : store.business.email)
                            .font(.subheadline)
                            .foregroundStyle(theme.colors.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(theme.colors.textSecondary)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var defaultsCard: some View {
        WiseCard {
            VStack(alignment: .leading, spacing: 4) {
                Text("DEFAULTS")
                    .font(.caption).fontWeight(.bold)
                    .foregroundStyle(theme.colors.textSecondary)
                    .padding(.bottom, 8)
                DefaultsEditorView()
            }
        }
    }

    private var templateCard: some View {
        WiseCard {
            VStack(alignment: .leading, spacing: 4) {
                Text("INVOICE TEMPLATE")
                    .font(.caption).fontWeight(.bold)
                    .foregroundStyle(theme.colors.textSecondary)
                    .padding(.bottom, 8)
                ForEach(InvoiceTemplate.allCases) { t in
                    Button {
                        store.business.template = t
                        store.save()
                        Haptics.tap()
                    } label: {
                        HStack(spacing: 12) {
                            templateSwatch(t)
                            Text(t.label)
                                .font(.subheadline).fontWeight(.semibold)
                                .foregroundStyle(theme.colors.ink)
                            Spacer()
                            if store.business.template == t {
                                Image(systemName: "checkmark")
                                    .fontWeight(.bold)
                                    .foregroundStyle(theme.colors.deep)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    /// Flat mini preview of each template's header treatment.
    private func templateSwatch(_ t: InvoiceTemplate) -> some View {
        let c = theme.colors
        return ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white)
                .frame(width: 52, height: 38)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(c.hair, lineWidth: 1))
            switch t {
            case .classic:
                RoundedRectangle(cornerRadius: 3).fill(c.deep).frame(width: 30, height: 5).offset(x: 7, y: 7)
            case .forest:
                RoundedRectangle(cornerRadius: 6).fill(c.deep).frame(width: 52, height: 14)
            case .bold:
                RoundedRectangle(cornerRadius: 3).fill(c.accent).frame(width: 30, height: 8).offset(x: 7, y: 6)
            }
            RoundedRectangle(cornerRadius: 2).fill(c.hair).frame(width: 38, height: 3).offset(x: 7, y: 24)
            RoundedRectangle(cornerRadius: 2).fill(c.hair).frame(width: 26, height: 3).offset(x: 7, y: 30)
        }
    }

    private var themeCard: some View {
        WiseCard {
            VStack(alignment: .leading, spacing: 4) {
                Text("COLOR THEME")
                    .font(.caption).fontWeight(.bold)
                    .foregroundStyle(theme.colors.textSecondary)
                    .padding(.bottom, 8)
                ForEach(AppTheme.allCases) { t in
                    Button {
                        theme.set(t)
                        Haptics.tap()
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle().fill(t.colors.deep).frame(width: 30, height: 30)
                                Circle().fill(t.colors.accent).frame(width: 30, height: 30)
                                    .mask(HalfMask())
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(t.label)
                                    .font(.subheadline).fontWeight(.semibold)
                                    .foregroundStyle(theme.colors.ink)
                                Text(t.blurb)
                                    .font(.caption)
                                    .foregroundStyle(theme.colors.textSecondary)
                            }
                            Spacer()
                            if theme.current == t {
                                Image(systemName: "checkmark")
                                    .fontWeight(.bold)
                                    .foregroundStyle(theme.colors.deep)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var planCard: some View {
        WiseCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("PLAN")
                    .font(.caption).fontWeight(.bold)
                    .foregroundStyle(theme.colors.textSecondary)
                ForEach(plans, id: \.name) { p in
                    Button {
                        store.business.plan = p.name
                        store.save()
                        Haptics.tap()
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(p.name)
                                    .font(.headline)
                                    .foregroundStyle(theme.colors.ink)
                                Spacer()
                                Text(p.price)
                                    .font(.subheadline).fontWeight(.bold)
                                    .foregroundStyle(theme.colors.deep)
                                if store.business.plan == p.name {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(theme.colors.success)
                                }
                            }
                            ForEach(p.features, id: \.self) { f in
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark")
                                        .font(.caption).fontWeight(.bold)
                                        .foregroundStyle(theme.colors.success)
                                    Text(f).font(.caption)
                                        .foregroundStyle(theme.colors.textSecondary)
                                }
                            }
                        }
                        .padding(14)
                        .background(theme.colors.secondaryBg, in: RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(store.business.plan == p.name ? theme.colors.deep : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var notificationsRow: some View {
        WiseCard {
            NavigationLink(destination: NotificationsView()) {
                HStack(spacing: 14) {
                    IconTile(icon: "bell", size: 44)
                    Text("Notifications")
                        .font(.headline)
                        .foregroundStyle(theme.colors.ink)
                    Spacer()
                    if store.unreadCount > 0 {
                        Text("\(store.unreadCount)")
                            .font(.caption).fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 9).padding(.vertical, 4)
                            .background(theme.colors.deep, in: Capsule())
                    }
                    Image(systemName: "chevron.right")
                        .foregroundStyle(theme.colors.textSecondary)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var dangerCard: some View {
        WiseCard {
            Button(role: .destructive) { confirmReset = true } label: {
                HStack {
                    Text("Reset demo data")
                        .font(.headline)
                        .foregroundStyle(theme.colors.danger)
                    Spacer()
                    Image(systemName: "arrow.counterclockwise")
                        .foregroundStyle(theme.colors.danger)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var aboutRow: some View {
        Text("QuickSend 1.0 — Invoice Maker")
            .font(.caption)
            .foregroundStyle(theme.colors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
    }
}

// MARK: - Half-circle mask for the theme color dots

private struct HalfMask: View {
    var body: some View {
        GeometryReader { g in
            Rectangle()
                .frame(width: g.size.width / 2, height: g.size.height)
                .offset(x: g.size.width / 2)
        }
    }
}

// MARK: - Defaults editor (inline, auto-saves)

private struct DefaultsEditorView: View {
    @Environment(DataStore.self) var store: DataStore
    @Environment(ThemeManager.self) var theme: ThemeManager

    var body: some View {
        @Bindable var s = store
        return VStack(spacing: 12) {
            WiseField(
                label: "Default tax rate (%)",
                text: Binding(
                    get: { s.business.defaultTaxRate == 0 ? "" : String(s.business.defaultTaxRate) },
                    set: { s.business.defaultTaxRate = Double($0) ?? 0; s.save() }
                ),
                keyboard: .decimalPad
            )
            HStack(spacing: 12) {
                WiseField(label: "Invoice prefix", text: autosave(\.invoicePrefix, on: s))
                WiseField(label: "Estimate prefix", text: autosave(\.estimatePrefix, on: s))
                WiseField(label: "Receipt prefix", text: autosave(\.receiptPrefix, on: s))
            }
            WiseField(label: "Default terms", text: autosave(\.defaultTerms, on: s))
            WiseField(label: "Default notes", text: autosave(\.defaultNotes, on: s))
        }
    }

    /// Binding into a BusinessProfile String field that saves on every edit.
    private func autosave(_ kp: WritableKeyPath<BusinessProfile, String>, on s: DataStore) -> Binding<String> {
        Binding(
            get: { s.business[keyPath: kp] },
            set: { s.business[keyPath: kp] = $0; s.save() }
        )
    }
}
