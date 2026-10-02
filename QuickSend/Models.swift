import Foundation

// MARK: - Document types

enum DocType: String, Codable, CaseIterable, Identifiable {
    case invoice, estimate, receipt
    var id: String { rawValue }
    var label: String {
        switch self {
        case .invoice: return "Invoice"
        case .estimate: return "Estimate"
        case .receipt: return "Receipt"
        }
    }
    var plural: String { label + "s" }
}

enum DocStatus: String, Codable {
    case draft, sent, paid
}

/// Display status — includes computed overdue.
enum DisplayStatus: String {
    case draft, sent, paid, overdue
    var label: String {
        switch self {
        case .draft: return "Draft"
        case .sent: return "Sent"
        case .paid: return "Paid"
        case .overdue: return "Overdue"
        }
    }
}

// MARK: - Line items & payments

struct LineItem: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var desc: String
    var qty: Double
    var rate: Double
    var lineTotal: Double { qty * rate }
}

struct DocPayment: Codable, Identifiable {
    var id: UUID = UUID()
    var date: Date
    var amount: Double
    var method: String
}

// MARK: - Invoice document (invoice / estimate / receipt)

struct InvoiceDocument: Codable, Identifiable {
    var id: UUID = UUID()
    var type: DocType
    var number: String
    var clientId: UUID?
    var issueDate: Date = Date()
    var dueDate: Date = Date()
    var items: [LineItem] = []
    var discountType: String = "pct"      // "pct" | "fixed"
    var discountValue: Double = 0
    var taxRate: Double = 0               // percent
    var notes: String = ""
    var terms: String = ""
    var status: DocStatus = .draft
    var paidTotal: Double = 0
    var payments: [DocPayment] = []
    var signaturePNG: Data? = nil
    var photoNames: [String] = []
    var depositType: String = "pct"        // estimate deposits
    var depositValue: Double = 0
    var onlinePayments: Bool = true
    var sentDate: Date? = nil
    var openedDate: Date? = nil           // simulated read receipt
    var createdAt: Date = Date()
}

struct DocTotals {
    var subtotal: Double = 0
    var discount: Double = 0
    var tax: Double = 0
    var total: Double = 0
    var paid: Double = 0
    var balance: Double = 0
}

// MARK: - Client

struct Client: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var email: String = ""
    var phone: String = ""
    var address: String = ""
    var notes: String = ""
    var createdAt: Date = Date()
}

// MARK: - Catalog item

struct CatalogItem: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var desc: String = ""
    var rate: Double = 0
    var taxRate: Double = 0
}

// MARK: - Expense

struct Expense: Codable, Identifiable {
    var id: UUID = UUID()
    var vendor: String
    var category: String = "General"
    var amount: Double = 0
    var date: Date = Date()
    var notes: String = ""
    var receiptName: String? = nil        // image file in media dir
}

// MARK: - Business profile & settings

enum InvoiceTemplate: String, Codable, CaseIterable, Identifiable {
    case classic, forest, bold
    var id: String { rawValue }
    var label: String {
        switch self {
        case .classic: return "Classic"
        case .forest: return "Forest"
        case .bold: return "Bold"
        }
    }
}

struct BusinessProfile: Codable {
    var name: String = ""
    var email: String = ""
    var phone: String = ""
    var address: String = ""
    var website: String = ""
    var currency: String = "USD"
    var defaultTaxRate: Double = 0
    var invoicePrefix: String = "INV-"
    var estimatePrefix: String = "EST-"
    var receiptPrefix: String = "REC-"
    var defaultTerms: String = "Payment due within 14 days."
    var defaultNotes: String = "Thanks for your business!"
    var template: InvoiceTemplate = .classic
    var plan: String = "Essentials"
}

// MARK: - Notifications (in-app feed)

struct AppNotification: Codable, Identifiable {
    var id: UUID = UUID()
    var date: Date = Date()
    var kind: String            // "opened" | "paid" | "overdue" | "info"
    var title: String
    var body: String
    var docId: UUID? = nil
    var read: Bool = false
}
