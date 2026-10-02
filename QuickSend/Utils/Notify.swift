import UserNotifications
import UIKit

// MARK: - Local notifications (overdue reminders, payment alerts)

enum Notify {
    static func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    static func pushLocal(title: String, body: String) {
        let c = UNMutableNotificationContent()
        c.title = title; c.body = body; c.sound = .default
        let req = UNNotificationRequest(identifier: UUID().uuidString, content: c,
                                        trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false))
        UNUserNotificationCenter.current().add(req)
    }

    /// Schedules a morning reminder for each overdue invoice (one per doc, idempotent by identifier).
    static func scheduleOverdueReminders(for docs: [InvoiceDocument], totals: (InvoiceDocument) -> DocTotals) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: docs.map { "overdue-\($0.id)" })
        let startOfToday = Calendar.current.startOfDay(for: Date())
        for d in docs where d.type == .invoice && d.status == .sent && d.dueDate < startOfToday {
            let t = totals(d)
            guard t.balance > 0 else { continue }
            let c = UNMutableNotificationContent()
            c.title = "Invoice overdue"
            c.body = "\(d.number) is overdue — \(String(format: "$%.2f", t.balance)) outstanding."
            c.sound = .default
            var dc = DateComponents(); dc.hour = 9
            let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
            center.add(UNNotificationRequest(identifier: "overdue-\(d.id)", content: c, trigger: trigger))
        }
    }
}

// MARK: - Haptics

enum Haptics {
    static func tap() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
}
