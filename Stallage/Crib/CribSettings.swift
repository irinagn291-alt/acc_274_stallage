import SwiftUI

/// Role: Crib. Settings segment. Stall names, contact link, re-run onboarding, confirmed reset.
struct CribSettings: View {
    @Bindable var watch: CribWatch
    @State private var confirmReset = false
    @State private var showAdd = false
    @FocusState private var addFocused: Bool

    var body: some View {
        Group {
            switch watch.settingsLoad {
            case .fault:
                CribVacancy(
                    image: "slg_EmptyList",
                    headline: "Settings could not be read",
                    line: watch.fault ?? "The last copy failed. Try again.",
                    actionTitle: "Retry",
                    loading: watch.isHauling
                ) {
                    Task { await watch.retry() }
                }
            case .empty:
                empty
            case .populated:
                populated
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CribInk.Palette.background)
        .confirmationDialog(
            "Erase the crib?",
            isPresented: $confirmReset,
            titleVisibility: .visible
        ) {
            Button("Erase every stall, Tag, and hop", role: .destructive) {
                Task { await watch.resetAll() }
            }
            Button("Keep", role: .cancel) {}
        } message: {
            Text("This clears stalls, Tags, hops, and trail on this device.")
        }
        .alert("Rename stall", isPresented: renamePresented) {
            TextField("Stall name", text: $watch.renameDraft)
                .textInputAutocapitalization(.words)
            Button("Save") {
                Task { await watch.renameOpenStall() }
            }
            Button("Keep", role: .cancel) {
                watch.renameStallID = nil
            }
        }
    }

    private var empty: some View {
        VStack(spacing: CribCraft.space(2)) {
            CribVacancy(
                image: "slg_EmptyHome",
                headline: "No stalls on this device",
                line: "Add a stall, then scan a Tag into it. Contact stays here.",
                actionTitle: "Add a stall"
            ) {
                showAdd = true
            }
            contactCard
                .padding(.horizontal, CribCraft.space(2))
                .padding(.bottom, CribCraft.space(2))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showAdd) {
            addSheet
        }
    }

    private var populated: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: CribCraft.space(2)) {
                Text("Settings")
                    .font(CribFace.font(.title))
                    .foregroundStyle(CribInk.Palette.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                if let fault = watch.fault {
                    CribBanner(text: fault) {
                        Task { await watch.retry() }
                    }
                }
            }
            .padding(.horizontal, CribCraft.space(2))
            .padding(.top, CribCraft.space(1))
            .padding(.bottom, CribCraft.space(2))
            GeometryReader { geo in
                ViewThatFits(in: .vertical) {
                    settingsRoster
                        .padding(.horizontal, CribCraft.space(2))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    ScrollView {
                        settingsRoster
                            .padding(.horizontal, CribCraft.space(2))
                            .frame(
                                maxWidth: .infinity,
                                minHeight: geo.size.height,
                                alignment: .topLeading
                            )
                    }
                    .scrollDismissesKeyboard(.interactively)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            settingsDock
        }
        .cribDismissKeyboardOnBackground()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    addFocused = false
                }
                .font(CribFace.font(.body))
            }
        }
    }

    private var settingsRoster: some View {
        VStack(alignment: .leading, spacing: CribCraft.space(2)) {
            stallBlock
            if showAdd {
                addFields
            } else {
                CribVerbButton(title: "Add a stall", kind: .quiet) {
                    showAdd = true
                }
            }
            CribVerbButton(
                title: "Stall then hop",
                detail: "How a scan seats or hops",
                kind: .quiet
            ) {
                watch.openHopTrail()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var stallBlock: some View {
        CribSurface(padded: false, fills: true) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Stalls")
                    .font(CribFace.font(.headline))
                    .foregroundStyle(CribInk.Palette.ink)
                    .padding(.horizontal, CribCraft.space(2))
                    .padding(.top, CribCraft.space(2))
                    .padding(.bottom, CribCraft.space(1))
                ForEach(watch.crib.stalls) { stall in
                    stallRow(stall)
                }
                hopExplain
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private func stallRow(_ stall: Stall) -> some View {
        let tags = watch.crib.tags(in: stall.id)
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: CribCraft.space(1)) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(stall.name)
                        .font(CribFace.font(.body))
                        .foregroundStyle(CribInk.Palette.ink)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Text(CribCopy.duty(stall.duty))
                        .font(CribFace.font(.caption))
                        .foregroundStyle(CribInk.Palette.muted)
                        .lineLimit(1)
                    Text(stallInk(stall))
                        .font(CribFace.font(.caption))
                        .foregroundStyle(CribInk.Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Button {
                    watch.renameStallID = stall.id
                    watch.renameDraft = stall.name
                } label: {
                    Image(systemName: "pencil")
                        .font(CribFace.font(.body))
                        .foregroundStyle(CribInk.Palette.ink)
                        .frame(width: CribCraft.tap, height: CribCraft.tap)
                        .contentShape(Rectangle())
                }
                .buttonStyle(CribPressStyle(enabled: true))
                .accessibilityLabel("Rename \(stall.name)")
                Button {
                    watch.openMark(.stall(stall.id))
                } label: {
                    Image(systemName: "qrcode")
                        .font(CribFace.font(.body))
                        .foregroundStyle(CribInk.Palette.ink)
                        .frame(width: CribCraft.tap, height: CribCraft.tap)
                        .contentShape(Rectangle())
                }
                .buttonStyle(CribPressStyle(enabled: true))
                .accessibilityLabel("Show QR for \(stall.name)")
            }
            .padding(.horizontal, CribCraft.space(2))
            .padding(.vertical, CribCraft.space(1))
            .frame(maxWidth: .infinity, minHeight: CribCraft.tap, alignment: .leading)
            CribRule()
            ForEach(tags) { tag in
                Text(settingsTagLine(tag))
                    .font(CribFace.font(.caption))
                    .foregroundStyle(CribInk.Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, minHeight: CribCraft.tap, alignment: .leading)
                    .padding(.horizontal, CribCraft.space(2))
                CribRule()
            }
        }
    }

    private var hopExplain: some View {
        VStack(alignment: .leading, spacing: CribCraft.space(1)) {
            Text("Scan seats or hops")
                .font(CribFace.font(.headline))
                .foregroundStyle(CribInk.Palette.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("An unknown code seats a Tag in the open stall. A known Tag scanned into another stall writes a hop and a trail. Relinquished freezes hops on that Tag.")
                .font(CribFace.font(.body))
                .foregroundStyle(CribInk.Palette.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("\(watch.hopCountLabel) hops in this crib. Overdue issued: \(watch.overdueCountLabel).")
                .font(CribFace.font(.caption))
                .foregroundStyle(CribInk.Palette.muted)
                .frame(maxWidth: .infinity, alignment: .leading)
            ForEach(watch.crib.stalls) { stall in
                Text(settingsHopLine(stall))
                    .font(CribFace.font(.caption))
                    .foregroundStyle(CribInk.Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, minHeight: CribCraft.tap, alignment: .leading)
                CribRule()
            }
        }
        .padding(.horizontal, CribCraft.space(2))
        .padding(.vertical, CribCraft.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func stallInk(_ stall: Stall) -> String {
        let names = watch.crib.tags(in: stall.id).map { watch.tagName($0.id) }
        if names.isEmpty {
            return "No Tags yet. Scan to seat the first."
        }
        return "\(names.joined(separator: ", ")). Scan to seat or hop."
    }

    private func settingsTagLine(_ tag: Tag) -> String {
        "\(watch.tagName(tag.id)). \(CribCopy.status(tag.status)). Scan to hop."
    }

    private func settingsHopLine(_ stall: Stall) -> String {
        let names = watch.crib.tags(in: stall.id).map { watch.tagName($0.id) }
        if names.isEmpty {
            return "\(stall.name) is empty. Scan an unknown code there to seat the first Tag."
        }
        return "\(stall.name) holds \(names.joined(separator: ", ")). Scan one in another stall to hop it."
    }

    private var settingsDock: some View {
        VStack(alignment: .leading, spacing: CribCraft.space(1)) {
            contactCard
            CribVerbButton(
                title: "Re-run onboarding",
                kind: .quiet,
                enabled: !watch.isCommitting
            ) {
                Task { await watch.reopenOnboarding() }
            }
            CribVerbButton(
                title: "Reset all data",
                detail: "Erase stalls and Tags on this device",
                kind: .destroy,
                enabled: !watch.isCommitting,
                loading: watch.isCommitting
            ) {
                confirmReset = true
            }
        }
        .padding(.horizontal, CribCraft.space(2))
        .padding(.top, CribCraft.space(1))
        .padding(.bottom, CribCraft.space(2))
        .frame(maxWidth: .infinity)
        .background(CribInk.Palette.background.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) {
            CribRule()
        }
    }

    private var addFields: some View {
        VStack(alignment: .leading, spacing: CribCraft.space(1)) {
            TextField("Stall name", text: $watch.stallDraft)
                .font(CribFace.font(.body))
                .foregroundStyle(CribInk.Palette.ink)
                .textInputAutocapitalization(.words)
                .focused($addFocused)
                .padding(.horizontal, CribCraft.space(2))
                .frame(maxWidth: .infinity, minHeight: CribCraft.tap)
                .background(CribInk.Palette.surface, in: CribCraft.chipShape)
                .overlay {
                    CribCraft.chipShape.stroke(CribInk.Palette.muted.opacity(0.45), lineWidth: CribCraft.hairline)
                }
                .cribLift()
            Picker("Duty", selection: $watch.stallDuty) {
                ForEach(StallDuty.allCases, id: \.self) { duty in
                    Text(CribCopy.duty(duty)).tag(duty)
                }
            }
            .pickerStyle(.segmented)
            .frame(minHeight: CribCraft.tap)
            .accessibilityLabel("Duty")
            CribVerbButton(
                title: "Save stall",
                kind: .primary,
                enabled: !watch.stallDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !watch.isCommitting,
                loading: watch.isCommitting
            ) {
                Task {
                    await watch.addStall()
                    showAdd = false
                }
            }
        }
    }

    private var addSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: CribCraft.space(2)) {
                CribSheetBar(title: "Add a stall") {
                    showAdd = false
                }
                addFields
                Text("Duty copies onto a new Tag when you scan it into this stall.")
                    .font(CribFace.font(.caption))
                    .foregroundStyle(CribInk.Palette.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(CribCraft.space(2))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(CribInk.Palette.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        addFocused = false
                    }
                    .font(CribFace.font(.body))
                }
            }
        }
    }

    private var contactCard: some View {
        Link(destination: CribClient.contactURL) {
            VStack(alignment: .leading, spacing: CribCraft.space(1)) {
                Text("Contact")
                    .font(CribFace.font(.body))
                    .foregroundStyle(CribInk.Palette.ink)
                    Text(CribClient.contactURL.absoluteString)
                    .font(CribFace.font(.caption))
                    .foregroundStyle(CribInk.Palette.accent)
                    .underline()
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(CribCraft.space(2))
            .frame(maxWidth: .infinity, minHeight: CribCraft.tap, alignment: .leading)
            .background(CribInk.Palette.surface, in: CribCraft.cardShape)
            .overlay {
                CribCraft.cardShape.stroke(CribInk.Palette.muted.opacity(0.45), lineWidth: CribCraft.hairline)
            }
            .cribLift()
            .contentShape(CribCraft.cardShape)
        }
        .accessibilityLabel("Contact")
        .accessibilityValue(CribClient.contactURL.absoluteString)
    }

    private var renamePresented: Binding<Bool> {
        Binding(
            get: { watch.renameStallID != nil },
            set: { presented in
                if !presented {
                    watch.renameStallID = nil
                }
            }
        )
    }
}
