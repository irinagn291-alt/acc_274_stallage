import SwiftUI

/// Role: Crib. Onboarding cover. Four pages. Skip writes default stalls. Re-runnable from Settings.
struct CribOnboard: View {
    @Bindable var watch: CribWatch
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    var body: some View {
        VStack(spacing: CribCraft.space(2)) {
            ScrollView {
                VStack(alignment: .leading, spacing: CribCraft.space(2)) {
                    if CribArt.present(art) {
                        Image(art)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .frame(maxHeight: CribCraft.space(36))
                            .accessibilityHidden(true)
                    }
                    Text(title)
                        .font(CribFace.font(.title))
                        .foregroundStyle(CribInk.Palette.ink)
                        .lineLimit(3)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(line)
                        .font(CribFace.font(.body))
                        .foregroundStyle(CribInk.Palette.muted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollDismissesKeyboard(.interactively)
            .animation(CribCraft.motion(reduce: reduceMotion), value: page)
            CribVerbButton(
                title: page == 3 ? "Continue" : "Next",
                kind: .primary
            ) {
                if page == 3 {
                    Task { await watch.finishOnboarding() }
                } else {
                    withAnimation(CribCraft.motion(reduce: reduceMotion)) {
                        page += 1
                    }
                }
            }
            CribVerbButton(
                title: "Skip",
                kind: .quiet
            ) {
                Task { await watch.finishOnboarding() }
            }
        }
        .padding(CribCraft.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CribInk.Palette.background.ignoresSafeArea())
        .interactiveDismissDisabled()
    }

    private var art: String {
        switch page {
        case 0: "slg_Onboarding1"
        case 1: "slg_Onboarding2"
        case 2: "slg_Onboarding3"
        default: "slg_TwistHero"
        }
    }

    private var title: String {
        switch page {
        case 0: "Keep each belonging in a stall"
        case 1: "Scan seats. Scan hops."
        case 2: "Lent, overdue, freeze"
        default: "QR stays on this device"
        }
    }

    private var line: String {
        switch page {
        case 0:
            "Scan a barcode or QR into the open stall. You will know where it sits and who last received it."
        case 1:
            "An unknown code writes a Tag here. The same Tag in another stall hops it, with a trail."
        case 2:
            "Lent writes who received it. Issued longer than 30 days ranks on Lifecycle. Relinquish freezes that Tag."
        default:
            "QR is the code if you have one, otherwise the id. Search stays on this device."
        }
    }
}
