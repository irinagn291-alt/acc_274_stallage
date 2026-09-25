import CoreImage.CIFilterBuiltins
import SwiftUI
import UniformTypeIdentifiers
#if canImport(UIKit)
import UIKit
#endif

/// Role: Crib. Local QR cover. Payload is code if present, else id. No remote catalog.
struct CribMarkShare: View {
    @Bindable var watch: CribWatch

    var body: some View {
        VStack(alignment: .leading, spacing: CribCraft.space(2)) {
            CribSheetBar(title: title) {
                watch.dismissCover()
                watch.markKind = nil
            }
            Spacer(minLength: CribCraft.space(2))
            qrBlock
            Text(payload)
                .font(CribFace.font(.caption))
                .monospacedDigit()
                .foregroundStyle(CribInk.Palette.muted)
                .lineLimit(3)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
            Spacer(minLength: CribCraft.space(2))
            if let image = qrImage {
                ShareLink(
                    item: CribQRItem(image: image, title: title),
                    preview: SharePreview(title, image: Image(uiImage: image))
                ) {
                    capsuleLabel("Share QR")
                }
                .buttonStyle(CribPressStyle(enabled: true))
            }
            CribVerbButton(title: "Close", kind: .quiet) {
                watch.dismissCover()
                watch.markKind = nil
            }
        }
        .padding(CribCraft.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CribInk.Palette.background.ignoresSafeArea())
    }

    private var title: String {
        guard let kind = watch.markKind else { return "QR" }
        return watch.markTitle(kind)
    }

    private var payload: String {
        guard let kind = watch.markKind else { return "" }
        return watch.markPayload(kind)
    }

    private var qrImage: UIImage? {
        CribMarkDraw.image(payload: payload)
    }

    @ViewBuilder
    private var qrBlock: some View {
        if let image = qrImage {
            Image(uiImage: image)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: CribCraft.space(28), maxHeight: CribCraft.space(28))
                .padding(CribCraft.space(2))
                .frame(maxWidth: .infinity)
                .background(CribInk.Palette.surface, in: CribCraft.cardShape)
                .overlay {
                    CribCraft.cardShape.stroke(CribInk.Palette.muted.opacity(0.45), lineWidth: CribCraft.hairline)
                }
                .cribLift()
                .frame(maxWidth: .infinity)
                .accessibilityLabel("QR for \(title)")
        } else {
            Text("QR could not be drawn.")
                .font(CribFace.font(.body))
                .foregroundStyle(CribInk.Palette.muted)
                .frame(maxWidth: .infinity)
        }
    }

    private func capsuleLabel(_ title: String) -> some View {
        Text(title)
            .font(CribFace.font(.body))
            .foregroundStyle(CribInk.Palette.ink)
            .frame(maxWidth: .infinity, minHeight: CribCraft.tap)
            .background(CribInk.Palette.accent, in: Capsule())
            .overlay {
                Capsule().stroke(CribInk.Palette.accent, lineWidth: CribCraft.hairline)
            }
            .cribLift()
            .contentShape(Capsule())
    }
}

/// Role: Crib. Draws QR on device from a payload. Never fetches a catalog.
enum CribMarkDraw {
    static func image(payload: String) -> UIImage? {
        let trimmed = payload.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let data = trimmed.data(using: .ascii) ?? trimmed.data(using: .utf8) else {
            return nil
        }
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 12, y: 12))
        let context = CIContext()
        guard let cg = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
}

struct CribQRItem: Transferable {
    let image: UIImage
    let title: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { item in
            item.image.pngData() ?? Data()
        }
    }
}
