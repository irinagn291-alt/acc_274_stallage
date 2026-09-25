import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Role: Crib. Spacing, radii, elevation, and quiet motion. Views never invent a second radius or shadow.
enum CribCraft {
    static let unit: CGFloat = 8
    static let tap: CGFloat = 44
    static let cardRadius: CGFloat = 20
    static let chipRadius: CGFloat = 12
    static let hairline: CGFloat = 1
    static let pressScale: CGFloat = 0.98
    static let liftOpacity: Double = 0.22
    static let liftRadius: CGFloat = unit * 2
    static let liftY: CGFloat = unit
    static let crossFade = Animation.easeOut(duration: 0.18)
    static let instant = Animation.easeOut(duration: 0)

    static func space(_ steps: Int) -> CGFloat {
        unit * CGFloat(steps)
    }

    static var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
    }

    static var chipShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: chipRadius, style: .continuous)
    }

    static func motion(reduce: Bool) -> Animation {
        reduce ? instant : crossFade
    }
}

/// Role: Crib. Hairline rule for the journal date rail. Not a box.
struct CribRule: View {
    var body: some View {
        Rectangle()
            .fill(CribInk.Palette.muted.opacity(0.45))
            .frame(height: CribCraft.hairline)
            .frame(maxWidth: .infinity)
            .accessibilityHidden(true)
    }
}

/// Role: Crib. One elevated surface. Cards, sheets, and grouped rows share this token.
struct CribSurface<Content: View>: View {
    var padded: Bool
    var fills: Bool
    var content: Content

    init(padded: Bool = true, fills: Bool = false, @ViewBuilder content: () -> Content) {
        self.padded = padded
        self.fills = fills
        self.content = content()
    }

    var body: some View {
        content
            .padding(padded ? CribCraft.space(2) : 0)
            .frame(maxWidth: .infinity, maxHeight: fills ? .infinity : nil, alignment: .topLeading)
            .background(CribInk.Palette.surface, in: CribCraft.cardShape)
            .overlay {
                CribCraft.cardShape.stroke(
                    CribInk.Palette.muted.opacity(0.45),
                    lineWidth: CribCraft.hairline
                )
            }
            .cribLift()
    }
}

/// Role: Crib. Wrapping chip rail. Status chips stay fully on-canvas.
struct CribFlow: Layout {
    var spacing: CGFloat = CribCraft.space(1)

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        cluster(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let placed = cluster(
            proposal: ProposedViewSize(width: bounds.width, height: bounds.height),
            subviews: subviews
        )
        for (subview, origin) in zip(subviews, placed.origins) {
            let size = subview.sizeThatFits(.unspecified)
            subview.place(
                at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y),
                proposal: ProposedViewSize(size)
            )
        }
    }

    private func cluster(proposal: ProposedViewSize, subviews: Subviews) -> (origins: [CGPoint], size: CGSize) {
        let limit = proposal.width ?? .greatestFiniteMagnitude
        var origins: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > limit {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            origins.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            maxX = max(maxX, x - spacing)
            rowHeight = max(rowHeight, size.height)
        }
        return (origins, CGSize(width: maxX, height: y + rowHeight))
    }
}

/// Role: Crib. Hop count meter. Accent fill, muted remainder. Not a second green.
struct CribHopMeter: View {
    var hops: Int
    var cap: Int = 8

    var body: some View {
        let ticks = max(cap, hops, 1)
        HStack(spacing: CribCraft.hairline) {
            ForEach(0..<ticks, id: \.self) { index in
                Rectangle()
                    .fill(index < hops ? CribInk.Palette.accent : CribInk.Palette.muted.opacity(0.35))
            }
        }
        .frame(width: CribCraft.space(10), height: CribCraft.hairline * 3)
        .accessibilityHidden(true)
    }
}

/// Role: Crib. Named art only when the imageset holds a bitmap.
enum CribArt {
    static func present(_ name: String) -> Bool {
        #if canImport(UIKit)
        UIImage(named: name) != nil
        #else
        false
        #endif
    }
}

/// Role: Crib. Pressed scale. Reduce Motion fades. Disabled is faded, not identical.
struct CribPressStyle: ButtonStyle {
    var enabled: Bool
    var loading: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        CribPressBody(configuration: configuration, enabled: enabled, loading: loading)
    }
}

