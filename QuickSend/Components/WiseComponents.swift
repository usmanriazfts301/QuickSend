import SwiftUI

// MARK: - Wise design components (flat, pill CTAs, 10px cards, hairlines)

/// Primary filled pill CTA — the ONE accent element per section.
struct WisePrimaryButton: View {
    @Environment(ThemeManager.self) private var theme
    let title: String
    var icon: String? = nil
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon { Image(systemName: icon) }
                Text(title).fontWeight(.semibold)
            }
            .font(.body)
            .foregroundStyle(theme.colors.onAccent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(theme.colors.accent, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// Underlined text link — the Wise secondary action. Never two filled buttons side by side.
struct WiseLinkButton: View {
    @Environment(ThemeManager.self) private var theme
    let title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body).fontWeight(.semibold)
                .foregroundStyle(theme.colors.deep)
                .underline()
        }
        .buttonStyle(.plain)
    }
}

/// Flat white card: 10px radius, hairline border, NO shadow.
struct WiseCard<Content: View>: View {
    @Environment(ThemeManager.self) private var theme
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        content
            .padding(18)
            .background(theme.colors.card)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10)
                .stroke(theme.colors.hair, lineWidth: 1))
    }
}

/// Status pill (uppercase micro-label).
struct StatusPill: View {
    @Environment(ThemeManager.self) private var theme
    let status: DisplayStatus

    var body: some View {
        let c = theme.colors
        let (fg, bg): (Color, Color) = switch status {
        case .paid: (c.success, c.success.opacity(0.14))
        case .sent: (Color(hex: 0x0B6D99), Color(hex: 0x0B6D99).opacity(0.14))
        case .overdue: (c.danger, c.danger.opacity(0.12))
        case .draft: (c.textSecondary, c.textSecondary.opacity(0.12))
        }
        Text(status.label.uppercased())
            .font(.caption2).fontWeight(.bold)
            .foregroundStyle(fg)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(bg, in: Capsule())
    }
}

/// Labeled text field — 10px, hairline, forest focus.
struct WiseField: View {
    @Environment(ThemeManager.self) private var theme
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var keyboard: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label.uppercased())
                .font(.caption).fontWeight(.bold)
                .foregroundStyle(theme.colors.textSecondary)
            TextField(placeholder, text: $text)
                .keyboardType(keyboard)
                .padding(13)
                .background(theme.colors.card)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .stroke(theme.colors.hair, lineWidth: 1))
        }
    }
}

/// Tinted pill chip (filters).
struct WiseChip: View {
    @Environment(ThemeManager.self) private var theme
    let title: String
    let isOn: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline).fontWeight(.semibold)
                .foregroundStyle(isOn ? .white : theme.colors.ink)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(isOn ? theme.colors.ink : theme.colors.secondaryBg, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// Avatar circle with initial.
struct AvatarView: View {
    @Environment(ThemeManager.self) private var theme
    let name: String
    var size: CGFloat = 46

    var body: some View {
        Text(String(name.first ?? "?").uppercased())
            .font(.wiseDisplay(size * 0.38))
            .foregroundStyle(theme.colors.deep)
            .frame(width: size, height: size)
            .background(theme.colors.accent.opacity(0.25), in: Circle())
    }
}

/// Empty state.
struct EmptyState: View {
    @Environment(ThemeManager.self) private var theme
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    init(icon: String, title: String, body: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.message = body
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 34))
                .foregroundStyle(theme.colors.deep)
                .frame(width: 72, height: 72)
                .background(theme.colors.canvas, in: RoundedRectangle(cornerRadius: 10))
            Text(title).font(.title3).fontWeight(.bold)
            Text(message).font(.subheadline)
                .foregroundStyle(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                WisePrimaryButton(title: actionTitle, action: action)
                    .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}

/// Small icon tile (10px, tinted).
struct IconTile: View {
    @Environment(ThemeManager.self) private var theme
    let icon: String
    var size: CGFloat = 46
    var tinted: Bool = true

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(theme.colors.deep)
            .frame(width: size, height: size)
            .background((tinted ? theme.colors.secondaryBg : theme.colors.card), in: RoundedRectangle(cornerRadius: 10))
            .overlay(tinted ? nil : RoundedRectangle(cornerRadius: 10).stroke(theme.colors.hair, lineWidth: 1))
    }
}

/// Toast banner modifier.
struct ToastModifier: ViewModifier {
    @Binding var message: String?
    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            if let message {
                Text(message)
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20).padding(.vertical, 13)
                    .background(Color(hex: 0x1F1A44), in: Capsule())
                    .padding(.bottom, 90)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35), value: message)
    }
}

extension View {
    func toast(_ message: Binding<String?>) -> some View {
        modifier(ToastModifier(message: message))
    }
}
