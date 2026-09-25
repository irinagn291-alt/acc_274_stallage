import SwiftUI

/// Role: Stall. Inventory home. Journal page: hairline date rail, ink lines, remaining height for writing. Scan seats or hops.
struct OpenStallView: View {
    @Bindable var watch: CribWatch
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var searchFocused: Bool
    @State private var confirmPeel = false
    @State private var confirmRelinquish = false

    var body: some View {
        Group {
            switch watch.inventoryLoad {
            case .fault:
                CribVacancy(
                    image: "slg_EmptyHome",
                    headline: "The crib could not be read",
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
            peelTitle,
            isPresented: $confirmPeel,
            titleVisibility: .visible
        ) {
            Button(peelTitle, role: focusedHasHops ? nil : .destructive) {
                Task { await watch.peelLastHop(tagID: watch.crib.focusedTagID) }
            }
            Button("Keep", role: .cancel) {}
        } message: {
            Text(peelMessage)
        }
        .confirmationDialog(
            "Freeze this Tag?",
            isPresented: $confirmRelinquish,
            titleVisibility: .visible
        ) {
            Button("Relinquish", role: .destructive) {
                if let id = watch.crib.focusedTagID {
                    Task { await watch.relinquish(tagID: id) }
                }
            }
            Button("Keep", role: .cancel) {}
        } message: {
            Text("New hops on this Tag stop. Other scans still seat.")
        }
    }

    private var empty: some View {
        VStack(spacing: 0) {
            rail
                .padding(.horizontal, CribCraft.space(2))
                .padding(.top, CribCraft.space(1))
            CribVacancy(
                image: "slg_EmptyHome",
                headline: "Scan your first Tag",
                line: watch.openStall == nil
                    ? "Add a stall in Settings, then scan a barcode or QR."
                    : "Unknown codes sit in \(watch.openStall?.name ?? "this stall"). A known Tag from another stall hops here.",
                actionTitle: watch.canSeatTag ? "Scan" : "Open Settings",
                enabled: !watch.isCommitting,
                loading: watch.isCommitting
            ) {
                if watch.canSeatTag {
                    watch.openCapture()
                } else {
                    watch.segment = .settings
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var populated: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: CribCraft.space(1)) {
                rail
                if let fault = watch.fault {
                    CribBanner(text: fault) {
                        Task { await watch.retry() }
                    }
                } else if let notice = watch.notice {
                    CribBanner(text: notice, retryTitle: "OK") {
                        watch.notice = nil
                    }
                }
                searchBar
                chips
            }
            .padding(.horizontal, CribCraft.space(2))
            .padding(.top, CribCraft.space(1))
            writing
                .padding(.horizontal, CribCraft.space(2))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            scanDock
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .cribDismissKeyboardOnBackground()
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    searchFocused = false
                }
                .font(CribFace.font(.body))
            }
        }
    }

    private var rail: some View {
        VStack(alignment: .leading, spacing: CribCraft.space(1)) {
            HStack(alignment: .firstTextBaseline, spacing: CribCraft.space(2)) {
                Text(CribFigures.day(watch.now, calendar: watch.calendarForDisplay))
                    .font(CribFace.font(.caption))
                    .foregroundStyle(CribInk.Palette.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: CribCraft.space(1))
                hopFigure
            }
            Text(watch.jobTitle)
                .font(CribFace.font(.display))
                .foregroundStyle(CribInk.Palette.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)
            Text(watch.jobLine)
                .font(CribFace.font(.body))
                .foregroundStyle(CribInk.Palette.muted)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            CribRule()
            stallRail
        }
    }

    private var hopFigure: some View {
        Button {
            watch.openHopTrail()
        } label: {
            VStack(alignment: .trailing, spacing: 0) {
                Text(watch.hopCountLabel)
                    .font(CribFace.font(.headline))
                    .monospacedDigit()
                    .foregroundStyle(CribInk.Palette.accent)
                    .contentTransition(reduceMotion ? .identity : .numericText())
                    .lineLimit(1)
                    .layoutPriority(1)
                Text("Hops")
                    .font(CribFace.font(.micro))
                    .foregroundStyle(CribInk.Palette.muted)
                    .lineLimit(1)
                CribHopMeter(hops: watch.crib.hops.count)
                    .padding(.top, CribCraft.space(1))
            }
            .frame(minWidth: CribCraft.tap, minHeight: CribCraft.tap, alignment: .trailing)
            .contentShape(Rectangle())
        }
        .buttonStyle(CribPressStyle(enabled: true))
        .accessibilityLabel("Stall then hop, \(watch.hopCountLabel) hops")
        .accessibilityHint("Opens the hop trail")
        .animation(CribCraft.motion(reduce: reduceMotion), value: watch.crib.hops.count)
    }

    private var stallRail: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: CribCraft.space(1)) {
                ForEach(watch.crib.stalls) { stall in
                    CribChip(
                        title: stall.name,
                        selected: stall.id == watch.crib.openStallID
                    ) {
                        Task { await watch.openStall(stall.id) }
                    }
                    .accessibilityLabel("Open \(stall.name)")
                }
                Button {
                    if let stall = watch.openStall {
                        watch.openMark(.stall(stall.id))
                    }
                } label: {
                    Image(systemName: "qrcode")
                        .font(CribFace.font(.body))
                        .foregroundStyle(CribInk.Palette.ink)
                        .frame(width: CribCraft.tap, height: CribCraft.tap)
                        .background(CribInk.Palette.surface, in: CribCraft.chipShape)
                        .overlay {
                            CribCraft.chipShape.stroke(
                                CribInk.Palette.muted.opacity(0.45),
                                lineWidth: CribCraft.hairline
                            )
                        }
                        .contentShape(CribCraft.chipShape)
                }
                .buttonStyle(CribPressStyle(enabled: watch.openStall != nil))
                .disabled(watch.openStall == nil)
                .accessibilityLabel("Show stall QR")
            }
            .padding(.vertical, CribCraft.space(1))
        }
    }

    private var searchBar: some View {
        HStack(spacing: CribCraft.space(1)) {
            Image(systemName: "magnifyingglass")
                .font(CribFace.font(.body))
                .foregroundStyle(CribInk.Palette.muted)
                .accessibilityHidden(true)
            TextField("Search names and codes", text: $watch.query)
                .font(CribFace.font(.body))
                .foregroundStyle(CribInk.Palette.ink)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($searchFocused)
                .submitLabel(.search)
        }
        .padding(.horizontal, CribCraft.space(2))
        .frame(maxWidth: .infinity, minHeight: CribCraft.tap)
        .background(CribInk.Palette.surface, in: CribCraft.chipShape)
        .overlay {
            CribCraft.chipShape.stroke(CribInk.Palette.muted.opacity(0.45), lineWidth: CribCraft.hairline)
        }
        .cribLift()
        .accessibilityLabel("Search names and codes")
    }

    private var chips: some View {
        CribFlow(spacing: CribCraft.space(1)) {
            CribChip(title: "All", selected: watch.statusFilter == nil) {
                watch.statusFilter = nil
            }
            ForEach(TagStatus.allCases, id: \.self) { status in
                CribChip(
                    title: CribCopy.status(status),
                    selected: watch.statusFilter == status
                ) {
                    watch.statusFilter = status
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, CribCraft.space(1))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Tag status")
    }

    private var writing: some View {
        GeometryReader { geo in
            ScrollViewReader { proxy in
                ScrollView {
                    writingInk
                        .frame(
                            maxWidth: .infinity,
                            minHeight: geo.size.height,
                            alignment: .topLeading
                        )
                }
                .scrollDismissesKeyboard(.interactively)
                .onAppear {
                    scrollFocused(proxy)
                }
                .onChange(of: watch.crib.focusedTagID) { _, _ in
                    scrollFocused(proxy)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private var writingInk: some View {
        if watch.visibleTags.isEmpty {
            filteredEmpty
        } else {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(watch.visibleTags) { tag in
                    TagLine(
                        tag: tag,
                        stallName: watch.stallName(tag.stallID),
                        showStall: !watch.query.isEmpty || tag.stallID != watch.crib.openStallID,
                        focused: tag.id == watch.crib.focusedTagID,
                        overdueDays: overdueLabel(tag),
                        ink: tagInk(tag)
                    ) {
                        watch.focus(tag.id)
                    }
                    .id(tag.id)
                }
                hopCueInk
                trailInk
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.bottom, CribCraft.space(2))
        }
    }

    private var hopCueInk: some View {
        VStack(alignment: .leading, spacing: CribCraft.space(1)) {
            Text("Next scan")
                .font(CribFace.font(.headline))
                .foregroundStyle(CribInk.Palette.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, CribCraft.space(2))
            Text(nextScanLine)
                .font(CribFace.font(.body))
                .foregroundStyle(CribInk.Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            ForEach(hopReadyTags) { tag in
                Text(hopReadyLine(tag))
                    .font(CribFace.font(.caption))
                    .foregroundStyle(CribInk.Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, minHeight: CribCraft.tap, alignment: .leading)
                CribRule()
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var trailInk: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Trail")
                .font(CribFace.font(.headline))
                .foregroundStyle(CribInk.Palette.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, CribCraft.space(2))
                .padding(.bottom, CribCraft.space(1))
            if watch.recentHops.isEmpty, watch.crib.trailMarks.isEmpty {
                Text("No hops yet. Scan a known Tag into another stall to write the first trail.")
                    .font(CribFace.font(.caption))
                    .foregroundStyle(CribInk.Palette.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, minHeight: CribCraft.tap, alignment: .leading)
                CribRule()
            } else {
                ForEach(watch.recentHops) { hop in
                    Text(homeHopLine(hop))
                        .font(CribFace.font(.caption))
                        .foregroundStyle(CribInk.Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, minHeight: CribCraft.tap, alignment: .leading)
                    CribRule()
                }
                ForEach(watch.crib.trailMarks.reversed()) { mark in
                    Text(homeTrailLine(mark))
                        .font(CribFace.font(.caption))
                        .foregroundStyle(CribInk.Palette.muted)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, minHeight: CribCraft.tap, alignment: .leading)
                    CribRule()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var filteredEmpty: some View {
        VStack(alignment: .leading, spacing: CribCraft.space(2)) {
            Text(watch.query.isEmpty ? "Nothing in this duty." : "No Tag matches that search.")
                .font(CribFace.font(.body))
                .foregroundStyle(CribInk.Palette.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Clear the filter, or scan into this stall.")
                .font(CribFace.font(.caption))
                .foregroundStyle(CribInk.Palette.muted)
                .frame(maxWidth: .infinity, alignment: .leading)
            CribVerbButton(
                title: watch.query.isEmpty && watch.statusFilter != nil ? "Show all" : (watch.query.isEmpty ? "Scan" : "Clear search"),
                kind: .primary,
                enabled: !watch.isCommitting
            ) {
                if !watch.query.isEmpty {
                    watch.query = ""
                } else if watch.statusFilter != nil {
                    watch.statusFilter = nil
                } else if watch.canSeatTag {
                    watch.openCapture()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.top, CribCraft.space(2))
    }

    private var scanDock: some View {
        VStack(spacing: CribCraft.space(1)) {
            focusedStrip
            CribVerbButton(
                title: "Scan",
                detail: watch.canSeatTag
                    ? "Seat or hop into \(watch.openStall?.name ?? "this stall")"
                    : "Open a stall first",
                kind: .primary,
                enabled: watch.canSeatTag && !watch.isCommitting,
                loading: watch.isCommitting,
                hint: "Opens capture to seat a new Tag or hop a known one"
            ) {
                watch.openCapture()
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

    @ViewBuilder
    private var focusedStrip: some View {
        if let tag = watch.crib.focusedTag {
            VStack(alignment: .leading, spacing: CribCraft.space(1)) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(watch.tagName(tag.id))
                        .font(CribFace.font(.headline))
                        .foregroundStyle(CribInk.Palette.ink)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Text(focusDetail(tag))
                        .font(CribFace.font(.caption))
                        .foregroundStyle(CribInk.Palette.muted)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                HStack(spacing: CribCraft.space(1)) {
                    dockVerb(
                        system: "qrcode",
                        title: "QR",
                        spoken: "Show Tag QR"
                    ) {
                        watch.openMark(.tag(tag.id))
                    }
                    dockVerb(
                        system: "arrow.uturn.backward",
                        title: focusedHasHops ? "Peel" : "Remove",
                        spoken: peelTitle
                    ) {
                        confirmPeel = true
                    }
                    dockVerb(
                        system: "hand.raised",
                        title: "Relinquish",
                        spoken: "Relinquish",
                        enabled: !tag.isFrozen
                    ) {
                        confirmRelinquish = true
                    }
                }
            }
            .padding(.horizontal, CribCraft.space(2))
            .padding(.vertical, CribCraft.space(1))
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(CribInk.Palette.surface, in: CribCraft.cardShape)
            .overlay {
                CribCraft.cardShape.stroke(CribInk.Palette.muted.opacity(0.45), lineWidth: CribCraft.hairline)
            }
            .cribLift()
        }
    }

    private func dockVerb(
        system: String,
        title: String,
        spoken: String,
        enabled: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: CribCraft.space(1)) {
                Image(systemName: system)
                    .font(CribFace.font(.body))
                    .foregroundStyle(CribInk.Palette.ink)
                    .accessibilityHidden(true)
                Text(title)
                    .font(CribFace.font(.caption))
                    .foregroundStyle(CribInk.Palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, minHeight: CribCraft.tap)
            .background(CribInk.Palette.background, in: CribCraft.chipShape)
            .overlay {
                CribCraft.chipShape.stroke(
                    CribInk.Palette.muted.opacity(0.45),
                    lineWidth: CribCraft.hairline
                )
            }
            .contentShape(CribCraft.chipShape)
        }
        .buttonStyle(CribPressStyle(enabled: enabled))
        .disabled(!enabled)
        .layoutPriority(1)
        .accessibilityLabel(spoken)
    }

    private var focusedHasHops: Bool {
        guard let id = watch.crib.focusedTagID else { return false }
        return !watch.hops(for: id).isEmpty
    }

    private var peelTitle: String {
        focusedHasHops ? "Peel last hop" : "Remove Tag"
    }

    private var peelMessage: String {
        if focusedHasHops {
            return "The Tag returns to the stall it left."
        }
        return "This Tag has no hops. Removing it clears the seat."
    }

    private func focusDetail(_ tag: Tag) -> String {
        var parts = [CribCopy.status(tag.status)]
        parts.append(tag.assignedTo ?? watch.stallName(tag.stallID))
        if let code = tag.code, !code.isEmpty {
            parts.append(code)
        }
        return parts.joined(separator: ". ") + "."
    }

    private var hopReadyTags: [Tag] {
        guard let openID = watch.crib.openStallID else { return [] }
        return watch.crib.tags.filter { tag in
            tag.stallID != openID && !tag.isFrozen
        }
    }

    private var nextScanLine: String {
        let stall = watch.openStall?.name ?? "this stall"
        if let tag = watch.crib.focusedTag {
            return "\(watch.tagName(tag.id)) is focused. Scan seats a new Tag in \(stall) or hops a known Tag in."
        }
        return "Scan to seat a new Tag in \(stall), or hop a known Tag in from another stall."
    }

    private func hopReadyLine(_ tag: Tag) -> String {
        let here = watch.openStall?.name ?? "this stall"
        var line = "\(watch.tagName(tag.id)) sits in \(watch.stallName(tag.stallID)). \(CribCopy.status(tag.status))."
        if let assigned = tag.assignedTo, !assigned.isEmpty {
            line += " \(assigned)."
        }
        if let last = watch.hops(for: tag.id).last {
            line += " Last hop \(watch.stallName(last.fromStallID)) to \(watch.stallName(last.toStallID))."
        }
        line += " Scan it here to hop into \(here)."
        return line
    }

    private func homeHopLine(_ hop: Hop) -> String {
        let day = CribFigures.dayKey(hop.dayKey, calendar: watch.calendarForDisplay)
        return "\(day). \(watch.stallName(hop.fromStallID)) to \(watch.stallName(hop.toStallID)). \(hop.assignedTo) received \(watch.tagName(hop.tagID))."
    }

    private func homeTrailLine(_ mark: TrailMark) -> String {
        let day = CribFigures.dayKey(mark.dayKey, calendar: watch.calendarForDisplay)
        return "\(watch.tagName(mark.tagID)) in \(watch.stallName(mark.stallID)) on \(day)."
    }

    private func scrollFocused(_ proxy: ScrollViewProxy) {
        guard let id = watch.crib.focusedTagID else { return }
        Task { @MainActor in
            proxy.scrollTo(id, anchor: .bottom)
        }
    }

    private func overdueLabel(_ tag: Tag) -> String? {
        guard tag.isOverdue(now: watch.now, calendar: watch.calendarForDisplay), let issued = tag.issuedDayKey else {
            return nil
        }
        return CribFigures.issuedSpan(issuedDayKey: issued, now: watch.now, calendar: watch.calendarForDisplay)
    }

    private func tagInk(_ tag: Tag) -> [String] {
        var lines: [String] = []
        if let last = watch.hops(for: tag.id).last {
            lines.append(
                "Last hop \(watch.stallName(last.fromStallID)) to \(watch.stallName(last.toStallID)), \(last.assignedTo)."
            )
        } else {
            lines.append("Seated in \(watch.stallName(tag.stallID)). Scan in another stall to hop.")
        }
        if tag.id == watch.crib.focusedTagID {
            lines.append("Focused. Next Scan seats a new Tag or hops this one.")
        }
        return lines
    }
}

/// Role: Stall. Section 3.6 Inventory. Named for the live driver. Open stall, search, scan, hop.
struct InventoryView: View {
    @Bindable var watch: CribWatch

    var body: some View {
        OpenStallView(watch: watch)
    }
}
