import Foundation
import Observation
import SwiftUI

/// Role: Crib. Presentation seat over CribStore. Views call seatTag, peelLastHop, and fuseName. They never touch UserDefaults.
@MainActor
@Observable
final class CribWatch {
    let store: any CribStoring
    var crib: Crib
    var warning: CribWarning?
    var segment: CribSegment = .inventory
    var query = ""
    var statusFilter: TagStatus?
    var assignedDraft = ""
    var fuseDraft = ""
    var stallDraft = ""
    var stallDuty: StallDuty = .inStock
    var renameDraft = ""
    var fault: String?
    var notice: String?
    var didLoad = false
    var isHauling = false
    var isCommitting = false
    var commitTick = 0
    var cover: CribCover?
    var fuseTagID: UUID?
    var markKind: CribMarkKind?
    var renameStallID: UUID?
    var captureRunning = true

    private var hookConsumed = false
    private var haulToken: UUID?
    private var appeared = false
    private let calendar: Calendar
    private let clock: @Sendable () -> Date
    private let shouldLoad: Bool
    private let permitSeed: Bool
    var now: Date

    init(
        store: any CribStoring,
        crib: Crib = .empty,
        warning: CribWarning? = nil,
        calendar: Calendar = .current,
        now: Date = Date(),
        clock: @escaping @Sendable () -> Date = { Date() },
        shouldLoad: Bool = true,
        permitSeed: Bool? = nil
    ) {
        self.store = store
        self.crib = crib
        self.warning = warning
        self.calendar = calendar
        self.now = now
        self.clock = clock
        self.shouldLoad = shouldLoad
        self.permitSeed = permitSeed ?? Self.simulatorSeed
    }

    static var simulatorSeed: Bool {
        #if targetEnvironment(simulator)
        true
        #else
        false
        #endif
    }

    static func live() -> CribWatch {
        let directory: URL
        do {
            directory = try CribStore.applicationSupportDirectory()
        } catch {
            directory = FileManager.default.temporaryDirectory.appendingPathComponent(
                "Stallage",
                isDirectory: true
            )
        }
        return CribWatch(store: CribStore(directory: directory))
    }

    static func previewSeeded(now: Date = Date(), calendar: Calendar = .current) -> CribWatch {
        let crib = (try? CribSeed.crib(now: now, calendar: calendar)) ?? .empty
        return CribWatch(
            store: CribHold(crib: crib),
            crib: crib,
            calendar: calendar,
            now: now,
            clock: { now },
            shouldLoad: false,
            permitSeed: false
        )
    }

    static func previewEmpty() -> CribWatch {
        var crib = Crib.empty
        crib.onboardingComplete = true
        return CribWatch(
            store: CribHold(crib: crib),
            crib: crib,
            shouldLoad: false,
            permitSeed: false
        )
    }

    var showsOnboarding: Bool {
        didLoad && !crib.onboardingComplete
    }

    var canSeatTag: Bool { crib.canSeatTag }

    var openStall: Stall? { crib.openStall }

    var visibleTags: [Tag] {
        let sought = crib.seeking(query)
        guard let statusFilter else { return sought }
        return sought.filter { $0.status == statusFilter }
    }

    var overdueTags: [Tag] {
        crib.overdueTags(now: now, calendar: calendar)
    }

    var recentHops: [Hop] {
        crib.hops.reversed()
    }

    var inventoryLoad: CribLoad {
        if warning == .startedEmpty { return .fault }
        if crib.stalls.isEmpty { return .empty }
        if query.isEmpty, statusFilter == nil, visibleTags.isEmpty { return .empty }
        return .populated
    }

    var lifecycleLoad: CribLoad {
        if warning == .startedEmpty { return .fault }
        if crib.hops.isEmpty, crib.trailMarks.isEmpty, overdueTags.isEmpty { return .empty }
        return .populated
    }

    var settingsLoad: CribLoad {
        if warning == .startedEmpty { return .fault }
        if crib.stalls.isEmpty { return .empty }
        return .populated
    }

    var twistLoad: CribLoad {
        if warning == .startedEmpty { return .fault }
        if crib.hops.isEmpty, crib.trailMarks.isEmpty { return .empty }
        return .populated
    }

    var jobTitle: String {
        openStall?.name ?? "Open a stall"
    }

    var jobLine: String {
        if let stall = openStall {
            return "Scan a barcode or QR to seat in \(stall.name). Hop a known Tag in from another stall."
        }
        return "Add a stall in Settings, then scan."
    }

