import AVFoundation
import SwiftUI
import UIKit

/// Role: Crib. Capture cover over Inventory. Unknown seats, known hops. The only UIViewRepresentable is the metadata preview.
struct StallCapture: View {
    @Bindable var watch: CribWatch
    @Environment(\.scenePhase) private var scenePhase
    @State private var gate: CaptureGate = .checking
    @State private var typed = ""
    @State private var lastPayload = ""
    @State private var lastStamp: CFTimeInterval = 0
    @FocusState private var typedFocus: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: CribCraft.space(2)) {
            CribSheetBar(title: "Scan into \(watch.openStall?.name ?? "this stall")") {
                watch.dismissCover()
            }
            if let fault = watch.fault {
                CribBanner(text: fault) {
                    watch.fault = nil
                }
            } else if let notice = watch.notice {
                Text(notice)
                    .font(CribFace.font(.caption))
                    .foregroundStyle(CribInk.Palette.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            receiverField
            pane
        }
        .padding(CribCraft.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(CribInk.Palette.background.ignoresSafeArea())
        .scrollDismissesKeyboard(.interactively)
        .cribDismissKeyboardOnBackground()
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    typedFocus = false
                }
                .font(CribFace.font(.body))
            }
        }
        .onAppear {
            resolveGate()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                watch.captureRunning = false
            } else if gate == .live {
                watch.captureRunning = true
            }
        }
    }

    @ViewBuilder
    private var pane: some View {
        switch gate {
        case .checking:
            ProgressView()
                .tint(CribInk.Palette.accent)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .needsContinue:
            continuePage
        case .denied:
            deniedPage
        case .simulator:
            simulatorPage
        case .live:
            livePage
        }
    }

    private var continuePage: some View {
        VStack(spacing: CribCraft.space(2)) {
            Spacer(minLength: CribCraft.space(2))
            if CribArt.present("slg_ControlFace") {
                Image("slg_ControlFace")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: CribCraft.space(16), maxHeight: CribCraft.space(16))
                    .accessibilityHidden(true)
            }
            Text("Read a barcode or QR")
                .font(CribFace.font(.title))
                .foregroundStyle(CribInk.Palette.ink)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            Text("Stallage uses the camera to seat a Tag in the open stall, or hop one in from another stall.")
                .font(CribFace.font(.body))
                .foregroundStyle(CribInk.Palette.muted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            Spacer(minLength: CribCraft.space(2))
            CribVerbButton(title: "Continue", kind: .primary) {
                requestAccess()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var deniedPage: some View {
        VStack(spacing: CribCraft.space(2)) {
            Spacer(minLength: CribCraft.space(2))
            Text("Camera is off")
                .font(CribFace.font(.title))
                .foregroundStyle(CribInk.Palette.ink)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            Text("Stallage reads a barcode or QR to seat a Tag. Open Settings if you want the camera, or type a code below.")
                .font(CribFace.font(.body))
                .foregroundStyle(CribInk.Palette.muted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            Spacer(minLength: CribCraft.space(2))
            manualBlock
            CribVerbButton(title: "Open Settings", kind: .primary) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var simulatorPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CribCraft.space(2)) {
                Text("No camera on this device. Use a sample code or type one.")
                    .font(CribFace.font(.body))
                    .foregroundStyle(CribInk.Palette.muted)
                chips
                manualBlock
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollDismissesKeyboard(.interactively)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var livePage: some View {
        VStack(spacing: CribCraft.space(2)) {
            ZStack {
                StallPreviewPane(
                    running: watch.captureRunning && scenePhase == .active,
                    onPayload: handlePayload
                )
                StallReticle()
                    .stroke(CribInk.Palette.ink, lineWidth: CribCraft.hairline * 2)
                    .frame(width: CribCraft.space(28), height: CribCraft.space(18))
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            .clipShape(CribCraft.cardShape)
            .overlay {
                CribCraft.cardShape.stroke(CribInk.Palette.muted.opacity(0.45), lineWidth: CribCraft.hairline)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .cribLift()
            Text("Hold a barcode or QR in the frame. An unknown code seats. A known Tag from another stall hops.")
                .font(CribFace.font(.caption))
                .foregroundStyle(CribInk.Palette.muted)
            manualBlock
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var receiverField: some View {
        TextField("Received by, if Lent", text: $watch.assignedDraft)
            .font(CribFace.font(.body))
            .foregroundStyle(CribInk.Palette.ink)
            .textInputAutocapitalization(.words)
            .padding(.horizontal, CribCraft.space(2))
            .frame(maxWidth: .infinity, minHeight: CribCraft.tap)
            .background(CribInk.Palette.surface, in: CribCraft.chipShape)
            .overlay {
                CribCraft.chipShape.stroke(CribInk.Palette.muted.opacity(0.45), lineWidth: CribCraft.hairline)
            }
            .cribLift()
            .accessibilityLabel("Received by")
    }

    private var manualBlock: some View {
        VStack(alignment: .leading, spacing: CribCraft.space(1)) {
            TextField("Type or paste a code", text: $typed)
                .font(CribFace.font(.body))
                .foregroundStyle(CribInk.Palette.ink)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($typedFocus)
                .submitLabel(.go)
                .onSubmit {
                    submitTyped()
                }
                .padding(.horizontal, CribCraft.space(2))
                .frame(maxWidth: .infinity, minHeight: CribCraft.tap)
                .background(CribInk.Palette.surface, in: CribCraft.chipShape)
                .overlay {
                    CribCraft.chipShape.stroke(CribInk.Palette.muted.opacity(0.45), lineWidth: CribCraft.hairline)
                }
                .cribLift()
                .accessibilityLabel("Type or paste a code")
            CribVerbButton(
                title: "Seat or hop",
                kind: .primary,
                enabled: !typed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !watch.isCommitting,
                loading: watch.isCommitting
            ) {
                submitTyped()
            }
        }
    }

    private var chips: some View {
        VStack(alignment: .leading, spacing: CribCraft.space(1)) {
            Text("Sample codes")
                .font(CribFace.font(.headline))
                .foregroundStyle(CribInk.Palette.ink)
            ForEach(sampleChips, id: \.payload) { chip in
                CribVerbButton(
                    title: chip.title,
                    detail: chip.payload,
                    kind: .quiet,
                    enabled: !watch.isCommitting
                ) {
                    handlePayload(chip.payload)
                }
            }
        }
    }

    private var sampleChips: [(title: String, payload: String)] {
        var rows: [(title: String, payload: String)] = []
        for stall in watch.crib.stalls {
            rows.append(("Open \(stall.name)", stall.qrPayload))
        }
        for tag in watch.crib.tags.prefix(6) {
            rows.append((watch.tagName(tag.id), tag.qrPayload))
        }
        if rows.isEmpty {
            rows = [
                ("XLR loom", "12345670"),
                ("Body 5D", "036000291452"),
                ("Clamp light", "5901234123457"),
            ]
        }
        return rows
    }

    private func resolveGate() {
        if AVCaptureDevice.default(for: .video) == nil {
            gate = .simulator
            return
        }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            watch.captureRunning = true
            gate = .live
        case .notDetermined:
            gate = .needsContinue
        default:
            gate = .denied
        }
    }

    private func requestAccess() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            Task { @MainActor in
                if granted {
                    watch.captureRunning = true
                    gate = .live
                } else {
                    gate = .denied
                }
            }
        }
    }

    private func submitTyped() {
        let payload = typed.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !payload.isEmpty else { return }
        typedFocus = false
        handlePayload(payload)
    }

    private func handlePayload(_ payload: String) {
        let trimmed = payload.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if watch.isCommitting { return }
        let now = CACurrentMediaTime()
        if trimmed == lastPayload, now - lastStamp < 1.7 {
            return
        }
        lastPayload = trimmed
        lastStamp = now
        Task { await watch.seat(trimmed) }
    }
}

enum CaptureGate: Equatable {
    case checking
    case needsContinue
    case live
    case denied
    case simulator
}

/// Role: Crib. Scanner frame drawn in SwiftUI. GenerateImage is not used for reticles.
struct StallReticle: Shape {
    func path(in rect: CGRect) -> Path {
        let arm = min(rect.width, rect.height) * 0.22
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + arm))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + arm, y: rect.minY))
        path.move(to: CGPoint(x: rect.maxX - arm, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + arm))
        path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - arm))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - arm, y: rect.maxY))
        path.move(to: CGPoint(x: rect.minX + arm, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - arm))
        return path
    }
}

