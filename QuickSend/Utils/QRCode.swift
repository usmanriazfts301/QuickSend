import UIKit
import CoreImage.CIFilterBuiltins

/// Real QR codes via CoreImage — every invoice gets its own payment QR.
func qrImage(from string: String, size: CGFloat = 300) -> UIImage? {
    let ctx = CIContext()
    var filter = CIFilter.qrCodeGenerator()
    filter.message = Data(string.utf8)
    filter.correctionLevel = "M"
    guard let out = filter.outputImage else { return nil }
    let scale = size / out.extent.width
    let scaled = out.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
    guard let cg = ctx.createCGImage(scaled, from: scaled.extent) else { return nil }
    return UIImage(cgImage: cg)
}

func paymentLink(for doc: InvoiceDocument, business: BusinessProfile) -> String {
    // Deep-link style payment URL embedded in the QR (handled by the merchant backend in production).
    "quicksend://pay/\(doc.number)?amount=\(String(format: "%.2f", docTotals(of: doc).total))&to=\(business.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
}

/// Standalone totals helper for contexts without a store.
func docTotals(of doc: InvoiceDocument) -> DocTotals {
    let sub = doc.items.reduce(0) { $0 + $1.lineTotal }
    let disc: Double = doc.discountType == "pct" ? sub * doc.discountValue / 100 : min(doc.discountValue, sub)
    let taxable = max(0, sub - disc)
    let tax = taxable * doc.taxRate / 100
    let total = taxable + tax
    return DocTotals(subtotal: sub, discount: disc, tax: tax, total: total,
                     paid: doc.paidTotal, balance: max(0, total - doc.paidTotal))
}
