import XCTest
@testable import Stallage

final class SeatHopTests: XCTestCase {
    private var calendar = Calendar(identifier: .gregorian)
    private var now = Date(timeIntervalSince1970: 0)

    override func setUpWithError() throws {
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        utc.locale = Locale(identifier: "en_US_POSIX")
        calendar = utc
        now = instant(2026, 9, 17)
    }

    func test_primaryVerb_emptyThrows_populatedSeats_invalidHasNoOpenStall() throws {
        var crib = Crib.empty
        XCTAssertFalse(crib.canSeatTag)
        XCTAssertThrowsError(try crib.seating("036000291452", now: now, calendar: calendar)) { error in
            XCTAssertEqual(error as? CribFault, .noOpenStall)
        }
        XCTAssertThrowsError(try crib.seating("   ", now: now, calendar: calendar)) { error in
            XCTAssertEqual(error as? CribFault, .emptyMark)
        }

        crib = try crib.addingStall(name: "Bench", duty: .inStock)
        XCTAssertTrue(crib.canSeatTag)
        XCTAssertThrowsError(try crib.seating("", now: now, calendar: calendar)) { error in
            XCTAssertEqual(error as? CribFault, .emptyMark)
        }

        let (seatedCrib, outcome) = try crib.seating("4006381333931", now: now, calendar: calendar)
        guard case .seated(let tagID) = outcome else {
            return XCTFail("populated mark must seat")
        }
        XCTAssertEqual(seatedCrib.tags.count, 1)
        XCTAssertEqual(seatedCrib.seats.count, 1)
        XCTAssertEqual(seatedCrib.tag(id: tagID)?.status, .inStock)
        XCTAssertEqual(seatedCrib.tag(id: tagID)?.code, "4006381333931")
    }

    func test_architecture_newScanWritesTagAndSeat_knownScanWritesHopTrailAndAssignedTo_dutyCopies_relinquishedFreezes() throws {
        let bench = UUID(uuidString: "33333333-0001-4000-8000-000000000001")!
        let repair = UUID(uuidString: "33333333-0001-4000-8000-000000000002")!
        var crib = try Crib.empty
            .addingStall(name: "Bench", duty: .inStock, id: bench)
            .addingStall(name: "Repair pane", duty: .repair, id: repair)
        crib = try crib.opening(bench)

        var outcome: SeatHop
        (crib, outcome) = try crib.seating("12345670", now: now, calendar: calendar)
        guard case .seated(let tagID) = outcome else {
            return XCTFail("expected seated")
        }
        XCTAssertEqual(crib.tags.count, 1)
        XCTAssertEqual(crib.seats.count, 1)
        XCTAssertEqual(crib.seat(for: tagID)?.tagID, tagID)
        XCTAssertEqual(CribDay.from(now, calendar: calendar).rawValue, 20260917)

        crib = try crib.opening(repair)
        (crib, outcome) = try crib.seating("12345670", now: now, calendar: calendar, assignedTo: "Kit")
        guard case .hopped = outcome else {
            return XCTFail("expected hop")
        }
        let moved = try XCTUnwrap(crib.tag(id: tagID))
        XCTAssertEqual(moved.status, .repair, "Duty copies onto status")
        XCTAssertEqual(moved.assignedTo, "Kit")
        XCTAssertEqual(crib.hops.count, 1)
        XCTAssertEqual(crib.trailMarks.count, 1)
        XCTAssertEqual(crib.hops.first?.fromStallID, bench)
        XCTAssertEqual(crib.hops.first?.toStallID, repair)

        crib = try crib.relinquishing(tagID)
        XCTAssertEqual(crib.tag(id: tagID)?.status, .relinquished)
        crib = try crib.opening(bench)
        (crib, outcome) = try crib.seating("12345670", now: now, calendar: calendar)
        guard case .frozen(let frozenID) = outcome else {
            return XCTFail("relinquished freezes hops")
        }
        XCTAssertEqual(frozenID, tagID)
        XCTAssertEqual(crib.tag(id: tagID)?.stallID, repair)
        XCTAssertEqual(crib.hops.count, 1, "frozen scan must not write another hop")

        (crib, outcome) = try crib.seating("5901234123457", now: now, calendar: calendar)
        guard case .seated = outcome else {
            return XCTFail("new scans still seat other tags")
        }
        XCTAssertEqual(crib.tags.count, 2)
    }

    func test_twist_stallThenHop_undoPeelsHopThenTag() throws {
        let bench = UUID(uuidString: "44444444-0001-4000-8000-000000000001")!
        let crew = UUID(uuidString: "44444444-0001-4000-8000-000000000002")!
        var crib = try Crib.empty
            .addingStall(name: "Bench", duty: .inStock, id: bench)
            .addingStall(name: "Crew hold", duty: .lent, id: crew)

        (crib, _) = try crib.seating(
            crew.uuidString,
            now: now,
            calendar: calendar
        )
        XCTAssertEqual(crib.openStallID, crew)
        XCTAssertTrue(crib.tags.isEmpty, "a stall mark opens the stall and does not write a tag")

        crib = try crib.opening(bench)
        var outcome: SeatHop
        (crib, outcome) = try crib.seating("500015941125", now: now, calendar: calendar)
        guard case .seated(let tagID) = outcome else {
            return XCTFail("expected seated")
        }
        crib = try crib.fusingName(tagID, "Tape brick")
        crib = try crib.opening(crew)
        (crib, outcome) = try crib.seating("500015941125", now: now, calendar: calendar, assignedTo: "Rae")
        guard case .hopped = outcome else {
            return XCTFail("known scan onto another stall hops")
        }
        XCTAssertEqual(crib.tag(id: tagID)?.status, .issued)
        XCTAssertEqual(crib.tag(id: tagID)?.assignedTo, "Rae")

        crib = try crib.peelLastHop(tagID: tagID)
        XCTAssertTrue(crib.hops.isEmpty)
        XCTAssertTrue(crib.trailMarks.isEmpty)
        XCTAssertEqual(crib.tag(id: tagID)?.stallID, bench)
        XCTAssertEqual(crib.tag(id: tagID)?.status, .inStock)
        XCTAssertNil(crib.tag(id: tagID)?.assignedTo)

        crib = try crib.peelLastHop(tagID: tagID)
        XCTAssertNil(crib.tag(id: tagID))
        XCTAssertTrue(crib.seats.isEmpty)
        XCTAssertTrue(crib.tags.isEmpty)
    }

    func test_seekingFiltersNameAndCodeInMemory() throws {
        let crib = try CribSeed.crib(now: now, calendar: calendar)
        XCTAssertGreaterThanOrEqual(crib.seeking("").count, 3)
        XCTAssertEqual(crib.seeking("xlr").map(\.name), ["XLR loom"])
        XCTAssertFalse(crib.seeking("4006381333931").isEmpty)
        XCTAssertTrue(crib.seeking("no-such-mark").isEmpty)
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
