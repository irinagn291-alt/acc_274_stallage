import SwiftUI

/// Role: Hop. Twist screen for stall-then-hop. Own cover plus the Inventory scan surface.
struct HopTrailPane: View {
    @Bindable var watch: CribWatch
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: CribCraft.space(2)) {
            CribSheetBar(title: "Stall then hop") {
                watch.dismissCover()
            }
            Group {
                switch watch.twistLoad {
                case .fault:
                    CribVacancy(
                        image: "slg_TwistHero",
                        headline: "The trail could not be read",
                        line: watch.fault ?? "The last copy failed. Try again.",
                        actionTitle: "Retry"
                    ) {
                        Task { await watch.retry() }
                    }
                case .empty:
                    CribVacancy(
                        image: "slg_TwistHero",
                        headline: "Seat here. Hop there.",
                        line: "An unknown code writes a Tag into the open stall. Scan that Tag in another stall to hop it.",
                        actionTitle: "Open Inventory"
                    ) {
                        watch.jumpInventory()
                    }
                case .populated:
                    populated
                }
            }
        }
        .padding(CribCraft.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(CribInk.Palette.background.ignoresSafeArea())
    }

    private var populated: some View {
        VStack(alignment: .leading, spacing: CribCraft.space(2)) {
            if CribArt.present("slg_TwistHero") {
                Image("slg_TwistHero")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: CribCraft.space(16))
                    .padding(CribCraft.space(2))
                    .frame(maxWidth: .infinity)
                    .background(CribInk.Palette.surface, in: CribCraft.cardShape)
                    .accessibilityHidden(true)
            }
            Text(watch.hopCountLabel)
                .font(CribFace.font(.display))
                .monospacedDigit()
                .foregroundStyle(CribInk.Palette.accent)
                .contentTransition(reduceMotion ? .identity : .numericText())
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityLabel("Hops \(watch.hopCountLabel)")
                .animation(CribCraft.motion(reduce: reduceMotion), value: watch.crib.hops.count)
            Text("A new scan writes a Tag into the open stall. A known scan into another stall writes a Hop and a TrailMark. Relinquished freezes hops on that Tag.")
                .font(CribFace.font(.body))
                .foregroundStyle(CribInk.Palette.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Trail \(CribFigures.integer(watch.crib.trailMarks.count)). Overdue \(watch.overdueCountLabel).")
                .font(CribFace.font(.caption))
                .foregroundStyle(CribInk.Palette.muted)
                .frame(maxWidth: .infinity, alignment: .leading)
            CribSurface(padded: false) {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(watch.recentHops) { hop in
                            HStack(alignment: .firstTextBaseline, spacing: CribCraft.space(1)) {
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(watch.tagName(hop.tagID))
                                        .font(CribFace.font(.body))
                                        .foregroundStyle(CribInk.Palette.ink)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                    Text("\(watch.stallName(hop.fromStallID)) to \(watch.stallName(hop.toStallID)), \(hop.assignedTo).")
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
                            .padding(.horizontal, CribCraft.space(2))
                            .frame(maxWidth: .infinity, minHeight: CribCraft.tap, alignment: .leading)
                            CribRule()
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            CribVerbButton(title: "Open Inventory", kind: .primary) {
                watch.jumpInventory()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
