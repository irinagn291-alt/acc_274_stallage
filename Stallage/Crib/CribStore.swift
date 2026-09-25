import Foundation

/// Role: Crib. The only persistence seam. Views observe the crib; they never touch UserDefaults or files.
protocol CribStoring: Sendable {
    func load() async -> (crib: Crib, warning: CribWarning?)
    func snapshot() async -> Crib
    func seatTag(_ raw: String, now: Date, calendar: Calendar, assignedTo: String?) async throws -> SeatHop
    func fuseName(tagID: UUID, name: String) async throws -> Crib
    func openStall(_ stallID: UUID) async throws -> Crib
    func peelLastHop(tagID: UUID?) async throws -> Crib
    func relinquish(tagID: UUID) async throws -> Crib
    func addStall(name: String, duty: StallDuty) async throws -> Crib
    func renameStall(_ stallID: UUID, name: String) async throws -> Crib
    func setOnboardingComplete(_ flag: Bool) async -> Crib
    func flush() async throws
    func resetAllData() async throws
    func seedDemoIfNeeded(now: Date, calendar: Calendar) async throws -> Crib?
}

/// Role: Crib. Memory is the source of truth. UserDefaults slg.crib.v1 plus an Application Support file are projections.
actor CribStore: CribStoring {
    private let directory: URL
    private let defaultsSuiteName: String?
    private let fileManager: FileManager
    private let writeDelayNanoseconds: UInt64

    private var latest: Crib = .empty
    private var dirty = false
    private var writeTask: Task<Void, Never>?
    private(set) var warning: CribWarning?
    private(set) var lastWriteError: String?

    init(
        directory: URL,
        defaultsSuiteName: String? = nil,
        fileManager: FileManager = .default,
        writeDelayNanoseconds: UInt64 = 300_000_000
    ) {
        self.directory = directory
        self.defaultsSuiteName = defaultsSuiteName
        self.fileManager = fileManager
        self.writeDelayNanoseconds = writeDelayNanoseconds
    }

    static func applicationSupportDirectory(fileManager: FileManager = .default) throws -> URL {
        let root = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return root.appendingPathComponent("Stallage", isDirectory: true)
    }

    func load() async -> (crib: Crib, warning: CribWarning?) {
        warning = nil
        latest = .empty
        dirty = false
        let defaults = preferenceDefaults()
        if let crib = decode(defaults.data(forKey: CribKey.snapshot)) {
            latest = crib
            return (latest, nil)
        }
        if let crib = decodeFile(fileURL) {
            latest = crib
            return (latest, nil)
        }
        if let crib = decode(defaults.data(forKey: CribKey.backup)) {
            latest = crib
            warning = .recoveredFromBackup
            return (latest, warning)
        }
        if let crib = decodeFile(backupURL) {
            latest = crib
            warning = .recoveredFromBackup
            return (latest, warning)
        }
        let hadPayload = defaults.data(forKey: CribKey.snapshot) != nil
            || fileManager.fileExists(atPath: fileURL.path)
        if hadPayload {
            warning = .startedEmpty
        }
        return (latest, warning)
    }

    func snapshot() async -> Crib {
        latest
    }

    func seatTag(
        _ raw: String,
        now: Date = Date(),
        calendar: Calendar = .current,
        assignedTo: String? = nil
    ) async throws -> SeatHop {
        try Task.checkCancellation()
        let (next, outcome) = try latest.seating(raw, now: now, calendar: calendar, assignedTo: assignedTo)
        latest = next
        switch outcome {
        case .seated, .hopped:
            try persistCommitted()
        case .focused, .frozen, .openedStall:
            dirty = true
            scheduleFlush()
        }
        return outcome
    }

    func fuseName(tagID: UUID, name: String) async throws -> Crib {
        try Task.checkCancellation()
        latest = try latest.fusingName(tagID, name)
        dirty = true
        scheduleFlush()
        return latest
    }

    func openStall(_ stallID: UUID) async throws -> Crib {
        try Task.checkCancellation()
        latest = try latest.opening(stallID)
        try persistCommitted()
        return latest
    }

    func peelLastHop(tagID: UUID? = nil) async throws -> Crib {
        try Task.checkCancellation()
        latest = try latest.peelLastHop(tagID: tagID)
        try persistCommitted()
        return latest
    }

    func relinquish(tagID: UUID) async throws -> Crib {
        try Task.checkCancellation()
        latest = try latest.relinquishing(tagID)
        try persistCommitted()
        return latest
    }

    func addStall(name: String, duty: StallDuty) async throws -> Crib {
        try Task.checkCancellation()
        latest = try latest.addingStall(name: name, duty: duty)
        try persistCommitted()
        return latest
    }

    func renameStall(_ stallID: UUID, name: String) async throws -> Crib {
        try Task.checkCancellation()
        latest = try latest.renamingStall(stallID, name: name)
        dirty = true
        scheduleFlush()
        return latest
    }

    func setOnboardingComplete(_ flag: Bool) async -> Crib {
        if flag {
            latest = latest.completingOnboarding()
        } else {
            latest.onboardingComplete = false
        }
        dirty = true
        scheduleFlush()
        return latest
    }

    func flush() async throws {
        writeTask?.cancel()
        writeTask = nil
        if dirty {
            try persistCommitted()
        }
    }

    func resetAllData() async throws {
        writeTask?.cancel()
        writeTask = nil
        latest = .empty
        dirty = false
        warning = nil
        lastWriteError = nil
        let defaults = preferenceDefaults()
        defaults.removeObject(forKey: CribKey.snapshot)
        defaults.removeObject(forKey: CribKey.backup)
        if fileManager.fileExists(atPath: directory.path) {
            try fileManager.removeItem(at: directory)
        }
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    func seedDemoIfNeeded(now: Date = Date(), calendar: Calendar = .current) async throws -> Crib? {
        #if targetEnvironment(simulator)
        let defaults = preferenceDefaults()
        guard defaults.object(forKey: CribKey.demo) == nil else { return nil }
        latest = try CribSeed.crib(now: now, calendar: calendar)
        try persistCommitted()
        defaults.set(true, forKey: CribKey.demo)
        return latest
        #else
        _ = now
        _ = calendar
        return nil
        #endif
    }

    /// File IO stays on this actor, which is not MainActor. The main thread never waits on disk.
    private func persistCommitted() throws {
        let document = CribCodec.committed(from: latest)
        let data = try CribCodec.encode(document)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let defaults = preferenceDefaults()
        if fileManager.fileExists(atPath: fileURL.path) {
            if fileManager.fileExists(atPath: backupURL.path) {
                try? fileManager.removeItem(at: backupURL)
            }
            try? fileManager.copyItem(at: fileURL, to: backupURL)
        }
        try data.write(to: fileURL, options: .atomic)
        if let previous = defaults.data(forKey: CribKey.snapshot) {
            defaults.set(previous, forKey: CribKey.backup)
        }
        defaults.set(data, forKey: CribKey.snapshot)
        dirty = false
        lastWriteError = nil
    }

    private func scheduleFlush() {
        writeTask?.cancel()
        let delay = writeDelayNanoseconds
        writeTask = Task { [weak self] in
            if delay > 0 {
                try? await Task.sleep(nanoseconds: delay)
            }
            guard !Task.isCancelled else { return }
            await self?.flushIfNeeded()
        }
    }

    private func flushIfNeeded() async {
        writeTask = nil
        do {
            if dirty {
                try persistCommitted()
            }
        } catch {
            lastWriteError = String(describing: error)
        }
    }

    private func decode(_ data: Data?) -> Crib? {
        guard let data, let document = try? CribCodec.decode(data) else { return nil }
        return document.crib
    }

    private func decodeFile(_ url: URL) -> Crib? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return decode(data)
    }

    private var fileURL: URL {
        directory.appendingPathComponent("crib.json")
    }

    private var backupURL: URL {
        directory.appendingPathComponent("crib.json.backup")
    }

    private func preferenceDefaults() -> UserDefaults {
        if let defaultsSuiteName {
            return UserDefaults(suiteName: defaultsSuiteName) ?? .standard
        }
        return .standard
    }
}
