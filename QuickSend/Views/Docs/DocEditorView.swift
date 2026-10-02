import SwiftUI
import PhotosUI

// MARK: - Document editor: new or existing invoice / estimate / receipt

struct DocEditorView: View {
    @Environment(DataStore.self) private var store: DataStore
    @Environment(ThemeManager.self) private var theme: ThemeManager
    @Environment(\.dismiss) private var dismiss

    @State private var draft: InvoiceDocument
    @State private var isNew: Bool
    @State private var configured = false

    @State private var message: String? = nil
    @State private var showClientPicker = false
    @State private var showItemPicker = false
    @State private var showSignature = false
    @State private var showPreview = false
    @State private var showPhotoPicker = false
    @State private var photoItems: [PhotosPickerItem] = []

    init(doc: InvoiceDocument? = nil) {
        _draft = State(initialValue: doc ?? InvoiceDocument())
        _isNew = State(initialValue: doc == nil)
    }

    private var totals: DocTotals { store.docTotals(draft) }
    private var selectedClient: Client? {
        store.clients.first(where: { $0.id == draft.clientId })
    }

    var body: some View {
        let c = theme.colors
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    typeCard
                    numberClientCard
                    datesCard
                    itemsCard
                    totalsCard
                    discountTaxCard
                    if draft.type == .estimate { depositCard }
                    notesCard
                    optionsCard
                    photosCard
                    signatureCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(c.canvas)
            .navigationTitle(isNew ? "New \(draft.type.label)" : draft.number)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 18) {
                    WiseLinkButton(title: "Save draft") { save(preview: false) }
                    WisePrimaryButton(title: "Preview", icon: "eye") { save(preview: true) }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(c.card)
                .overlay(alignment: .top) {
                    Rectangle().frame(height: 1).foregroundStyle(c.hair)
                }
            }
            .navigationDestination(isPresented: $showPreview) {
                DocPreviewView(doc: draft)
            }
            .sheet(isPresented: $showClientPicker) { clientPickerSheet }
            .sheet(isPresented: $showItemPicker) { itemPickerSheet }
            .sheet(isPresented: $showSignature) {
                SignatureView { data in draft.signaturePNG = data }
            }
            .photosPicker(isPresented: $showPhotoPicker, selection: $photoItems,
                          maxSelectionCount: 5, matching: .images)
            .onChange(of: photoItems) { _, items in importPhotos(items) }
            .onChange(of: draft.type) { _, t in
                if isNew { draft.number = store.nextNumber(for: t) }
            }
            .onAppear(perform: configureNew)
            .toast($message)
        }
    }

    // MARK: - New-doc defaults

    private func configureNew() {
        guard isNew, !configured else { return }
        configured = true
        draft.number = store.nextNumber(for: draft.type)
        draft.notes = store.business.defaultNotes
        draft.terms = store.business.defaultTerms
        draft.taxRate = store.business.defaultTaxRate
        draft.onlinePayments = true
        let cal = Calendar.current
        draft.dueDate = cal.date(byAdding: .day, value: 14, to: draft.issueDate) ?? draft.issueDate
    }

    // MARK: - Sections

    private var typeCard: some View {
        WiseCard {
            VStack(alignment: .leading, spacing: 10) {
                sectionLabel("Document type")
                Picker("Type", selection: $draft.type) {
                    ForEach(DocType.allCases) { t in Text(t.label).tag(t) }
                }
                .pickerStyle(.segmented)
                .disabled(!isNew)
            }
        }
    }

    private var numberClientCard: some View {
        WiseCard {
            VStack(spacing: 14) {
                WiseField(label: "Number", text: $draft.number, placeholder: "INV-1001")
                VStack(alignment: .leading, spacing: 7) {
                    sectionLabel("Client")
                    Button { showClientPicker = true } label: {
                        HStack {
                            if let cl = selectedClient {
                                AvatarView(name: cl.name, size: 34)
                                Text(cl.name).fontWeight(.semibold)
                                    .foregroundStyle(theme.colors.ink)
                            } else {
                                IconTile(icon: "person.badge.plus", size: 34)
                                Text("Select client")
                                    .foregroundStyle(theme.colors.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(theme.colors.textSecondary)
                        }
                        .padding(10)
                        .background(theme.colors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10)
                            .stroke(theme.colors.hair, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var datesCard: some View {
        WiseCard {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 7) {
                    sectionLabel("Issue date")
                    DatePicker("", selection: $draft.issueDate, displayedComponents: .date)
                        .labelsHidden()
                }
                Spacer()
                VStack(alignment: .leading, spacing: 7) {
                    sectionLabel(draft.type == .estimate ? "Valid until" : "Due date")
                    DatePicker("", selection: $draft.dueDate, displayedComponents: .date)
                        .labelsHidden()
                }
            }
        }
    }

    private var itemsCard: some View {
        WiseCard {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    sectionLabel("Line items")
                    Spacer()
                    Button { showItemPicker = true } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                            Text("Add item").fontWeight(.semibold)
                        }
                        .font(.subheadline)
                        .foregroundStyle(theme.colors.deep)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 6)
                if draft.items.isEmpty {
                    Text("No items yet — add your first line item.")
                        .font(.subheadline)
                        .foregroundStyle(theme.colors.textSecondary)
                        .padding(.vertical, 10)
                }
                ForEach($draft.items) { $item in
                    VStack(spacing: 8) {
                        HStack {
                            TextField("Description", text: $item.desc)
                                .fontWeight(.medium)
                            Spacer()
                            Button {
                                draft.items.removeAll { $0.id == item.id }
                                Haptics.tap()
                            } label: {
                                Image(systemName: "trash")
                                    .font(.subheadline)
                                    .foregroundStyle(theme.colors.danger)
                            }
                            .buttonStyle(.plain)
                        }
                        HStack(spacing: 10) {
                            TextField("Qty", value: $item.qty, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.center)
                                .padding(8)
                                .background(theme.colors.secondaryBg, in: RoundedRectangle(cornerRadius: 8))
                                .frame(width: 76)
                            Text("×").foregroundStyle(theme.colors.textSecondary)
                            TextField("Rate", value: $item.rate, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.center)
                                .padding(8)
                                .background(theme.colors.secondaryBg, in: RoundedRectangle(cornerRadius: 8))
                                .frame(width: 110)
                            Spacer()
                            Text(store.formatMoney(item.lineTotal))
                                .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                    }
                    .padding(.vertical, 8)
                    Divider().background(theme.colors.hair)
                }
            }
        }
    }

    private var totalsCard: some View {
        WiseCard {
            VStack(spacing: 4) {
                totalsRow("Subtotal", totals.subtotal)
                if totals.discount > 0 { totalsRow("Discount", -totals.discount) }
                totalsRow("Tax (\(trimNum(draft.taxRate))%)", totals.tax)
                HStack {
                    Text("Total").font(.wiseDisplay(18))
                    Spacer()
                    Text(store.formatMoney(totals.total)).font(.wiseDisplay(20))
                }
                .padding(.top, 6)
            }
        }
    }

    private func totalsRow(_ label: String, _ value: Double) -> some View {
        HStack {
            Text(label).foregroundStyle(theme.colors.textSecondary)
            Spacer()
            Text(store.formatMoney(value))
        }
        .font(.subheadline)
    }

    private var discountTaxCard: some View {
        WiseCard {
            VStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    sectionLabel("Discount")
                    HStack(spacing: 12) {
                        Picker("", selection: $draft.discountType) {
                            Text("%").tag("pct")
                            Text("Fixed").tag("fixed")
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 150)
                        TextField("0", value: $draft.discountValue, format: .number)
                            .keyboardType(.decimalPad)
                            .padding(12)
                            .background(theme.colors.card)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10)
                                .stroke(theme.colors.hair, lineWidth: 1))
                    }
                }
                VStack(alignment: .leading, spacing: 8) {
                    sectionLabel("Tax rate %")
                    TextField("0", value: $draft.taxRate, format: .number)
                        .keyboardType(.decimalPad)
                        .padding(12)
                        .background(theme.colors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10)
                            .stroke(theme.colors.hair, lineWidth: 1))
                }
            }
        }
    }

    private var depositCard: some View {
        WiseCard {
            VStack(alignment: .leading, spacing: 8) {
                sectionLabel("Deposit requested")
                HStack(spacing: 12) {
                    Picker("", selection: $draft.depositType) {
                        Text("%").tag("pct")
                        Text("Fixed").tag("fixed")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 150)
                    TextField("0", value: $draft.depositValue, format: .number)
                        .keyboardType(.decimalPad)
                        .padding(12)
                        .background(theme.colors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10)
                            .stroke(theme.colors.hair, lineWidth: 1))
                }
                if draft.depositValue > 0 {
                    Text("Client will be asked for \(store.formatMoney(store.depositAmount(draft))) upfront.")
                        .font(.subheadline)
                        .foregroundStyle(theme.colors.success)
                }
            }
        }
    }

    private var notesCard: some View {
        WiseCard {
            VStack(spacing: 14) {
                WiseField(label: "Notes", text: $draft.notes, placeholder: "Thanks for your business!")
                WiseField(label: "Terms", text: $draft.terms, placeholder: "Payment due within 14 days.")
            }
        }
    }

    private var optionsCard: some View {
        WiseCard {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Online payments").fontWeight(.semibold)
                    Text("Cards, ACH, PayPal, Venmo + QR code")
                        .font(.subheadline)
                        .foregroundStyle(theme.colors.textSecondary)
                }
                Spacer()
                Toggle("", isOn: $draft.onlinePayments)
                    .labelsHidden()
                    .tint(theme.colors.deep)
            }
        }
    }

    private var photosCard: some View {
        WiseCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    sectionLabel("Photo attachments")
                    Spacer()
                    Button { showPhotoPicker = true } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "photo.badge.plus")
                            Text("Add").fontWeight(.semibold)
                        }
                        .font(.subheadline)
                        .foregroundStyle(theme.colors.deep)
                    }
                    .buttonStyle(.plain)
                }
                if draft.photoNames.isEmpty {
                    Text("Attach job photos as proof of work.")
                        .font(.subheadline)
                        .foregroundStyle(theme.colors.textSecondary)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(draft.photoNames, id: \.self) { name in
                                ZStack(alignment: .topTrailing) {
                                    if let ui = UIImage(contentsOfFile: store.fileURL(for: name).path) {
                                        Image(uiImage: ui)
                                            .resizable().scaledToFill()
                                            .frame(width: 88, height: 88)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                    Button {
                                        store.deleteMedia(named: name)
                                        draft.photoNames.removeAll { $0 == name }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.white, theme.colors.danger)
                                            .font(.title3)
                                    }
                                    .buttonStyle(.plain)
                                    .padding(4)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var signatureCard: some View {
        WiseCard {
            VStack(alignment: .leading, spacing: 10) {
                sectionLabel("Signature")
                if let data = draft.signaturePNG, let ui = UIImage(data: data) {
                    HStack {
                        Image(uiImage: ui)
                            .resizable().scaledToFit()
                            .frame(height: 70)
                        Spacer()
                        VStack(spacing: 10) {
                            WiseLinkButton(title: "Replace") { showSignature = true }
                            WiseLinkButton(title: "Remove") { draft.signaturePNG = nil }
                        }
                    }
                } else {
                    Button { showSignature = true } label: {
                        HStack {
                            Image(systemName: "pencil.and.scribble")
                            Text("Add signature").fontWeight(.semibold)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(theme.colors.textSecondary)
                        }
                        .foregroundStyle(theme.colors.deep)
                        .padding(12)
                        .background(theme.colors.secondaryBg, in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Client picker sheet

    private var clientPickerSheet: some View {
        NavigationStack {
            List {
                Section("Quick add") {
                    TextField("Name", text: $newClientName)
                    TextField("Email", text: $newClientEmail)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    Button("Add & select") {
                        let c = Client(name: newClientName.trimmingCharacters(in: .whitespaces),
                                       email: newClientEmail.trimmingCharacters(in: .whitespaces))
                        guard !c.name.isEmpty else { return }
                        store.addClient(c)
                        if let saved = store.clients.first(where: { $0.name == c.name && $0.email == c.email }) {
                            draft.clientId = saved.id
                        }
                        newClientName = ""; newClientEmail = ""
                        Haptics.success()
                        showClientPicker = false
                    }
                    .disabled(newClientName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                Section("Clients") {
                    ForEach(store.clients) { c in
                        Button {
                            draft.clientId = c.id
                            Haptics.tap()
                            showClientPicker = false
                        } label: {
                            HStack {
                                AvatarView(name: c.name, size: 38)
                                VStack(alignment: .leading) {
                                    Text(c.name).foregroundStyle(theme.colors.ink)
                                    if !c.email.isEmpty {
                                        Text(c.email).font(.caption)
                                            .foregroundStyle(theme.colors.textSecondary)
                                    }
                                }
                                Spacer()
                                if draft.clientId == c.id {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(theme.colors.deep)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select client")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { showClientPicker = false }
                }
            }
        }
    }

    // MARK: - Item picker sheet (catalog + custom)

    @State private var customDesc = ""
    @State private var customQty = "1"
    @State private var customRate = ""

    private var itemPickerSheet: some View {
        NavigationStack {
            List {
                Section("From catalog") {
                    ForEach(store.items) { item in
                        Button {
                            draft.items.append(LineItem(desc: item.name, qty: 1, rate: item.rate))
                            Haptics.tap()
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(item.name).foregroundStyle(theme.colors.ink)
                                    if !item.desc.isEmpty {
                                        Text(item.desc).font(.caption)
                                            .foregroundStyle(theme.colors.textSecondary)
                                    }
                                }
                                Spacer()
                                Text(store.formatMoney(item.rate))
                                    .foregroundStyle(theme.colors.textSecondary)
                            }
                        }
                    }
                }
                Section("Custom item") {
                    TextField("Description", text: $customDesc)
                    HStack {
                        TextField("Qty", text: $customQty).keyboardType(.decimalPad)
                        TextField("Rate", text: $customRate).keyboardType(.decimalPad)
                    }
                    Button("Add item") {
                        let qty = Double(customQty) ?? 1
                        let rate = Double(customRate) ?? 0
                        guard !customDesc.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        draft.items.append(LineItem(desc: customDesc, qty: qty, rate: rate))
                        customDesc = ""; customQty = "1"; customRate = ""
                        Haptics.tap()
                    }
                    .disabled(customDesc.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .navigationTitle("Add item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { showItemPicker = false }
                }
            }
        }
    }

    // MARK: - Photos

    private func importPhotos(_ items: [PhotosPickerItem]) {
        for item in items {
            Task {
                guard let data = try? await item.loadTransferable(type: Data.self) else { continue }
                await MainActor.run {
                    if let name = store.saveImageData(data) {
                        draft.photoNames.append(name)
                    }
                }
            }
        }
        photoItems = []
    }

    // MARK: - Save

    private func save(preview: Bool) {
        // Keep only real line items.
        draft.items.removeAll { $0.desc.trimmingCharacters(in: .whitespaces).isEmpty && $0.lineTotal == 0 }
        guard draft.clientId != nil else { message = "Select a client first"; return }
        guard !draft.items.isEmpty else { message = "Add at least one line item"; return }
        if isNew { store.addDoc(draft) } else { store.updateDoc(draft) }
        Haptics.success()
        if preview {
            showPreview = true
        } else {
            message = "Draft saved"
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { dismiss() }
        }
    }

    // MARK: - Small helpers

    private func sectionLabel(_ s: String) -> some View {
        Text(s.uppercased())
            .font(.caption).fontWeight(.bold)
            .foregroundStyle(theme.colors.textSecondary)
    }

    private func trimNum(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", v) : String(format: "%.2f", v)
    }
}
