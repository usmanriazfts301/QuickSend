import Foundation

// MARK: - Expense CSV export

func makeExpensesCSV(_ expenses: [Expense]) -> URL? {
    var rows = ["Date,Vendor,Category,Amount,Notes"]
    let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
    func esc(_ s: String) -> String {
        let q = s.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(q)\""
    }
    for e in expenses {
        rows.append([f.string(from: e.date), esc(e.vendor), esc(e.category),
                     String(format: "%.2f", e.amount), esc(e.notes)].joined(separator: ","))
    }
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("quicksend-expenses.csv")
    do {
        try rows.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
        return url
    } catch { return nil }
}
