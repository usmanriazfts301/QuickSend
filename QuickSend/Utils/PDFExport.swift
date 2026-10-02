import UIKit

// MARK: - Invoice PDF export (UIGraphicsPDFRenderer, 3 Wise templates)

/// Renders a print-ready invoice/estimate/receipt PDF and returns its file URL.
func makeInvoicePDF(doc: InvoiceDocument, business: BusinessProfile,
                    clientName: String, clientEmail: String) -> URL? {
    let t = docTotals(of: doc)
    let page = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter
    let rendererFormat = UIGraphicsPDFRendererFormat()
    let renderer = UIGraphicsPDFRenderer(bounds: page, format: rendererFormat)

    let template = business.template
    // Template palette (flat Wise colors)
    let (headBG, headFG, accent): (UIColor, UIColor, UIColor) = switch template {
    case .classic: (UIColor(white: 0.97, alpha: 1), UIColor(hex: 0x1F1A44), UIColor(hex: 0x8B7CFF))
    case .forest: (UIColor(hex: 0x163300), .white, UIColor(hex: 0x9FE870))
    case .bold: (UIColor(hex: 0x1F1A44), .white, UIColor(hex: 0x8B7CFF))
    }

    let data = renderer.pdfData { ctx in
        ctx.beginPage()
        let c = ctx.cgContext
        var y: CGFloat = 0

        // Header band
        c.setFillColor(headBG.cgColor)
        c.fill(CGRect(x: 0, y: 0, width: 612, height: 150))
        y = 44
        drawText(business.name.isEmpty ? "QuickSend" : business.name, at: CGPoint(x: 48, y: y),
                 size: 26, weight: .black, color: headFG); y += 34
        drawText([business.email, business.phone].filter { !$0.isEmpty }.joined(separator: " · "),
                 at: CGPoint(x: 48, y: y), size: 10, color: headFG.withAlphaComponent(0.7)); y += 16
        if !business.address.isEmpty {
            drawText(business.address, at: CGPoint(x: 48, y: y), size: 10, color: headFG.withAlphaComponent(0.7))
        }
        // Doc label top-right
        drawText(doc.type.label.uppercased(), at: CGPoint(x: 564, y: 40), size: 13, weight: .bold,
                 color: headFG.withAlphaComponent(0.7), align: .right)
        drawText(doc.number, at: CGPoint(x: 564, y: 60), size: 24, weight: .black, color: headFG, align: .right)

        // Bill-to + meta
        y = 190
        drawText("BILL TO", at: CGPoint(x: 48, y: y), size: 10, weight: .bold,
                 color: UIColor(hex: 0x4E476E)); y += 18
        drawText(clientName, at: CGPoint(x: 48, y: y), size: 15, weight: .bold, color: .black); y += 20
        if !clientEmail.isEmpty {
            drawText(clientEmail, at: CGPoint(x: 48, y: y), size: 11, color: .darkGray); y += 18
        }
        let meta: [(String, String)] = [
            ("Issue date", shortDate(doc.issueDate)),
            (doc.type == .estimate ? "Valid until" : "Due date", shortDate(doc.dueDate)),
            ("Status", doc.status.rawValue.capitalized),
        ]
        var my = 190.0
        for (k, v) in meta {
            drawText(k.uppercased(), at: CGPoint(x: 420, y: my), size: 9, weight: .bold,
                     color: UIColor(hex: 0x4E476E), align: .left)
            drawText(v, at: CGPoint(x: 564, y: my), size: 11, weight: .semibold, color: .black, align: .right)
            my += 20
        }

        // Items table
        y = 300
        c.setStrokeColor(UIColor(hex: 0x1F1A44, alpha: 0.15).cgColor); c.setLineWidth(1)
        c.move(to: CGPoint(x: 48, y: y)); c.addLine(to: CGPoint(x: 564, y: y)); c.strokePath()
        y += 12
        drawText("DESCRIPTION", at: CGPoint(x: 48, y: y), size: 9, weight: .bold, color: UIColor(hex: 0x4E476E))
        drawText("QTY", at: CGPoint(x: 380, y: y), size: 9, weight: .bold, color: UIColor(hex: 0x4E476E), align: .right)
        drawText("RATE", at: CGPoint(x: 470, y: y), size: 9, weight: .bold, color: UIColor(hex: 0x4E476E), align: .right)
        drawText("AMOUNT", at: CGPoint(x: 564, y: y), size: 9, weight: .bold, color: UIColor(hex: 0x4E476E), align: .right)
        y += 20
        for it in doc.items {
            drawText(it.desc, at: CGPoint(x: 48, y: y), size: 12, color: .black)
            drawText(trimNum(it.qty), at: CGPoint(x: 380, y: y), size: 12, color: .darkGray, align: .right)
            drawText(fmt(it.rate), at: CGPoint(x: 470, y: y), size: 12, color: .darkGray, align: .right)
            drawText(fmt(it.lineTotal), at: CGPoint(x: 564, y: y), size: 12, weight: .semibold, color: .black, align: .right)
            y += 24
        }
        c.move(to: CGPoint(x: 48, y: y + 4)); c.addLine(to: CGPoint(x: 564, y: y + 4)); c.strokePath()
        y += 22

        // Totals (right aligned)
        func totalRow(_ k: String, _ v: Double) {
            drawText(k, at: CGPoint(x: 400, y: y), size: 12, color: .darkGray, align: .right)
            drawText(fmt(v), at: CGPoint(x: 564, y: y), size: 12, weight: .semibold, color: .black, align: .right)
            y += 22
        }
        totalRow("Subtotal", t.subtotal)
        if t.discount > 0 { totalRow("Discount", -t.discount) }
        totalRow("Tax (\(trimNum(doc.taxRate))%)", t.tax)
        // Grand total band
        c.setFillColor(accent.cgColor)
        let band = CGRect(x: 360, y: y - 4, width: 204, height: 34)
        c.addPath(UIBezierPath(roundedRect: band, cornerRadius: 8).cgPath)
        c.fillPath()
        drawText("TOTAL  " + fmt(t.total), at: CGPoint(x: 552, y: y + 3), size: 14, weight: .black,
                 color: template == .classic ? .white : headFG, align: .right)
        y += 52

        // Deposit (estimates)
        if doc.type == .estimate && doc.depositValue > 0 {
            let dep = doc.depositType == "pct" ? t.total * doc.depositValue / 100 : min(doc.depositValue, t.total)
            drawText("Deposit requested (\(trimNum(doc.depositValue))\(doc.depositType == "pct" ? "%" : "")): \(fmt(dep))",
                     at: CGPoint(x: 48, y: y), size: 12, weight: .bold, color: UIColor(hex: 0x15803D))
            y += 24
        }

        // Notes / terms
        if !doc.notes.isEmpty {
            drawText("NOTES", at: CGPoint(x: 48, y: y), size: 9, weight: .bold, color: UIColor(hex: 0x4E476E)); y += 16
            y = drawWrapped(doc.notes, at: CGPoint(x: 48, y: y), width: 516, size: 11, color: .darkGray) + 14
        }
        if !doc.terms.isEmpty {
            drawText("TERMS", at: CGPoint(x: 48, y: y), size: 9, weight: .bold, color: UIColor(hex: 0x4E476E)); y += 16
            y = drawWrapped(doc.terms, at: CGPoint(x: 48, y: y), width: 516, size: 11, color: .darkGray) + 14
        }

        // QR code
        if let qr = qrImage(from: paymentLink(for: doc, business: business), size: 110) {
            qr.draw(in: CGRect(x: 48, y: y, width: 110, height: 110))
            drawText("Scan to pay", at: CGPoint(x: 170, y: y + 44), size: 11, weight: .semibold, color: .darkGray)
        }

        // Signature
        if let sig = doc.signaturePNG, let img = UIImage(data: sig) {
            let sy = y + 130
            drawText("SIGNED", at: CGPoint(x: 420, y: sy), size: 9, weight: .bold, color: UIColor(hex: 0x4E476E))
            img.draw(in: CGRect(x: 420, y: sy + 14, width: 144, height: 60))
        }

        // Footer
        drawText("Made with QuickSend", at: CGPoint(x: 306, y: 762), size: 9, color: UIColor(white: 0.6, alpha: 1), align: .center)
    }

    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("\(doc.number).pdf")
    do { try data.write(to: url); return url } catch { return nil }
}

