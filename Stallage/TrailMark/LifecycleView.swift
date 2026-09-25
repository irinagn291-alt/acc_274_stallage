import SwiftUI

/// Role: TrailMark. Lifecycle segment. Hero hop count, then journal ink for overdue, hops, trail, and the next hop.
struct LifecycleView: View {
    @Bindable var watch: CribWatch
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pickedOverdueID: UUID?

    var body: some View {
        Group {
            switch watch.lifecycleLoad {
            case .fault:
                CribVacancy(
                    image: "slg_EmptyList",
                    headline: "Lifecycle could not be read",
                    line: watch.fault ?? "The last copy failed. Try again.",
                    actionTitle: "Retry",
                    loading: watch.isHauling
                ) {
                    Task { await watch.retry() }
                }
            case .empty:
                CribVacancy(
                    image: "slg_EmptyList",
                    headline: "No hops yet",
                    line: "Hop a Tag into another stall to write a trail. Issued longer than 30 days will rank here.",
                    actionTitle: "Open Inventory"
                ) {
                    watch.jumpInventory()
                }
            case .populated:
                populated
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CribInk.Palette.background)
    }

    private var populated: some View {
        VStack(alignment: .leading, spacing: CribCraft.space(2)) {
            header
            if let fault = watch.fault {
                CribBanner(text: fault) {
                    Task { await watch.retry() }
                }
            }
            GeometryReader { geo in
                ScrollView {
                    VStack(alignment: .leading, spacing: CribCraft.space(3)) {
                        if !watch.overdueTags.isEmpty {
                            overdueBlock
                        }
                        if !watch.recentHops.isEmpty {
                            hopBlock
                        }
                        if !watch.crib.trailMarks.isEmpty {
                            trailBlock
                        }
                        nextHopInk
                        seatedNow
                    }
                    .frame(maxWidth: .infinity, minHeight: geo.size.height, alignment: .topLeading)
                    .padding(.bottom, CribCraft.space(3))
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(.horizontal, CribCraft.space(2))
        .padding(.top, CribCraft.space(1))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: CribCraft.space(1)) {
            Text("Lifecycle")
                .font(CribFace.font(.title))
                .foregroundStyle(CribInk.Palette.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .accessibilityAddTraits(.isHeader)
            HStack(alignment: .firstTextBaseline, spacing: CribCraft.space(2)) {
                Text(watch.hopCountLabel)
                    .font(CribFace.font(.display))
                    .monospacedDigit()
                    .foregroundStyle(CribInk.Palette.accent)
                    .contentTransition(reduceMotion ? .identity : .numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .layoutPriority(1)
                    .accessibilityLabel("Hops \(watch.hopCountLabel)")
                Text("hops in this crib. Overdue issued: \(watch.overdueCountLabel).")
                    .font(CribFace.font(.body))
                    .foregroundStyle(CribInk.Palette.muted)
                    .lineLimit(3)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .animation(CribCraft.motion(reduce: reduceMotion), value: watch.crib.hops.count)
            CribRule()
        }
    }

    private var overdueBlock: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Overdue")
                .font(CribFace.font(.headline))
                .foregroundStyle(CribInk.Palette.ink)
                .padding(.bottom, CribCraft.space(1))
            ForEach(watch.overdueTags) { tag in
                Button {
                    pickedOverdueID = tag.id
                } label: {
                    HStack(alignment: .firstTextBaseline, spacing: CribCraft.space(1)) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(watch.tagName(tag.id))
                                .font(CribFace.font(.body))
                                .foregroundStyle(CribInk.Palette.ink)
                                .lineLimit(1)
                                .truncationMode(.tail)
                            Text(overdueLine(tag))
                                .font(CribFace.font(.caption))
                                .foregroundStyle(CribInk.Palette.muted)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        if let issued = tag.issuedDayKey {
                            overdueFigure(issuedDayKey: issued)
                        }
                    }
                    .padding(.vertical, CribCraft.space(1))
                    .frame(maxWidth: .infinity, minHeight: CribCraft.tap, alignment: .leading)
                    .overlay(alignment: .bottom) {
                        CribRule()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(CribPressStyle(enabled: true))
                .accessibilityLabel(watch.tagName(tag.id))
                .accessibilityValue(overdueSpoken(tag))
                .accessibilityAddTraits(tag.id == shownOverdue?.id ? .isSelected : [])
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Overdue issued Tags")
    }

    private var hopBlock: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Hops")
                .font(CribFace.font(.headline))
                .foregroundStyle(CribInk.Palette.ink)
                .padding(.bottom, CribCraft.space(1))
            ForEach(watch.recentHops) { hop in
                HStack(alignment: .firstTextBaseline, spacing: CribCraft.space(1)) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(watch.tagName(hop.tagID))
                            .font(CribFace.font(.body))
                            .foregroundStyle(CribInk.Palette.ink)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Text(hopLine(hop))
                            .font(CribFace.font(.caption))
                            .foregroundStyle(CribInk.Palette.muted)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Text(CribFigures.dayKey(hop.dayKey, calendar: watch.calendarForDisplay))
                        .font(CribFace.font(.caption))
                        .monospacedDigit()
                        .foregroundStyle(CribInk.Palette.muted)
                        .lineLimit(1)
                        .layoutPriority(1)
                }
                .frame(maxWidth: .infinity, minHeight: CribCraft.tap, alignment: .leading)
                CribRule()
            }
        }
    }

    private var trailBlock: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Trail")
                .font(CribFace.font(.headline))
                .foregroundStyle(CribInk.Palette.ink)
                .padding(.bottom, CribCraft.space(1))
            ForEach(watch.crib.trailMarks.reversed()) { mark in
                HStack(alignment: .firstTextBaseline, spacing: CribCraft.space(1)) {
                    Text("\(watch.tagName(mark.tagID)) in \(watch.stallName(mark.stallID))")
                        .font(CribFace.font(.body))
                        .foregroundStyle(CribInk.Palette.ink)
                        .lineLimit(2)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(CribFigures.dayKey(mark.dayKey, calendar: watch.calendarForDisplay))
                        .font(CribFace.font(.caption))
                        .monospacedDigit()
                        .foregroundStyle(CribInk.Palette.muted)
                        .lineLimit(1)
                        .layoutPriority(1)
                }
                .frame(maxWidth: .infinity, minHeight: CribCraft.tap, alignment: .leading)
                CribRule()
            }
        }
    }

    private var nextHopInk: some View {
        VStack(alignment: .leading, spacing: CribCraft.space(1)) {
            if let tag = shownOverdue {
                Text("Next hop")
                    .font(CribFace.font(.headline))
                    .foregroundStyle(CribInk.Palette.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(watch.tagName(tag.id))
                    .font(CribFace.font(.body))
                    .foregroundStyle(CribInk.Palette.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(overdueStoryLine(tag))
                    .font(CribFace.font(.body))
                    .foregroundStyle(CribInk.Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                ForEach(watch.hops(for: tag.id)) { hop in
                    Text(hopStory(hop))
                        .font(CribFace.font(.caption))
                        .foregroundStyle(CribInk.Palette.muted)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, minHeight: CribCraft.tap, alignment: .leading)
                    CribRule()
                }
                ForEach(watch.crib.trail(for: tag.id)) { mark in
                    Text("Trail in \(watch.stallName(mark.stallID)) on \(CribFigures.dayKey(mark.dayKey, calendar: watch.calendarForDisplay)).")
                        .font(CribFace.font(.caption))
                        .foregroundStyle(CribInk.Palette.muted)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, minHeight: CribCraft.tap, alignment: .leading)
                    CribRule()
                }
                Text(nextHopHint(tag))
                    .font(CribFace.font(.body))
                    .foregroundStyle(CribInk.Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                CribVerbButton(
                    title: "Scan",
                    detail: nextHopDetail(tag),
                    kind: .primary,
                    enabled: watch.canSeatTag && !watch.isCommitting,
                    hint: "Opens capture to hop this Tag into the open stall"
                ) {
                    watch.focus(tag.id)
                    watch.jumpInventory()
                    watch.openCapture()
                }
            } else {
                Text("Hop trail")
                    .font(CribFace.font(.headline))
                    .foregroundStyle(CribInk.Palette.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                ForEach(watch.recentHops) { hop in
                    Text(hopStory(hop))
                        .font(CribFace.font(.caption))
                        .foregroundStyle(CribInk.Palette.muted)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, minHeight: CribCraft.tap, alignment: .leading)
                    CribRule()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var seatedNow: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Seated now")
                .font(CribFace.font(.headline))
                .foregroundStyle(CribInk.Palette.ink)
                .padding(.bottom, CribCraft.space(1))
                .frame(maxWidth: .infinity, alignment: .leading)
            ForEach(watch.crib.stalls) { stall in
                seatedStall(stall)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func seatedStall(_ stall: Stall) -> some View {
        let tags = watch.crib.tags(in: stall.id)
        let marks = watch.crib.trailMarks.filter { $0.stallID == stall.id }
        return VStack(alignment: .leading, spacing: 0) {
            Text(stall.name)
                .font(CribFace.font(.body))
                .foregroundStyle(CribInk.Palette.ink)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(seatedDutyLine(stall, empty: tags.isEmpty))
                .font(CribFace.font(.caption))
                .foregroundStyle(CribInk.Palette.muted)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, CribCraft.space(1))
            if tags.isEmpty {
                Text("No Tags seated. Scan into this stall to seat one.")
                    .font(CribFace.font(.caption))
                    .foregroundStyle(CribInk.Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, minHeight: CribCraft.tap, alignment: .leading)
                CribRule()
            } else {
                ForEach(tags) { tag in
                    Text(seatedTagLine(tag))
                        .font(CribFace.font(.caption))
                        .foregroundStyle(CribInk.Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, minHeight: CribCraft.tap, alignment: .leading)
                    CribRule()
                }
            }
            if marks.isEmpty {
                Text("No trail in \(stall.name) yet. Hop a Tag here to write one.")
                    .font(CribFace.font(.caption))
                    .foregroundStyle(CribInk.Palette.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, minHeight: CribCraft.tap, alignment: .leading)
                CribRule()
            } else {
                ForEach(marks) { mark in
                    Text(seatedTrailLine(mark))
                        .font(CribFace.font(.caption))
                        .foregroundStyle(CribInk.Palette.muted)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, minHeight: CribCraft.tap, alignment: .leading)
                    CribRule()
                }
            }
        }
        .padding(.bottom, CribCraft.space(2))
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var shownOverdue: Tag? {
        if let pickedOverdueID, let match = watch.overdueTags.first(where: { $0.id == pickedOverdueID }) {
            return match
        }
        return watch.overdueTags.first
    }

    @ViewBuilder
    private func overdueFigure(issuedDayKey: Int) -> some View {
        let days = CribFigures.issuedDays(
            issuedDayKey: issuedDayKey,
            now: watch.now,
            calendar: watch.calendarForDisplay
        )
        VStack(alignment: .trailing, spacing: 0) {
            Text(CribFigures.integer(days))
                .font(CribFace.font(.body))
                .monospacedDigit()
                .foregroundStyle(CribInk.Palette.ink)
                .lineLimit(1)
            Text(days == 1 ? "day overdue" : "days overdue")
                .font(CribFace.font(.micro))
                .foregroundStyle(CribInk.Palette.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .layoutPriority(1)
        .accessibilityLabel(CribFigures.issuedSpan(
            issuedDayKey: issuedDayKey,
            now: watch.now,
            calendar: watch.calendarForDisplay
        ))
    }

    private func overdueLine(_ tag: Tag) -> String {
        let who = tag.assignedTo ?? watch.stallName(tag.stallID)
        return "Issued to \(who). \(watch.stallName(tag.stallID))."
    }

    private func overdueStoryLine(_ tag: Tag) -> String {
        let who = tag.assignedTo ?? watch.stallName(tag.stallID)
        if let issued = tag.issuedDayKey {
            return "Issued to \(who) in \(watch.stallName(tag.stallID)). \(CribFigures.issuedSpan(issuedDayKey: issued, now: watch.now, calendar: watch.calendarForDisplay))."
        }
        return overdueLine(tag)
    }

    private func overdueSpoken(_ tag: Tag) -> String {
        if let issued = tag.issuedDayKey {
            return "\(overdueLine(tag)) \(CribFigures.issuedSpan(issuedDayKey: issued, now: watch.now, calendar: watch.calendarForDisplay))"
        }
        return overdueLine(tag)
    }

    private func hopLine(_ hop: Hop) -> String {
        "\(watch.stallName(hop.fromStallID)) to \(watch.stallName(hop.toStallID)), \(hop.assignedTo)."
    }

    private func hopStory(_ hop: Hop) -> String {
        let day = CribFigures.dayKey(hop.dayKey, calendar: watch.calendarForDisplay)
        return "\(day). \(watch.stallName(hop.fromStallID)) to \(watch.stallName(hop.toStallID)). \(hop.assignedTo) received \(watch.tagName(hop.tagID))."
    }

    private func nextHopHint(_ tag: Tag) -> String {
        if let open = watch.openStall, open.id != tag.stallID {
            return "Scan \(watch.tagName(tag.id)) into \(open.name) to hop it from \(watch.stallName(tag.stallID))."
        }
        return "Open another stall, then scan \(watch.tagName(tag.id)) to hop it."
    }

    private func nextHopDetail(_ tag: Tag) -> String {
        if let open = watch.openStall, open.id != tag.stallID {
            return "Hop \(watch.tagName(tag.id)) into \(open.name)"
        }
        return "Open a stall, then hop \(watch.tagName(tag.id))"
    }

    private func seatedDutyLine(_ stall: Stall, empty: Bool) -> String {
        if empty {
            return "\(CribCopy.duty(stall.duty)). Scan into this stall to seat a Tag."
        }
        return "\(CribCopy.duty(stall.duty)). Scan a Tag from another stall to hop it here."
    }

    private func seatedTagLine(_ tag: Tag) -> String {
        let who = tag.assignedTo ?? watch.stallName(tag.stallID)
        var line = "\(watch.tagName(tag.id)). \(CribCopy.status(tag.status)). \(who)."
        if let last = watch.hops(for: tag.id).last {
            line += " Last hop \(watch.stallName(last.fromStallID)) to \(watch.stallName(last.toStallID))."
        }
        return line
    }

    private func seatedTrailLine(_ mark: TrailMark) -> String {
        let day = CribFigures.dayKey(mark.dayKey, calendar: watch.calendarForDisplay)
        return "Trail: \(watch.tagName(mark.tagID)) on \(day)."
    }
}
