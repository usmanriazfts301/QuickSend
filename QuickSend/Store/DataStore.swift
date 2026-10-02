import Foundation
import SwiftUI
import Observation

/// Central data store: JSON persistence, seed demo data, and all business logic.
@Observable
final class DataStore {
    var docs: [InvoiceDocument] = []
    var clients: [Client] = []
    var items: [CatalogItem] = []
    var expenses: [Expense] = []
    var notifications: [AppNotification] = []
    var business: BusinessProfile = BusinessProfile()
    var isOnboarded: Bool = false

    private let fileName = "quicksend-data.json"
    private let mediaDir = "quicksend-media"

    // MARK: - Init / persistence

    init() { load() }

    private var dataURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }
    private var mediaURL: URL {
        let u = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(mediaDir)
        try? FileManager.default.createDirectory(at: u, withIntermediateDirectories: true)
        return u
    }

    func fileURL(for name: String) -> URL { mediaURL.appendingPathComponent(name) }

    private struct Snapshot: Codable {
        var docs: [InvoiceDocument]; var clients: [Client]; var items: [CatalogItem]
        var expenses: [Expense]; var notifications: [AppNotification]
        var business: BusinessProfile; var isOnboarded: Bool
    }

    func save() {
        let snap = Snapshot(docs: docs, clients: clients, items: items,
                            expenses: expenses, notifications: notifications,
                            business: business, isOnboarded: isOnboarded)
        do {
            let data = try JSONEncoder().encode(snap)
            try data.write(to: dataURL, options: .atomic)
        } catch { print("QuickSend save failed:", error) }
    }

    func load() {
        do {
            let data = try Data(contentsOf: dataURL)
            let snap = try JSONDecoder().decode(Snapshot.self, from: data)
            docs = snap.docs; clients = snap.clients; items = snap.items
            expenses = snap.expenses; notifications = snap.notifications
            business = snap.business; isOnboarded = snap.isOnboarded
        } catch {
            seed(); save()
        }
    }

    func resetDemo() {
        try? FileManager.default.removeItem(at: dataURL)
        seed(); isOnboarded = true; save()
    }

    // MARK: - Seed demo data (mirrors the web prototype)

    private func seed() {
        let t = Date()
        func days(_ n: Int) -> Date { Calendar.current.date(byAdding: .day, value: n, to: t)! }
        let c1 = Client(name: "Sarah Mitchell", email: "sarah@studio.com", phone: "+1 415 555 0132", address: "418 Market St, San Francisco, CA")
        let c2 = Client(name: "Brightline Co", email: "ops@brightline.co", phone: "+1 212 555 0177", address: "77 Greene St, New York, NY")
        let c3 = Client(name: "Daniel Kim", email: "dan@danielkim.design", phone: "+49 170 555 0142", address: "Torstr. 101, Berlin")
        clients = [c1, c2, c3]
        items = [
            CatalogItem(name: "Brand identity design", desc: "Logo + visual system", rate: 900, taxRate: 8.8),
            CatalogItem(name: "Design revisions", desc: "Per revision round", rate: 60, taxRate: 8.8),
            CatalogItem(name: "Landing page build", desc: "Design + Webflow", rate: 2400, taxRate: 8.8),
            CatalogItem(name: "Monthly retainer", desc: "20h design support", rate: 1800, taxRate: 8.8),
        ]
        func li(_ d: String, _ q: Double, _ r: Double) -> LineItem { LineItem(desc: d, qty: q, rate: r) }
        docs = [
            InvoiceDocument(type: .invoice, number: "INV-1042", clientId: c1.id,
                            issueDate: days(-6), dueDate: days(8),
                            items: [li("Brand identity design", 1, 900), li("Revisions × 4", 4, 60)],
                            taxRate: 8.8, notes: "Thanks for your business!", terms: "Payment due within 14 days.",
                            status: .sent, onlinePayments: true, sentDate: days(-6), openedDate: days(-5)),
            InvoiceDocument(type: .invoice, number: "INV-1041", clientId: c2.id,
                            issueDate: days(-20), dueDate: days(-6),
                            items: [li("Landing page build", 1, 2400)],
                            taxRate: 8.8, status: .sent, sentDate: days(-20)),
            InvoiceDocument(type: .invoice, number: "INV-1040", clientId: c3.id,
                            issueDate: days(-40), dueDate: days(-26),
                            items: [li("Logo package", 1, 2100), li("Brand guidelines", 1, 350)],
                            taxRate: 10, status: .paid, paidTotal: 2695,
                            payments: [DocPayment(date: days(-27), amount: 2695, method: "Card")],
                            sentDate: days(-40), openedDate: days(-39)),
            InvoiceDocument(type: .estimate, number: "EST-2015", clientId: c1.id,
                            issueDate: days(-2), dueDate: days(28),
                            items: [li("Website redesign", 1, 3200)],
                            taxRate: 8.8, status: .sent, depositType: "pct", depositValue: 30,
                            sentDate: days(-2), openedDate: days(-2)),
            InvoiceDocument(type: .estimate, number: "EST-2014", clientId: c2.id,
                            issueDate: days(-9), dueDate: days(21),
                            items: [li("Monthly retainer", 1, 1800)],
                            taxRate: 8.8, status: .draft),
            InvoiceDocument(type: .receipt, number: "REC-3001", clientId: c3.id,
                            issueDate: days(-27), dueDate: days(-27),
                            items: [li("Print collateral", 2, 320)],
                            discountType: "fixed", discountValue: 40, taxRate: 10,
                            status: .paid, paidTotal: 660,
                            payments: [DocPayment(date: days(-27), amount: 660, method: "Venmo")]),
        ]
        expenses = [
            Expense(vendor: "Apple Store", category: "Equipment", amount: 129, date: days(-12), notes: "Magic Keyboard"),
            Expense(vendor: "Figma", category: "Software", amount: 15, date: days(-4), notes: "Monthly seat"),
            Expense(vendor: "Uber", category: "Travel", amount: 34.5, date: days(-1), notes: "Client site visit"),
        ]
        notifications = [
            AppNotification(date: days(-5), kind: "opened", title: "Read receipt",
                            body: "Sarah Mitchell opened INV-1042", docId: docs[0].id, read: true),
            AppNotification(date: days(-6), kind: "overdue", title: "Overdue",
                            body: "INV-1041 is now overdue", docId: docs[1].id, read: false),
        ]
        business = BusinessProfile(name: "Usman Studio", email: "hello@usmanstudio.com",
                                    currency: "USD", defaultTaxRate: 8.8, template: .classic, plan: "Essentials")
        isOnboarded = false
    }

    // MARK: - Math

    func docTotals(_ d: InvoiceDocument) -> DocTotals {
        let sub = d.items.reduce(0) { $0 + $1.lineTotal }
        let disc: Double = d.discountType == "pct" ? sub * d.discountValue / 100 : min(d.discountValue, sub)
        let taxable = max(0, sub - disc)
        let tax = taxable * d.taxRate / 100
        let total = taxable + tax
        let paid = d.paidTotal
        return DocTotals(subtotal: sub, discount: disc, tax: tax, total: total,
                         paid: paid, balance: max(0, total - paid))
    }

    func displayStatus(_ d: InvoiceDocument) -> DisplayStatus {
        if d.type == .receipt || d.status == .paid { return .paid }
        if d.status == .draft { return .draft }
        if d.dueDate < Calendar.current.startOfDay(for: Date()) { return .overdue }
        return .sent
    }

    func depositAmount(_ d: InvoiceDocument) -> Double {
        let total = docTotals(d).total
        return d.depositType == "pct" ? total * d.depositValue / 100 : min(d.depositValue, total)
    }

    // MARK: - Documents

    func addDoc(_ d: InvoiceDocument) { docs.insert(d, at: 0); save() }
    func updateDoc(_ d: InvoiceDocument) {
        if let i = docs.firstIndex(where: { $0.id == d.id }) { docs[i] = d; save() }
    }
    func deleteDoc(_ d: InvoiceDocument) { docs.removeAll { $0.id == d.id }; save() }

    func nextNumber(for type: DocType) -> String {
        let prefix: String
        switch type {
        case .invoice: prefix = business.invoicePrefix
        case .estimate: prefix = business.estimatePrefix
        case .receipt: prefix = business.receiptPrefix
        }
        let nums = docs.filter { $0.type == type }.compactMap {
            Int($0.number.replacingOccurrences(of: prefix, with: ""))
        }
        return "\(prefix)\((nums.max() ?? 1000) + 1)"
    }

    /// One-tap estimate → invoice conversion.
    @discardableResult
    func convertToInvoice(_ doc: InvoiceDocument) -> InvoiceDocument {
        var inv = doc
        inv.id = UUID()
        inv.type = .invoice
        inv.number = nextNumber(for: .invoice)
        inv.status = .draft
        inv.depositType = "pct"; inv.depositValue = 0
        inv.sentDate = nil; inv.openedDate = nil
        inv.createdAt = Date()
        docs.insert(inv, at: 0); save()
        pushNotification(kind: "info", title: "Converted",
                         body: "\(doc.number) became \(inv.number)", docId: inv.id)
        return inv
    }

    func markSent(_ doc: InvoiceDocument) {
        var d = doc; d.status = .sent; d.sentDate = Date()
        updateDoc(d)
        // Simulated read receipt (a real backend would confirm actual opens)
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
            guard let self, var cur = self.docs.first(where: { $0.id == doc.id }),
                  cur.openedDate == nil, cur.status == .sent else { return }
            cur.openedDate = Date(); self.updateDoc(cur)
            self.pushNotification(kind: "opened", title: "Read receipt",
                                  body: "\(self.clientName(for: cur)) opened \(cur.number)", docId: cur.id)
        }
    }

    func recordPayment(doc: InvoiceDocument, amount: Double, method: String, date: Date = Date()) {
        var d = doc
        d.payments.append(DocPayment(date: date, amount: amount, method: method))
        d.paidTotal += amount
        if docTotals(d).balance < 0.01 { d.status = .paid }
        updateDoc(d)
        pushNotification(kind: "paid", title: "Payment received",
                         body: "\(formatMoney(amount)) · \(method) · \(d.number)", docId: d.id)
    }

    // MARK: - Clients / items / expenses

    func clientName(for d: InvoiceDocument) -> String {
        clients.first(where: { $0.id == d.clientId })?.name ?? "—"
    }
    func addClient(_ c: Client) { clients.append(c); save() }
    func updateClient(_ c: Client) {
        if let i = clients.firstIndex(where: { $0.id == c.id }) { clients[i] = c; save() }
    }
    func deleteClient(_ c: Client) { clients.removeAll { $0.id == c.id }; save() }
    func clientDocs(_ c: Client) -> [InvoiceDocument] {
        docs.filter { $0.clientId == c.id }.sorted { $0.issueDate > $1.issueDate }
    }
    func clientTotals(_ c: Client) -> (billed: Double, outstanding: Double) {
        let ds = clientDocs(c)
        let billed = ds.reduce(0) { $0 + docTotals($1).total }
        let outstanding = ds.reduce(0) { $0 + (displayStatus($1) == .paid ? 0 : docTotals($1).balance) }
        return (billed, outstanding)
    }

    func addItem(_ i: CatalogItem) { items.append(i); save() }
    func updateItem(_ i: CatalogItem) {
        if let x = items.firstIndex(where: { $0.id == i.id }) { items[x] = i; save() }
    }
    func deleteItem(_ i: CatalogItem) { items.removeAll { $0.id == i.id }; save() }

    func addExpense(_ e: Expense) { expenses.insert(e, at: 0); save() }
    func updateExpense(_ e: Expense) {
        if let i = expenses.firstIndex(where: { $0.id == e.id }) { expenses[i] = e; save() }
    }
    func deleteExpense(_ e: Expense) {
        if let r = e.receiptName { try? FileManager.default.removeItem(at: fileURL(for: r)) }
        expenses.removeAll { $0.id == e.id }; save()
    }

    // MARK: - Notifications

    func pushNotification(kind: String, title: String, body: String, docId: UUID? = nil) {
        notifications.insert(AppNotification(kind: kind, title: title, body: body, docId: docId), at: 0)
        if notifications.count > 100 { notifications = Array(notifications.prefix(100)) }
        save()
    }
    var unreadCount: Int { notifications.filter { !$0.read }.count }
    func markAllNotificationsRead() {
        notifications = notifications.map { var n = $0; n.read = true; return n }
        save()
    }

    // MARK: - Reports

    func revenueStats() -> (collected: Double, outstanding: Double, overdue: Double, monthly: [(String, Double)]) {
        var collected = 0.0, outstanding = 0.0, overdue = 0.0
        var byMonth: [String: Double] = [:]
        let fmt = DateFormatter(); fmt.dateFormat = "MMM"
        for d in docs where d.type == .invoice {
            let t = docTotals(d)
            collected += t.paid
            let st = displayStatus(d)
            if st == .overdue { overdue += t.balance } else if st != .paid { outstanding += t.balance }
            for p in d.payments {
                let k = fmt.string(from: p.date)
                byMonth[k, default: 0] += p.amount
            }
        }
        let order = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
        let monthly = order.compactMap { m -> (String, Double)? in
            guard let v = byMonth[m] else { return nil }; return (m, v)
        }
        return (collected, outstanding, overdue, monthly)
    }

    // MARK: - Media

    @discardableResult
    func saveImageData(_ data: Data, ext: String = "jpg") -> String? {
        let name = "\(UUID().uuidString).\(ext)"
        do { try data.write(to: fileURL(for: name)); return name } catch { return nil }
    }
    func deleteMedia(named name: String) {
        try? FileManager.default.removeItem(at: fileURL(for: name))
    }

    // MARK: - Formatting helper (currency-aware)

    func formatMoney(_ v: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency; f.currencyCode = business.currency
        f.maximumFractionDigits = 2
        return f.string(from: NSNumber(value: v)) ?? "\(v)"
    }
}
