import Foundation

// MARK: - Dates

func shortDate(_ d: Date) -> String {
    let f = DateFormatter()
    f.dateStyle = .medium; f.timeStyle = .none
    return f.string(from: d)
}

func relativeDay(_ d: Date) -> String {
    let cal = Calendar.current
    if cal.isDateInToday(d) { return "Today" }
    if cal.isDateInYesterday(d) { return "Yesterday" }
    if cal.isDateInTomorrow(d) { return "Tomorrow" }
    let days = cal.dateComponents([.day], from: cal.startOfDay(for: Date()), to: cal.startOfDay(for: d)).day ?? 0
    if days < 0 { return "\(-days)d overdue" }
    return "in \(days)d"
}

func monthKey(_ d: Date) -> String {
    let f = DateFormatter(); f.dateFormat = "yyyy-MM"
    return f.string(from: d)
}