    var hopCountLabel: String {
        CribFigures.integer(crib.hops.count)
    }

    var overdueCountLabel: String {
        CribFigures.integer(overdueTags.count)
    }

    var calendarForDisplay: Calendar { calendar }

    func appear(arguments: [String] = ProcessInfo.processInfo.arguments) async {
        if appeared {
            applyHook(arguments: arguments)
            return
        }
        appeared = true
        now = clock()
        guard shouldLoad else {
            crib = await store.snapshot()
            didLoad = true
            applyHook(arguments: arguments)
            return
        }
        let token = UUID()
        haulToken = token
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 150_000_000)
            guard let self, self.haulToken == token else { return }
            self.isHauling = true
        }
        if permitSeed {
            do {
                _ = try await store.seedDemoIfNeeded(now: now, calendar: calendar)
            } catch {
                fault = "The crib could not be seeded."
            }
        }
        let loaded = await store.load()
        crib = loaded.crib
        warning = loaded.warning
        applyWarning()
        haulToken = nil
        isHauling = false
        didLoad = true
        applyHook(arguments: arguments)
    }

    func retry() async {
        fault = nil
        notice = nil
        warning = nil
        appeared = false
        didLoad = false
        hookConsumed = false
        await appear()
    }

    func flush() async {
        do {
            try await store.flush()
        } catch {
            fault = "The crib could not be written."
        }
    }

    func handlePhase(_ phase: ScenePhase) {
        switch phase {
        case .inactive, .background:
            captureRunning = false
            Task { await flush() }
        case .active:
            captureRunning = true
            now = clock()
        @unknown default:
            break
        }
    }

    func refreshDay() {
        now = clock()
    }

    func seat(_ raw: String) async {
        guard !isCommitting else { return }
        isCommitting = true
        defer { isCommitting = false }
        let receiver = assignedDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            let outcome = try await store.seatTag(
                raw,
                now: clock(),
                calendar: calendar,
                assignedTo: receiver.isEmpty ? nil : receiver
            )
            crib = await store.snapshot()
            fault = nil
            switch outcome {
            case .seated(let tagID):
                commitTick += 1
                fuseTagID = tagID
                fuseDraft = crib.tag(id: tagID)?.name ?? ""
                cover = crib.tag(id: tagID)?.needsName == true ? .fuse : nil
            case .hopped:
                commitTick += 1
                assignedDraft = ""
                notice = hopNotice()
                cover = nil
            case .focused:
                notice = "This Tag already sits in the open stall."
                cover = nil
            case .frozen:
                notice = "This Tag is relinquished. Hops stay frozen."
                cover = nil
            case .openedStall:
                notice = "Open stall is \(openStall?.name ?? "ready"). Scan a Tag to hop it here."
            }
        } catch {
            fault = CribCopy.fault(error)
        }
    }

    func fuseName() async {
        guard let fuseTagID else { return }
        guard !isCommitting else { return }
        isCommitting = true
        defer { isCommitting = false }
        do {
            crib = try await store.fuseName(tagID: fuseTagID, name: fuseDraft)
            fault = nil
            cover = nil
            self.fuseTagID = nil
            fuseDraft = ""
        } catch {
            fault = CribCopy.fault(error)
        }
    }

    func dismissFuse() {
        cover = nil
        fuseTagID = nil
        fuseDraft = ""
    }

    func dismissCover() {
        cover = nil
    }

    func openStall(_ stallID: UUID) async {
        guard !isCommitting else { return }
        isCommitting = true
        defer { isCommitting = false }
        do {
            crib = try await store.openStall(stallID)
            fault = nil
        } catch {
            fault = CribCopy.fault(error)
        }
    }

    func peelLastHop(tagID: UUID?) async {
        guard !isCommitting else { return }
        isCommitting = true
        defer { isCommitting = false }
        do {
            crib = try await store.peelLastHop(tagID: tagID)
            fault = nil
            commitTick += 1
        } catch {
            fault = CribCopy.fault(error)
        }
    }

    func relinquish(tagID: UUID) async {
        guard !isCommitting else { return }
        isCommitting = true
        defer { isCommitting = false }
        do {
            crib = try await store.relinquish(tagID: tagID)
            fault = nil
        } catch {
            fault = CribCopy.fault(error)
        }
    }

    func addStall() async {
        guard !isCommitting else { return }
        isCommitting = true
        defer { isCommitting = false }
        do {
            crib = try await store.addStall(name: stallDraft, duty: stallDuty)
            stallDraft = ""
            stallDuty = .inStock
            fault = nil
        } catch {
            fault = CribCopy.fault(error)
        }
    }

    func renameOpenStall() async {
        guard let renameStallID else { return }
        guard !isCommitting else { return }
        isCommitting = true
        defer { isCommitting = false }
        do {
            crib = try await store.renameStall(renameStallID, name: renameDraft)
            self.renameStallID = nil
            renameDraft = ""
            fault = nil
        } catch {
            fault = CribCopy.fault(error)
        }
    }

    func finishOnboarding() async {
        await ensureDefaultStalls()
        crib = await store.setOnboardingComplete(true)
        await flush()
        applyHook()
    }

    func reopenOnboarding() async {
        crib = await store.setOnboardingComplete(false)
        segment = .inventory
        cover = nil
        await flush()
    }

    func resetAll() async {
        isCommitting = true
        do {
            try await store.resetAllData()
            crib = await store.snapshot()
            warning = nil
            fault = nil
            notice = nil
            query = ""
            statusFilter = nil
            assignedDraft = ""
            segment = .inventory
            cover = nil
            hookConsumed = false
        } catch {
            fault = "The crib could not be cleared."
        }
        isCommitting = false
    }

    func openMark(_ kind: CribMarkKind) {
        markKind = kind
        cover = .mark
    }

    func openCapture() {
        cover = .capture
    }

    func openHopTrail() {
        cover = .hopTrail
    }

    func jumpInventory() {
        segment = .inventory
        cover = nil
    }

    func focus(_ tagID: UUID) {
        crib.focusedTagID = tagID
    }

    func applyHook(arguments: [String] = ProcessInfo.processInfo.arguments) {
        guard let pane = CribLaunch.consume(
            arguments: arguments,
            onboardingComplete: crib.onboardingComplete,
            consumed: &hookConsumed
        ) else { return }
        segment = pane.segment
        cover = nil
    }

    func stallName(_ id: UUID) -> String {
        crib.stall(id: id)?.name ?? "Unknown stall"
    }

    func tagName(_ id: UUID) -> String {
        guard let tag = crib.tag(id: id) else { return "Unknown Tag" }
        if tag.needsName {
            return tag.code ?? "Unnamed Tag"
        }
        return tag.name
    }

    func hops(for tagID: UUID) -> [Hop] {
        crib.hops(for: tagID)
    }

    func markPayload(_ kind: CribMarkKind) -> String {
        switch kind {
        case .tag(let id):
            crib.tag(id: id)?.qrPayload ?? id.uuidString
        case .stall(let id):
            crib.stall(id: id)?.qrPayload ?? id.uuidString
        }
    }

    func markTitle(_ kind: CribMarkKind) -> String {
        switch kind {
        case .tag(let id):
            tagName(id)
        case .stall(let id):
            stallName(id)
        }
    }

    private func hopNotice() -> String {
        guard let tag = crib.focusedTag else {
            return "Hop written."
        }
        let who = tag.assignedTo ?? openStall?.name ?? "this stall"
        return "\(tagName(tag.id)) hopped to \(openStall?.name ?? "this stall"), with \(who)."
    }

    private func applyWarning() {
        switch warning {
        case .recoveredFromBackup:
            notice = "Restored from a backup copy."
        case .startedEmpty:
            fault = "The crib could not be read."
            notice = nil
        case nil:
            break
        }
    }

    private func ensureDefaultStalls() async {
        if crib.stalls.isEmpty {
            do {
                crib = try await store.addStall(name: "Bench", duty: .inStock)
                crib = try await store.addStall(name: "Crew hold", duty: .lent)
                crib = try await store.addStall(name: "Repair pane", duty: .repair)
            } catch {
                fault = CribCopy.fault(error)
            }
        }
    }
}

enum CribLoad: Equatable, Sendable {
    case empty
    case populated
    case fault
}

enum CribCover: String, Identifiable, Equatable, Sendable {
    case capture
    case fuse
    case mark
    case hopTrail

    var id: String { rawValue }
}

enum CribMarkKind: Equatable, Sendable, Identifiable {
    case tag(UUID)
    case stall(UUID)

    var id: String {
        switch self {
        case .tag(let id): "tag-\(id.uuidString)"
        case .stall(let id): "stall-\(id.uuidString)"
        }
    }
}
