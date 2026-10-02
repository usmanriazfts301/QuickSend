import SwiftUI

// MARK: - Invoice preview: SwiftUI replica of the PDF (template-aware) + share

struct DocPreviewView: View {
    @Environment(DataStore.self) private var store: DataStore
    @Environment(ThemeManager.self) private var theme: ThemeManager

    let doc: InvoiceDocument

    @State private var pdfURL: URL? = nil

    private var totals: DocTotals { store.docTotals(doc) }
    private var client: Client? { store.clients.first(where: { $0.id == doc.clientId }) }

    /// Header band per template (mirrors the PDF palettes).
    private var bandBG: Color {
        switch store.business.template {
        case .classic: return Color(white: 0.96)
        case .forest: return Color(hex: 0x163300)
        case .bold: return Color(hex: 0x1F1A44)
        }
    }
    private var bandFG: Color {
        switch store.business.template {
        case .classic: return theme.colors.ink
        case .forest, .bold: return .white
        }
    }

    var body: some View {
        let c = theme.colors
        let b = store.business
        ScrollView {
            VStack(spacing: 0) {
                // Header band
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(b.name.isEmpty ? "QuickSend" : b.name)
                                .font(.wiseDisplay(26))
                            if !b.email.isEmpty || !b.phone.isEmpty {
                                Text([b.email, b.phone].filter { !$0.isEmpty }.joined(separator: " · "))
                                    .font(.caption)
                                    .opacity(0.75)
                            }
                            if !b.address.isEmpty {
                                Text(b.address).font(.caption).opacity(0.75)
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(doc.type.label.uppercased())
                                .font(.caption).fontWeight(.bold).opacity(0.7)
                            Text(doc.number).font(.wiseDisplay(22))
                        }
                    }
                }
                .foregroundStyle(bandFG)
                .padding(20)
                .background(bandBG)

                // Body
                VStack(alignment: .leading, spacing: 18) {
                    // Bill-to + meta
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            microLabel("Bill to")
                            Text(store.clientName(for: doc)).fontWeight(.bold)
                            if let email = client?.email, !email.isEmpty {
                                Text(email).font(.subheadline).foregroundStyle(c.textSecondary)
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 6) {
                            metaRow("Issue date", shortDate(doc.issueDate))
                            metaRow(doc.type == .estimate ? "Valid until" : "Due date", shortDate(doc.dueDate))
                            metaRow("Status", store.displayStatus(doc).label)
                        }
                    }

                    // Items table
                    VStack(spacing: 0) {
                        HStack {
                            Text("DESCRIPTION").frame(maxWidth: .infinity, alignment: .leading)
                            Text("QTY").frame(width: 44, alignment: .trailing)
                            Text("AMOUNT").frame(width: 90, alignment: .trailing)
                        }
                        .font(.caption).fontWeight(.bold)
                        .foregroundStyle(c.textSecondary)
                        .padding(.bottom, 8)
                        ForEach(doc.items) { item in
                            HStack(alignment: .top) {
                                Text(item.desc).frame(maxWidth: .infinity, alignment: .leading)
                                Text(trimNum(item.qty)).frame(width: 44, alignment: .trailing)
                                    .foregroundStyle(c.textSecondary)
                                Text(store.formatMoney(item.lineTotal))
                                    .frame(width: 90, alignment: .trailing)
                                    .fontWeight(.semibold)
                            }
                            .font(.subheadline)
                            .padding(.vertical, 7)
                            Divider().background(c.hair)
                        }
                    }

                    // Totals
                    VStack(spacing: 5) {
                        totalRow("Subtotal", totals.subtotal)
                        if totals.discount > 0 { totalRow("Discount", -totals.discount) }
                        totalRow("Tax (\(trimNum(doc.taxRate))%)", totals.tax)
                        HStack {
                            Text("TOTAL").font(.wiseDisplay(18))
                            Spacer()
                            Text(store.formatMoney(totals.total)).font(.wiseDisplay(20))
                        }
                        .padding(.top, 4)
                        if totals.paid > 0 {
                            totalRow("Paid", totals.paid)
                            HStack {
                                Text("Balance due").fontWeight(.bold)
                                Spacer()
                                Text(store.formatMoney(totals.balance)).fontWeight(.bold)
                            }
                            .font(.subheadline)
                        }
                    }

                    // Deposit (estimates)
                    if doc.type == .estimate && doc.depositValue > 0 {
                        Text("Deposit requested: \(store.formatMoney(store.depositAmount(doc)))")
                            .font(.subheadline).fontWeight(.bold)
                            .foregroundStyle(c.success)
                    }

                    // Notes / terms
                    if !doc.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            microLabel("Notes")
                            Text(doc.notes).font(.subheadline).foregroundStyle(c.textSecondary)
                        }
                    }
                    if !doc.terms.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            microLabel("Terms")
                            Text(doc.terms).font(.subheadline).foregroundStyle(c.textSecondary)
                        }
                    }

                    // QR
                    if doc.onlinePayments {
                        HStack(spacing: 14) {
                            if let ui = qrImage(from: paymentLink(for: doc, business: b)) {
                                Image(uiImage: ui)
                                    .interpolation(.none)
                                    .resizable()
                                    .frame(width: 96, height: 96)
                            }
                            Text("Scan to pay")
                                .font(.subheadline).fontWeight(.semibold)
                                .foregroundStyle(c.textSecondary)
                        }
                    }

                    // Signature
                    if let data = doc.signaturePNG, let ui = UIImage(data: data) {
                        VStack(alignment: .leading, spacing: 4) {
                            microLabel("Signed")
                            Image(uiImage: ui)
                                .resizable().scaledToFit()
                                .frame(maxHeight: 70)
                        }
                    }
                }
                .padding(20)
            }
            .background(c.card)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(c.hair, lineWidth: 1))
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(c.canvas)
        .navigationTitle("Preview")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            if let pdfURL {
                ShareLink(item: pdfURL) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share PDF").fontWeight(.semibold)
                    }
                    .font(.body)
                    .foregroundStyle(c.onAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(c.accent, in: Capsule())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(c.card)
                .overlay(alignment: .top) {
                    Rectangle().frame(height: 1).foregroundStyle(c.hair)
                }
            }
        }
        .onAppear { buildPDF() }
    }

    // MARK: - Helpers

    private func microLabel(_ s: String) -> some View {
        Text(s.uppercased())
            .font(.caption).fontWeight(.bold)
            .foregroundStyle(theme.colors.textSecondary)
    }

    private func metaRow(_ k: String, _ v: String) -> some View {
        VStack(alignment: .trailing, spacing: 1) {
            Text(k.uppercased()).font(.caption2).foregroundStyle(theme.colors.textSecondary)
            Text(v).font(.subheadline).fontWeight(.semibold)
        }
    }

    private func totalRow(_ label: String, _ value: Double) -> some View {
        HStack {
            Text(label).foregroundStyle(theme.colors.textSecondary)
            Spacer()
            Text(store.formatMoney(value)).fontWeight(.semibold)
        }
        .font(.subheadline)
    }

    private func buildPDF() {
        pdfURL = makeInvoicePDF(doc: doc, business: store.business,
                                clientName: store.clientName(for: doc),
                                clientEmail: client?.email ?? "")
    }

    private func trimNum(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", v) : String(format: "%.2f", v)
    }
}