/// Role: Crib. The only UIViewRepresentable. AVCaptureMetadataOutput preview. Session stops on disappear and background.
struct StallPreviewPane: UIViewRepresentable {
    var running: Bool
    var onPayload: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onPayload: onPayload)
    }

    func makeUIView(context: Context) -> StallPreviewView {
        let view = StallPreviewView()
        view.coordinator = context.coordinator
        return view
    }

    func updateUIView(_ uiView: StallPreviewView, context: Context) {
        context.coordinator.onPayload = onPayload
        uiView.coordinator = context.coordinator
        if running {
            uiView.start()
        } else {
            uiView.stop()
        }
    }

    static func dismantleUIView(_ uiView: StallPreviewView, coordinator: Coordinator) {
        uiView.stop()
    }

    final class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var onPayload: (String) -> Void

        init(onPayload: @escaping (String) -> Void) {
            self.onPayload = onPayload
        }

        func metadataOutput(
            _ output: AVCaptureMetadataOutput,
            didOutput metadataObjects: [AVMetadataObject],
            from connection: AVCaptureConnection
        ) {
            guard
                let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                let value = object.stringValue,
                !value.isEmpty
            else { return }
            onPayload(value)
        }
    }
}

final class StallPreviewView: UIView {
    var coordinator: StallPreviewPane.Coordinator? {
        didSet {
            metadataOutput?.setMetadataObjectsDelegate(coordinator, queue: .main)
        }
    }

    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var metadataOutput: AVCaptureMetadataOutput?
    private var configured = false

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }

    func start() {
        configureIfNeeded()
        if !session.isRunning {
            session.startRunning()
        }
    }

    func stop() {
        if session.isRunning {
            session.stopRunning()
        }
    }

    private func configureIfNeeded() {
        guard !configured else { return }
        configured = true
        session.beginConfiguration()
        session.sessionPreset = session.canSetSessionPreset(.hd1920x1080) ? .hd1920x1080 : .high
        guard
            let device = AVCaptureDevice.default(for: .video),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else {
            session.commitConfiguration()
            return
        }
        session.addInput(input)
        if device.isFocusModeSupported(.continuousAutoFocus) || device.isExposureModeSupported(.continuousAutoExposure) {
            try? device.lockForConfiguration()
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
            device.unlockForConfiguration()
        }

        let metadata = AVCaptureMetadataOutput()
        if session.canAddOutput(metadata) {
            session.addOutput(metadata)
            let wanted: [AVMetadataObject.ObjectType] = [
                .qr, .ean13, .ean8, .upce, .code128, .code39, .code93,
            ]
            metadata.metadataObjectTypes = wanted.filter { metadata.availableMetadataObjectTypes.contains($0) }
            metadata.setMetadataObjectsDelegate(coordinator, queue: .main)
            metadataOutput = metadata
        }

        let video = AVCaptureVideoDataOutput()
        video.alwaysDiscardsLateVideoFrames = true
        if session.canAddOutput(video) {
            session.addOutput(video)
        }
        session.commitConfiguration()

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        layer.addSublayer(preview)
        previewLayer = preview
        preview.frame = bounds
        if let connection = preview.connection, connection.isVideoRotationAngleSupported(90) {
            connection.videoRotationAngle = 90
        }
    }
}
