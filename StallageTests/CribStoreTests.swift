import XCTest
@testable import Stallage

final class CribStoreTests: XCTestCase {
    private var directory = FileManager.default.temporaryDirectory
    private var suiteName = ""
    private var defaults = UserDefaults.standard
    private var calendar = Calendar(identifier: .gregorian)
    private var now = Date(timeIntervalSince1970: 0)

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        suiteName = "slg.test.\(UUID().uuidString)"
        defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        utc.locale = Locale(identifier: "en_US_POSIX")
        calendar = utc
        now = instant(2026, 9, 17)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
        if !suiteName.isEmpty {
            defaults.removePersistentDomain(forName: suiteName)
        }
    }

    func test_roundTrip_reloadPreservesSeatHopTrailAndIssued() async throws {
        let store = makeStore()
        _ = await store.load()
        _ = await store.setOnboardingComplete(true)
        try await store.flush()
        _ = try await store.addStall(name: "Bench", duty: .inStock)
        _ = try await store.addStall(name: "Crew hold", duty: .lent)
        let crib = await store.snapshot()
        let crewID = try XCTUnwrap(crib.stalls.first(where: { $0.duty == .lent })?.id)

        let seated = try await store.seatTag("036000291452", now: now, calendar: calendar, assignedTo: nil)
        guard case .seated(let tagID) = seated else {
            return XCTFail("expected seated")
        }
        _ = try await store.fuseName(tagID: tagID, name: "XLR loom")
        try await store.flush()
        _ = try await store.openStall(crewID)
        let hopped = try await store.seatTag("036000291452", now: now, calendar: calendar, assignedTo: "Maya")
        guard case .hopped = hopped else {
            return XCTFail("expected hop")
        }

        let relaunched = makeStore()
        let loaded = await relaunched.load()
        XCTAssertNil(loaded.warning)
        XCTAssertTrue(loaded.crib.onboardingComplete)
        XCTAssertEqual(loaded.crib.tags.first?.name, "XLR loom")
        XCTAssertEqual(loaded.crib.tags.first?.status, .issued)
        XCTAssertEqual(loaded.crib.tags.first?.assignedTo, "Maya")
        XCTAssertEqual(loaded.crib.hops.count, 1)
        XCTAssertEqual(loaded.crib.trailMarks.count, 1)
        XCTAssertEqual(loaded.crib.seats.count, 1)
        XCTAssertNotNil(defaults.data(forKey: CribKey.snapshot))
        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.appendingPathComponent("crib.json").path))
    }

    func test_corruptSnapshotFallsBackToBackup() async throws {
        let store = makeStore()
        _ = await store.load()
        _ = try await store.addStall(name: "Bench", duty: .inStock)
        _ = try await store.seatTag("12345670", now: now, calendar: calendar, assignedTo: nil)
        try await store.flush()
        if let good = defaults.data(forKey: CribKey.snapshot) {
            defaults.set(good, forKey: CribKey.backup)
        }
        let file = directory.appendingPathComponent("crib.json")
        let backup = directory.appendingPathComponent("crib.json.backup")
        if FileManager.default.fileExists(atPath: file.path) {
            try? FileManager.default.removeItem(at: backup)
            try FileManager.default.copyItem(at: file, to: backup)
        }
        defaults.set(Data("{not-json".utf8), forKey: CribKey.snapshot)
        try Data("{not-json".utf8).write(to: file)

        let loaded = await makeStore().load()
        XCTAssertEqual(loaded.warning, .recoveredFromBackup)
        XCTAssertEqual(loaded.crib.tags.first?.code, "12345670")
        XCTAssertEqual(loaded.crib.stalls.first?.name, "Bench")
    }

    func test_corruptSnapshotWithoutBackupStartsEmpty() async throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defaults.set(Data("nope".utf8), forKey: CribKey.snapshot)
        try Data("nope".utf8).write(to: directory.appendingPathComponent("crib.json"))
        let loaded = await makeStore().load()
        XCTAssertEqual(loaded.warning, .startedEmpty)
        XCTAssertTrue(loaded.crib.tags.isEmpty)
        XCTAssertFalse(loaded.crib.onboardingComplete)
    }

    func test_codecSwitchesOnSchemaVersion() throws {
        let crib = try CribSeed.crib(now: now, calendar: calendar)
        let document = CribCodec.committed(from: crib)
        let data = try CribCodec.encode(document)
        let decoded = try CribCodec.decode(data)
        XCTAssertEqual(decoded.schemaVersion, 1)
        XCTAssertEqual(decoded.crib.stalls.count, crib.stalls.count)
        XCTAssertEqual(decoded.crib.tags.count, crib.tags.count)
        XCTAssertEqual(decoded.crib.hops.count, crib.hops.count)
        XCTAssertEqual(decoded.crib.trailMarks.count, crib.trailMarks.count)
        XCTAssertEqual(decoded.crib.openStall?.name, crib.openStall?.name)

        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(object["schemaVersion"] as? Int, 1)
        XCTAssertNil(object["overdue"])
        XCTAssertNotNil(object["stalls"])
        XCTAssertNotNil(object["tags"])
        XCTAssertNotNil(object["hops"])
        XCTAssertNotNil(object["trailMarks"])

        let future = Data("{\"schemaVersion\":99}".utf8)
        XCTAssertThrowsError(try CribCodec.decode(future)) { error in
            XCTAssertEqual(error as? CribCodec.Failure, .unsupportedSchema(99))
        }
        XCTAssertThrowsError(try CribCodec.decode(Data("[]".utf8))) { error in
            XCTAssertEqual(error as? CribCodec.Failure, .corrupt)
        }
    }

    func test_resetAllDataClearsSnapshotAndFiles() async throws {
        let store = makeStore()
        _ = await store.load()
        _ = try await store.addStall(name: "Bench", duty: .inStock)
        try await store.resetAllData()
        let loaded = await store.load()
        XCTAssertTrue(loaded.crib.stalls.isEmpty)
        XCTAssertFalse(loaded.crib.onboardingComplete)
        XCTAssertNil(defaults.data(forKey: CribKey.snapshot))
        XCTAssertNil(defaults.data(forKey: CribKey.backup))
        let leftovers = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        XCTAssertTrue(leftovers.filter { $0.pathExtension == "json" }.isEmpty)
    }

    func test_onboardingFlagDebouncesUntilFlush() async throws {
        let store = makeStore()
        _ = await store.load()
        _ = await store.setOnboardingComplete(true)
        try await store.flush()
        let loaded = await makeStore().load()
        XCTAssertTrue(loaded.crib.onboardingComplete)
    }

    func test_relinquishAndPeelPersistOnTheSeam() async throws {
        let store = makeStore()
        _ = await store.load()
        _ = try await store.addStall(name: "Bench", duty: .inStock)
        _ = try await store.addStall(name: "Crew hold", duty: .lent)
        let seated = try await store.seatTag("4006381333931", now: now, calendar: calendar, assignedTo: nil)
        guard case .seated(let tagID) = seated else {
            return XCTFail("expected seated")
        }
        let snapshot = await store.snapshot()
        let crewID = try XCTUnwrap(snapshot.stalls.first(where: { $0.duty == .lent })?.id)
        _ = try await store.openStall(crewID)
        _ = try await store.seatTag("4006381333931", now: now, calendar: calendar, assignedTo: "Nia")
        _ = try await store.peelLastHop(tagID: tagID)
        var loaded = await makeStore().load()
        XCTAssertEqual(loaded.crib.tag(id: tagID)?.stallID, loaded.crib.stalls.first?.id)
        XCTAssertTrue(loaded.crib.hops.isEmpty)

        _ = try await store.relinquish(tagID: tagID)
        loaded = await makeStore().load()
        XCTAssertEqual(loaded.crib.tag(id: tagID)?.status, .relinquished)
    }

    #if targetEnvironment(simulator)
    func test_simulatorSeedWritesOnceAndEnablesScan() async throws {
        let store = makeStore()
        let first = try await store.seedDemoIfNeeded(now: now, calendar: calendar)
        let second = try await store.seedDemoIfNeeded(now: now, calendar: calendar)
        XCTAssertNil(second)
        XCTAssertEqual(first?.onboardingComplete, true)
        XCTAssertEqual(first?.canSeatTag, true)
        XCTAssertGreaterThanOrEqual(first?.stalls.count ?? 0, 4)
        XCTAssertGreaterThanOrEqual(first?.tags.count ?? 0, 6)
        XCTAssertGreaterThan(first?.hops.count ?? 0, 0)
        XCTAssertTrue(defaults.bool(forKey: CribKey.demo))
        XCTAssertNotNil(defaults.data(forKey: CribKey.snapshot))
        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.appendingPathComponent("crib.json").path))
    }
    #endif

    private func makeStore() -> CribStore {
        CribStore(
            directory: directory,
            defaultsSuiteName: suiteName,
            writeDelayNanoseconds: 0
        )
    }

    private func instant(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var parts = DateComponents()
        parts.year = year
        parts.month = month
        parts.day = day
        parts.hour = 12
        return calendar.date(from: parts) ?? Date(timeIntervalSince1970: 0)
    }
}
