import XCTest
@testable import Stallage

final class CribWatchTests: XCTestCase {
    private var calendar: Calendar {
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        utc.locale = Locale(identifier: "en_US_POSIX")
        return utc
    }

    private var now: Date {
        instant(2026, 9, 17)
    }

    @MainActor
    func test_reviewScreenOpensThreeDifferentSegmentsAfterOnboarding() async throws {
        let crib = try CribSeed.crib(now: now, calendar: calendar)
        XCTAssertTrue(crib.onboardingComplete)

        let today = makeWatch(crib)
        await today.appear(arguments: ["-ReviewScreen", "today"])
        XCTAssertEqual(today.segment, .inventory)

        let log = makeWatch(crib)
        await log.appear(arguments: ["-ReviewScreen", "log"])
        XCTAssertEqual(log.segment, .lifecycle)

        let goals = makeWatch(crib)
        await goals.appear(arguments: ["-ReviewScreen", "goals"])
        XCTAssertEqual(goals.segment, .settings)

        XCTAssertNotEqual(today.segment, log.segment)
        XCTAssertNotEqual(log.segment, goals.segment)
        XCTAssertNotEqual(today.segment, goals.segment)
    }

    @MainActor
    func test_hookIgnoredUntilOnboardingCompletesThenReadsOnce() async {
        var crib = Crib.empty
        let watch = makeWatch(crib)
        await watch.appear(arguments: ["-ReviewScreen", "log"])
        XCTAssertTrue(watch.showsOnboarding)
        XCTAssertEqual(watch.segment, .inventory)

        await watch.finishOnboarding()
        XCTAssertFalse(watch.showsOnboarding)
        XCTAssertFalse(watch.crib.stalls.isEmpty)

        crib = watch.crib
        let second = makeWatch(crib)
        await second.appear(arguments: ["-ReviewScreen", "log"])
        XCTAssertEqual(second.segment, .lifecycle)
        await second.appear(arguments: ["-ReviewScreen", "goals"])
        XCTAssertEqual(second.segment, .lifecycle, "hook consumes once")
    }

    @MainActor
    func test_inventoryLoadEmptyPopulatedFaultAndScanEnabledOnSeed() async throws {
        let emptyWatch = CribWatch.previewEmpty()
        await emptyWatch.appear()
        XCTAssertEqual(emptyWatch.inventoryLoad, .empty)
        XCTAssertEqual(emptyWatch.lifecycleLoad, .empty)
        XCTAssertEqual(emptyWatch.settingsLoad, .empty)
        XCTAssertFalse(emptyWatch.canSeatTag)

        let seeded = try CribSeed.crib(now: now, calendar: calendar)
        let populated = makeWatch(seeded)
        await populated.appear()
        XCTAssertEqual(populated.inventoryLoad, .populated)
        XCTAssertEqual(populated.lifecycleLoad, .populated)
        XCTAssertEqual(populated.settingsLoad, .populated)
        XCTAssertTrue(populated.canSeatTag)
        XCTAssertTrue(populated.crib.onboardingComplete)
        XCTAssertTrue(populated.jobLine.contains("Scan"))
        XCTAssertTrue(populated.jobLine.contains("Hop a known Tag"))
        XCTAssertTrue(populated.jobTitle.isEmpty == false)
        XCTAssertEqual(populated.hopCountLabel, CribFigures.integer(seeded.hops.count))

        let broken = makeWatch(.empty, warning: .startedEmpty)
        await broken.appear()
        XCTAssertEqual(broken.inventoryLoad, .fault)
        XCTAssertEqual(broken.lifecycleLoad, .fault)
        XCTAssertEqual(broken.settingsLoad, .fault)
    }

    @MainActor
    func test_seatUnknownWritesTagAndOpensFuseCover() async throws {
        var crib = Crib.empty.completingOnboarding()
        crib = try crib.addingStall(name: "Bench", duty: .inStock)
        let watch = makeWatch(crib)
        await watch.appear()
        watch.cover = .capture
        await watch.seat("12345670")
        XCTAssertEqual(watch.cover, .fuse)
        XCTAssertEqual(watch.crib.tags.count, 1)
        XCTAssertEqual(watch.crib.tags.first?.status, .inStock)
        XCTAssertEqual(watch.crib.seats.count, 1)
        XCTAssertTrue(watch.canSeatTag)

        watch.fuseDraft = "XLR loom"
        await watch.fuseName()
        XCTAssertNil(watch.cover)
        XCTAssertEqual(watch.crib.tags.first?.name, "XLR loom")
    }

    func test_craftRadiiAndContactStayOnContract() {
        XCTAssertEqual(CribCraft.cardRadius, 20)
        XCTAssertEqual(CribCraft.chipRadius, 12)
        XCTAssertEqual(CribCraft.unit, 8)
        XCTAssertEqual(CribCraft.tap, 44)
        XCTAssertEqual(CribCraft.liftRadius, 16)
        XCTAssertEqual(CribCraft.liftY, 8)
        XCTAssertEqual(CribClient.contactURL.absoluteString, "https://stallage-crib.pro/contact-us")
        XCTAssertEqual(CribCopy.status(.issued), "Issued")
        XCTAssertEqual(CribCopy.duty(.lent), "Lent")
        XCTAssertEqual(CribFigures.integer(31), NumberFormatter.localizedString(from: 31, number: .decimal))
        let forty = calendar.date(byAdding: .day, value: -40, to: now) ?? now
        let key = CribDay.from(forty, calendar: calendar).rawValue
        XCTAssertEqual(CribFigures.issuedDays(issuedDayKey: key, now: now, calendar: calendar), 40)
        let span = CribFigures.issuedSpan(issuedDayKey: key, now: now, calendar: calendar)
        XCTAssertTrue(span.contains("40"))
        XCTAssertTrue(span.contains("days overdue"))
    }

    @MainActor
    private func makeWatch(_ crib: Crib, warning: CribWarning? = nil) -> CribWatch {
        let frozen = now
        let cal = calendar
        return CribWatch(
            store: CribHold(crib: crib, warning: warning),
            crib: crib,
            warning: warning,
            calendar: cal,
            now: frozen,
            clock: { frozen },
            shouldLoad: false,
            permitSeed: false
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
