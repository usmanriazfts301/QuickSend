import UIKit
import Vision

// MARK: - Receipt OCR (on-device Vision text recognition)

/// Runs on-device text recognition on a receipt photo and extracts the most
/// likely total: the largest currency-like amount found on the receipt.
func recognizeReceiptTotal(_ image: UIImage, completion: @escaping (Double?) -> Void) {
    guard let cg = image.cgImage else { completion(nil); return }
    let req = VNRecognizeTextRequest { req, _ in
        let strings = (req.results as? [VNRecognizedTextObservation])?
            .compactMap { $0.topCandidates(1).first?.string } ?? []
        completion(extractTotal(from: strings))
    }
    req.recognitionLevel = .accurate
    req.usesLanguageCorrection = false
    DispatchQueue.global(qos: .userInitiated).async {
        try? VNImageRequestHandler(cgImage: cg, options: [:]).perform([req])
    }
}

private func extractTotal(from lines: [String]) -> Double? {
    // Currency-ish amounts: $1,234.56 / 1234.56 / USD 45.00
    let pattern = #"\$?\s?(\d{1,3}(?:,\d{3})*\.\d{2})"#
    let rx = try? NSRegularExpression(pattern: pattern)
    var best: Double?
    // Prefer lines mentioning total/balance/due/amount
    let prioritized = lines.sorted {
        let a = $0.lowercased(), b = $1.lowercased()
        let ka = a.contains("total") || a.contains("balance") || a.contains("due") || a.contains("amount")
        let kb = b.contains("total") || b.contains("balance") || b.contains("due") || b.contains("amount")
        return ka && !kb
    }
    for line in prioritized {
        let ns = line as NSString
        for m in rx?.matches(in: line, range: NSRange(location: 0, length: ns.length)) ?? [] {
            let raw = ns.substring(with: m.range(at: 1)).replacingOccurrences(of: ",", with: "")
            if let v = Double(raw), v > 0 { best = max(best ?? 0, v) }
        }
        if best != nil && prioritized.firstIndex(of: line) ?? 99 < 4 { break }
    }
    return best
}

/// Vendor guess: longest alpha line near the top of the receipt.
func recognizeVendor(_ image: UIImage, completion: @escaping (String?) -> Void) {
    guard let cg = image.cgImage else { completion(nil); return }
    let req = VNRecognizeTextRequest { req, _ in
        let strings = (req.results as? [VNRecognizedTextObservation])?
            .compactMap { $0.topCandidates(1).first?.string } ?? []
        let vendor = strings.prefix(6).first {
            $0.rangeOfCharacter(from: .letters) != nil && $0.count > 3 && $0.count < 40
        }
        completion(vendor)
    }
    req.recognitionLevel = .fast
    DispatchQueue.global(qos: .userInitiated).async {
        try? VNImageRequestHandler(cgImage: cg, options: [:]).perform([req])
    }
}
