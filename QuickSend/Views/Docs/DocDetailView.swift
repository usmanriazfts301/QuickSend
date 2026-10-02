import SwiftUI

// MARK: - Document detail: header, items, payments, QR, actions (one primary + links)

struct DocDetailView: View {
    @Environment(DataStore.self) private var store: DataStore
    @Environment(ThemeManager.self) private var theme: ThemeManager
    @Environment(\.dismiss) private var dismiss

    let doc: InvoiceDocument

    @State private var showDelete = false
    @State private var showPayment = false
    @State private var showEditor = false
    @State private var showPreview = false
    @State private var convertedDoc: InvoiceDocument? = nil
    @State private var pdfURL: URL? = nil
    @State private var message: String? = nil

    /// Always read the freshest copy from the store.
    private var live: InvoiceDocument {
        store.docs.first(where: { $0.id == doc.id }) ?? doc
    }
    private var totals: DocTotals { store.docTotals(live) }
    private var status: DisplayStatus { store.displayStatus(live) }
    private var client: Client? { store.clients.first(where: { $0.id == live.clientId }) }

    var body: some View {
        let c = theme.colors
        ScrollView {
            VStack(spacing: 14) {
                headerCard
                itemsCard
                if live.type == .estimate && live.depositValue > 0 { depositCard }
                if !live.payments.isEmpty { paymentsCard }
                if live.onlinePayments && status != .paid { qrCard }
                if let sig = live.signaturePNG, let ui = UIImage(data: sig) { signatureCard(ui) }
                if !live.photoNames.isEmpty { photosCard }
                actionArea
                    .padding(.top, 4)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(c.canvas)
        .navigationTitle(live.number)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showPreview = true } label: {
                    Image(systemName: "eye")
                }
            }
        }
        .navigationDestination(isPresented: $showPreview) {
            DocPreviewView(doc: live)
        }
        .navigationDestination(isPresented: Binding(
            get: { convertedDoc != nil },
            set: { if !$0 { convertedDoc = nil } }
        )) {
            if let convertedDoc { DocDetailView(doc: convertedDoc) }
        }
        .sheet(isPresented: $showEditor) { DocEditorView(doc: live) }
        .sheet(isPresented: $showPayment) { RecordPaymentView(doc: live) }
        .confirmationDialog("Delete this \(live.type.label.lowercased())?",
                            isPresented: $showDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                store.deleteDoc(live)
                Haptics.tap()
                dismiss()
            }
        }
        .onAppear { buildPDF() }
        .onChange(of: pdfFingerprint) { buildPDF() }
        .toast($message)
    }

    /// Cheap equatable fingerprint so the cached PDF rebuilds when the doc changes.
    private var pdfFingerprint: String {
        "\(live.id)-\(live.status.rawValue)-\(live.paidTotal)-\(live.items.count)-\(live.number)-\(live.signaturePNG == nil)"
    }

    // MARK: - Cards

    private var headerCard: some View {
        let c = theme.colors
        return WiseCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(live.number).font(.wiseDisplay(28))
                        Text(live.type.label.uppercased())
                            .font(.caption).fontWeight(.bold)
                            .foregroundStyle(c.textSecondary)
                    }
                    Spacer()
                    StatusPill(status: status)
                }
                Divider().background(c.hair)
                HStack(spacing: 12) {
                    AvatarView(name: store.clientName(for: live), size: 46)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(store.clientName(for: live)).fontWeight(.semibold)
                        if let email = client?.email, !email.isEmpty {
                            Text(email).font(.subheadline).foregroundStyle(c.textSecondary)
                        }
                    }
                }
                HStack {
                    dateCell("Issued", live.issueDate)
                    Spacer()
                    dateCell(live.type == .estimate ? "Valid until" : "Due", live.dueDate)
                    Spacer()
                    if let opened = live.openedDate {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Opened").font(.caption).foregroundStyle(c.textSecondary)
                            Text(shortDate(opened)).font(.subheadline).fontWeight(.semibold)
                                .foregroundStyle(c.success)
                        }
                    }
                }
            }
        }
    }

    private func dateCell(_ label: String, _ date: Date) -> some View {
        let c = theme.colors
        return VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption).foregroundStyle(c.textSecondary)
            Text(shortDate(date)).font(.subheadline).fontWeight(.semibold)
        }
    }

    private var itemsCard: some View {
        let c = theme.colors
        return WiseCard {
            VStack(alignment: .leading, spacing: 0) {
                Text("ITEMS").font(.caption).fontWeight(.bold).foregroundStyle(c.textSecondary)
                    .padding(.bottom, 10)
                ForEach(live.items) { item in
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.desc).fontWeight(.medium)
                            Text("\(trimNum(item.qty)) × \(store.formatMoney(item.rate))")
                                .font(.subheadline).foregroundStyle(c.textSecondary)
                        }
                        Spacer()
                        Text(store.formatMoney(item.lineTotal)).fontWeight(.semibold)
                    }
                    .padding(.vertical, 8)
                    Divider().background(c.hair)
                }
                moneyRow("Subtotal", totals.subtotal)
                if totals.discount > 0 { moneyRow("Discount", -totals.discount) }
                moneyRow("Tax (\(trimNum(live.taxRate))%)", totals.tax)
                HStack {
                    Text("Total").font(.wiseDisplay(18))
                    Spacer()
                    Text(store.formatMoney(totals.total)).font(.wiseDisplay(20))
                }
                .padding(.top, 8)
                HStack {
                    Text("Balance due").fontWeight(.bold)
                    Spacer()
                    Text(store.formatMoney(totals.balance)).fontWeight(.bold)
                }
                .padding(12)
                .background(c.secondaryBg, in: RoundedRectangle(cornerRadius: 10))
                .padding(.top, 10)
            }
        }
    }

    private func moneyRow(_ label: String, _ value: Double) -> some View {
        HStack {
            Text(label).foregroundStyle(theme.colors.textSecondary)
            Spacer()
            Text(store.formatMoney(value))
        }
        .font(.subheadline)
        .padding(.vertical, 3)
    }

    private var depositCard: some View {
        let c = theme.colors
        return WiseCard {
            HStack {
                IconTile(icon: "percent", size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Deposit requested").fontWeight(.bold)
                    Text(live.depositType == "pct"
                         ? "\(trimNum(live.depositValue))% of total"
                         : "Fixed amount")
                        .font(.subheadline).foregroundStyle(c.textSecondary)
                }
                Spacer()
                Text(store.formatMoney(store.depositAmount(live)))
                    .font(.wiseDisplay(20)).foregroundStyle(c.success)
            }
        }
    }

    private var paymentsCard: some View {
        let c = theme.colors
        return WiseCard {
            VStack(alignment: .leading, spacing: 0) {
                Text("PAYMENTS").font(.caption).fontWeight(.bold).foregroundStyle(c.textSecondary)
                    .padding(.bottom, 6)
                ForEach(live.payments) { p in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(p.method).fontWeight(.medium)
                            Text(shortDate(p.date)).font(.subheadline).foregroundStyle(c.textSecondary)
                        }
                        Spacer()
                        Text(store.formatMoney(p.amount)).fontWeight(.semibold)
                            .foregroundStyle(c.success)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
    }

    private var qrCard: some View {
        let c = theme.colors
        return WiseCard {
            VStack(spacing: 10) {
                if let ui = qrImage(from: paymentLink(for: live, business: store.business)) {
                    Image(uiImage: ui)
                        .interpolation(.none)
                        .resizable()
                        .frame(width: 180, height: 180)
                }
                Text("Scan to pay \(store.formatMoney(totals.balance))")
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundStyle(c.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func signatureCard(_ ui: UIImage) -> some View {
        let c = theme.colors
        return WiseCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("SIGNATURE").font(.caption).fontWeight(.bold).foregroundStyle(c.textSecondary)
                Image(uiImage: ui)
                    .resizable().scaledToFit()
                    .frame(maxHeight: 90)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var photosCard: some View {
        let c = theme.colors
        return WiseCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("PHOTOS").font(.caption).fontWeight(.bold).foregroundStyle(c.textSecondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(live.photoNames, id: \.self) { name in
                            if let ui = UIImage(contentsOfFile: store.fileURL(for: name).path) {
                                Image(uiImage: ui)
                                    .resizable().scaledToFill()
                                    .frame(width: 96, height: 96)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Action area (Wise rule: ONE primary CTA + underlined links)

    @ViewBuilder
    private var actionArea: some View {
        VStack(spacing: 14) {
            switch (live.type, status) {
            case (.estimate, .draft):
                WisePrimaryButton(title: "Send estimate", icon: "paperplane") {
                    store.markSent(live); Haptics.success(); message = "Estimate sent"
                }
                linkRow([
                    ("Convert to invoice", { convert() }),
                    ("Edit", { showEditor = true }),
                    ("Delete", { showDelete = true }),
                ])
            case (.estimate, _):
                WisePrimaryButton(title: "Convert to invoice", icon: "arrow.triangle.2.circlepath") {
                    convert()
                }
                linkRow([
                    ("Preview / PDF", { showPreview = true }),
                    ("Edit", { showEditor = true }),
                    ("Delete", { showDelete = true }),
                ])
            case (_, .draft):
                WisePrimaryButton(title: "Send \(live.type.label)", icon: "paperplane") {
                    store.markSent(live); Haptics.success(); message = "\(live.type.label) sent"
                }
                linkRow([
                    ("Edit", { showEditor = true }),
                    ("Delete", { showDelete = true }),
                ])
            case (_, .sent), (_, .overdue):
                WisePrimaryButton(title: "Record payment", icon: "creditcard") {
                    showPayment = true
                }
                linkRow([
                    ("Preview / PDF", { showPreview = true }),
                    ("Edit", { showEditor = true }),
                ])
            case (_, .paid):
                if let pdfURL {
                    ShareLink(item: pdfURL) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share PDF").fontWeight(.semibold)
                        }
                        .font(.body)
                        .foregroundStyle(theme.colors.onAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(theme.colors.accent, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
                linkRow([("Preview / PDF", { showPreview = true })])
            }
        }
    }

    private func linkRow(_ links: [(String, () -> Void)]) -> some View {
        HStack(spacing: 22) {
            ForEach(links.indices, id: \.self) { i in
                WiseLinkButton(title: links[i].0, action: links[i].1)
            }
        }
    }

    // MARK: - Helpers

    private func convert() {
        let inv = store.convertToInvoice(live)
        Haptics.success()
        message = "Converted to \(inv.number)"
        // Hop to the new invoice after a beat so the toast reads first.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            convertedDoc = inv
        }
    }

    private func buildPDF() {
        pdfURL = makeInvoicePDF(doc: live, business: store.business,
                                clientName: store.clientName(for: live),
                                clientEmail: client?.email ?? "")
    }

    private func trimNum(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", v) : String(format: "%.2f", v)
    }
}
