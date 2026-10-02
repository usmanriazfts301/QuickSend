import SwiftUI

// MARK: - Signature capture: finger-drawn canvas → PNG data

struct SignatureView: View {
    @Environment(ThemeManager.self) private var theme: ThemeManager
    @Environment(\.dismiss) private var dismiss

    /// Called with the PNG bytes when the user taps Done.
    var onSave: (Data) -> Void

    @State private var paths: [Path] = []
    @State private var current = Path()

    private var isEmpty: Bool { paths.isEmpty && current.isEmpty }

    var body: some View {
        let c = theme.colors
        NavigationStack {
            VStack(spacing: 16) {
                Text("Sign inside the box")
                    .font(.subheadline)
                    .foregroundStyle(c.textSecondary)

                // Drawing canvas
                SignaturePad(paths: paths, current: current)
                    .frame(height: 240)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10)
                        .stroke(c.hair, lineWidth: 1))
                    .gesture(
                        DragGesture(minimumDistance: 1)
                            .onChanged { value in
                                if current.isEmpty {
                                    current.move(to: value.startLocation)
                                }
                                current.addLine(to: value.location)
                            }
                            .onEnded { _ in
                                if !current.isEmpty {
                                    paths.append(current)
                                    current = Path()
                                }
                            }
                    )

                HStack(spacing: 22) {
                    WiseLinkButton(title: "Clear") {
                        paths = []
                        current = Path()
                        Haptics.tap()
                    }
                    Spacer()
                    // Done is the single primary CTA here.
                    Button {
                        if let png = renderPNG() {
                            onSave(png)
                            Haptics.success()
                        }
                        dismiss()
                    } label: {
                        Text("Done").fontWeight(.semibold)
                            .foregroundStyle(c.onAccent)
                            .padding(.horizontal, 44).padding(.vertical, 13)
                            .background(isEmpty ? c.hair : c.accent, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(isEmpty)
                }
                Spacer()
            }
            .padding(20)
            .background(c.canvas)
            .navigationTitle("Signature")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    /// Renders the drawn paths to PNG via ImageRenderer (iOS 16+).
    private func renderPNG() -> Data? {
        let canvas = SignaturePad(paths: paths, current: Path())
            .frame(width: 600, height: 240)
            .background(.white)
        let renderer = ImageRenderer(content: canvas)
        renderer.scale = 2.0
        return renderer.uiImage?.pngData()
    }
}

// MARK: - The drawable pad (shared by the live view and the renderer)

private struct SignaturePad: View {
    var paths: [Path]
    var current: Path

    var body: some View {
        ZStack {
            ForEach(paths.indices, id: \.self) { i in
                paths[i].stroke(.black, lineWidth: 3)
            }
            current.stroke(.black, lineWidth: 3)
        }
    }
}
