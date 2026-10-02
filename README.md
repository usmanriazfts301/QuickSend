# QuickSend — Native iOS App (SwiftUI)

Invoice Maker for iOS/iPadOS. SwiftUI, iOS 17+, no external dependencies.
Wise design language, Iris violet theme by default (Wise Lime / Cobalt / Ember switchable in Settings).

## Open

1. Open `QuickSend.xcodeproj` in Xcode 15+.
2. Select your Team in Signing & Capabilities (bundle id `com.quicksend.app` — change if needed).
3. Run on a simulator or device (iOS 17+).

First launch seeds demo data (3 clients, 4 items, 6 docs, 3 expenses). Reset anytime in Settings → Reset demo data.

## What's inside

| Area | Files |
|---|---|
| App entry | `QuickSend/QuickSendApp.swift` |
| Models | `QuickSend/Models.swift` |
| Data + seed + business logic | `QuickSend/Store/DataStore.swift` |
| Theming (4 themes) | `QuickSend/Theme/WiseTheme.swift` |
| Wise components | `QuickSend/Components/WiseComponents.swift` |
| Utils | `QuickSend/Utils/` — QR codes, invoice PDF (3 templates), CSV export, on-device receipt OCR (Vision), local notifications, formatters |
| Views | `QuickSend/Views/` — Docs (list/detail/editor/preview/signature/record-payment), Clients, Item catalog, Expenses (+receipt scan), Reports, Settings, Onboarding, Main tabs |

## Features

- Invoices / estimates / receipts with draft → sent → paid lifecycle + automatic overdue detection
- 1-tap estimate → invoice conversion
- Client manager with history, billed/outstanding totals
- Item catalog with autofill in the editor
- Expense tracker: receipt photo + on-device OCR total/vendor extraction, CSV export
- Online payments: per-invoice QR codes (CoreImage), deposit requests on estimates
- Read/paid/overdue notification feed + local overdue reminders
- Signature capture, photo attachments
- PDF export (3 Wise templates) + share sheet
- Revenue reports with monthly chart
- Essentials / Plus / Premium plan picker, business profile, defaults, invoice templates, 4 color themes

## Notes

- Data persists locally as JSON (`quicksend-data.json`); attachments in `quicksend-media/`.
- Read receipts are simulated in-app (a production backend would confirm real opens).
- Online payments use a `quicksend://pay` deep-link QR payload — wire to a real processor (Stripe Payment Links etc.) for production.
- No Swift toolchain was available where this was authored; first Xcode build validates compilation.