// MARK: - PDF drawing helpers

private func drawText(_ s: String, at p: CGPoint, size: CGFloat,
                      weight: UIFont.Weight = .regular, color: UIColor,
                      align: NSTextAlignment = .left) {
    let a = NSAttributedString(string: s, attributes: [
        .font: UIFont.systemFont(ofSize: size, weight: weight),
        .foregroundColor: color,
    ])
    let w: CGFloat = align == .left ? 600 : 600
    let r = CGRect(x: align == .left ? p.x : (align == .right ? p.x - w : p.x - w / 2),
                   y: p.y, width: w, height: size + 10)
    a.draw(in: r)
}

private func drawWrapped(_ s: String, at p: CGPoint, width: CGFloat, size: CGFloat, color: UIColor) -> CGFloat {
    let style = NSMutableParagraphStyle(); style.lineBreakMode = .byWordWrapping
    let a = NSAttributedString(string: s, attributes: [
        .font: UIFont.systemFont(ofSize: size), .foregroundColor: color, .paragraphStyle: style,
    ])
    let r = a.boundingRect(with: CGSize(width: width, height: 1000),
                           options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
    a.draw(in: CGRect(x: p.x, y: p.y, width: width, height: ceil(r.height)))
    return p.y + ceil(r.height)
}

private func fmt(_ v: Double) -> String {
    String(format: "$%.2f", v)
}
private func trimNum(_ v: Double) -> String {
    v.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", v) : String(format: "%.2f", v)
}

private extension UIColor {
    convenience init(hex: UInt, alpha: CGFloat = 1) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
    }
}