private struct CribPressBody: View {
    var configuration: ButtonStyle.Configuration
    var enabled: Bool
    var loading: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        configuration.label
            .scaleEffect(!reduceMotion && configuration.isPressed && enabled && !loading ? CribCraft.pressScale : 1)
            .opacity(enabled ? (configuration.isPressed ? 0.88 : 1) : 0.45)
            .animation(CribCraft.motion(reduce: reduceMotion), value: configuration.isPressed)
    }
}

enum CribVerbKind: Equatable, Sendable {
    case primary
    case quiet
    case destroy
}

/// Role: Crib. Primary is a full-width filled Capsule. Destroy does not wear accent.
struct CribVerbButton: View {
    var title: String
    var detail: String? = nil
    var kind: CribVerbKind
    var fills: Bool = true
    var enabled: Bool = true
    var loading: Bool = false
    var hint: String? = nil
    var action: () -> Void

    private var active: Bool { enabled && !loading }

    var body: some View {
        Button(action: action) {
            HStack(spacing: CribCraft.space(1)) {
                if loading {
                    ProgressView()
                        .tint(labelInk)
                        .frame(width: CribCraft.space(2), height: CribCraft.space(2))
                }
                VStack(spacing: 0) {
                    Text(title)
                        .font(CribFace.font(.body))
                        .foregroundStyle(labelInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    if let detail {
                        Text(detail)
                            .font(CribFace.font(.caption))
                            .foregroundStyle(detailInk)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
                .frame(maxWidth: fills ? .infinity : nil)
            }
            .padding(.horizontal, CribCraft.space(2))
            .frame(maxWidth: fills ? .infinity : nil, minHeight: CribCraft.tap)
            .background(fillPaint, in: shape)
            .overlay {
                shape.stroke(strokePaint, lineWidth: CribCraft.hairline)
            }
            .cribLift()
            .contentShape(shape)
        }
        .buttonStyle(CribPressStyle(enabled: active, loading: loading))
        .disabled(!active)
        .accessibilityLabel(detail.map { "\(title). \($0)" } ?? title)
        .accessibilityHint(hint ?? "")
    }

    private var shape: Capsule {
        Capsule()
    }

    private var labelInk: Color {
        active ? CribInk.Palette.ink : CribInk.Palette.muted
    }

    private var detailInk: Color {
        switch kind {
        case .primary:
            active ? CribInk.Palette.background : CribInk.Palette.muted
        case .quiet, .destroy:
            active ? CribInk.Palette.ink.opacity(0.86) : CribInk.Palette.muted
        }
    }

    private var fillPaint: Color {
        switch kind {
        case .primary:
            CribInk.Palette.accent.opacity(active ? 1 : 0.35)
        case .quiet:
            CribInk.Palette.surface
        case .destroy:
            CribInk.Palette.muted.opacity(active ? 0.28 : 0.12)
        }
    }

    private var strokePaint: Color {
        switch kind {
        case .primary:
            CribInk.Palette.accent.opacity(active ? 0.9 : 0.25)
        case .quiet:
            CribInk.Palette.muted.opacity(0.45)
        case .destroy:
            CribInk.Palette.muted.opacity(0.55)
        }
    }
}

/// Role: Crib. Full-page empty or fault. Cutout art, one headline, one line, bottom full-width CTA.
struct CribVacancy: View {
    var image: String
    var headline: String
    var line: String
    var actionTitle: String
    var enabled: Bool = true
    var loading: Bool = false
    var action: () -> Void

    var body: some View {
        VStack(spacing: CribCraft.space(2)) {
            VStack(spacing: CribCraft.space(2)) {
                if CribArt.present(image) {
                    Image(image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: CribCraft.space(28), maxHeight: CribCraft.space(28))
                        .accessibilityHidden(true)
                }
                Text(headline)
                    .font(CribFace.font(.title))
                    .foregroundStyle(CribInk.Palette.ink)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity)
                Text(line)
                    .font(CribFace.font(.body))
                    .foregroundStyle(CribInk.Palette.muted)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            CribVerbButton(
                title: actionTitle,
                kind: .primary,
                enabled: enabled,
                loading: loading,
                action: action
            )
        }
        .padding(.horizontal, CribCraft.space(2))
        .padding(.bottom, CribCraft.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CribInk.Palette.background)
    }
}

/// Role: Crib. Recoverable fault with Retry.
struct CribBanner: View {
    var text: String
    var retryTitle: String = "Retry"
    var retry: () -> Void

    var body: some View {
        HStack(spacing: CribCraft.space(1)) {
            Text(text)
                .font(CribFace.font(.caption))
                .foregroundStyle(CribInk.Palette.ink)
                .lineLimit(3)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: retry) {
                Text(retryTitle)
                    .font(CribFace.font(.caption))
                    .foregroundStyle(CribInk.Palette.ink)
                    .frame(minWidth: CribCraft.tap, minHeight: CribCraft.tap)
                    .padding(.horizontal, CribCraft.space(1))
                    .background(CribInk.Palette.surface, in: CribCraft.chipShape)
                    .overlay {
                        CribCraft.chipShape.stroke(
                            CribInk.Palette.muted.opacity(0.45),
                            lineWidth: CribCraft.hairline
                        )
                    }
                    .contentShape(CribCraft.chipShape)
            }
            .buttonStyle(CribPressStyle(enabled: true))
            .accessibilityLabel(retryTitle)
        }
        .padding(.horizontal, CribCraft.space(2))
        .padding(.vertical, CribCraft.space(1))
        .frame(maxWidth: .infinity, minHeight: CribCraft.tap, alignment: .leading)
        .background(CribInk.Palette.surface, in: CribCraft.cardShape)
        .overlay {
            CribCraft.cardShape.stroke(CribInk.Palette.muted.opacity(0.45), lineWidth: CribCraft.hairline)
        }
        .cribLift()
    }
}

/// Role: Crib. Cover header with a dismiss that always works.
struct CribSheetBar: View {
    var title: String
    var onClose: () -> Void

    var body: some View {
        HStack(spacing: CribCraft.space(1)) {
            Text(title)
                .font(CribFace.font(.title))
                .foregroundStyle(CribInk.Palette.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 0)
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(CribFace.font(.body))
                    .foregroundStyle(CribInk.Palette.ink)
                    .frame(width: CribCraft.tap, height: CribCraft.tap)
                    .contentShape(Rectangle())
            }
            .buttonStyle(CribPressStyle(enabled: true))
            .accessibilityLabel("Close")
        }
        .frame(maxWidth: .infinity, minHeight: CribCraft.tap)
    }
}

/// Role: Crib. Duty and status chips. Selected is filled, not colour alone.
struct CribChip: View {
    var title: String
    var selected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(CribFace.font(.caption))
                .foregroundStyle(selected ? CribInk.Palette.ink : CribInk.Palette.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, CribCraft.space(2))
                .frame(minHeight: CribCraft.tap)
                .background(
                    selected ? CribInk.Palette.accent.opacity(0.85) : CribInk.Palette.surface,
                    in: CribCraft.chipShape
                )
                .overlay {
                    CribCraft.chipShape.stroke(
                        selected ? CribInk.Palette.accent : CribInk.Palette.muted.opacity(0.45),
                        lineWidth: selected ? CribCraft.hairline * 2 : CribCraft.hairline
                    )
                }
                .contentShape(CribCraft.chipShape)
        }
        .buttonStyle(CribPressStyle(enabled: true))
        .cribLift()
        .accessibilityLabel(title)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

extension View {
    func cribScreen() -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(CribInk.Palette.background.ignoresSafeArea())
    }

    /// Single soft drop-shadow. Reused everywhere a surface sits above another.
    func cribLift() -> some View {
        shadow(
            color: CribInk.Palette.ink.opacity(CribCraft.liftOpacity),
            radius: CribCraft.liftRadius,
            x: 0,
            y: CribCraft.liftY
        )
    }

    func cribDismissKeyboardOnBackground() -> some View {
        background {
            CribInk.Palette.background
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    #if canImport(UIKit)
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil,
                        from: nil,
                        for: nil
                    )
                    #endif
                }
        }
    }
}
