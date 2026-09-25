import XCTest
@testable import Stallage

final class FamilyInvariantTests: XCTestCase {
    private var calendar = Calendar(identifier: .gregorian)
    private var now = Date(timeIntervalSince1970: 0)

    override func setUpWithError() throws {
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        utc.locale = Locale(identifier: "en_US_POSIX")
        calendar = utc
        now = instant(2026, 9, 17)
    }

    func test_familyInvariant_scanCreatesInStock_hopWritesIssuedAssignedTo_overdueAfter30Days_qrIsCodeOrId() throws {
        let bench = UUID(uuidString: "11111111-0001-4000-8000-000000000001")!
        let crew = UUID(uuidString: "11111111-0001-4000-8000-000000000002")!
        var crib = Crib.empty
        crib = try crib.addingStall(name: "Bench", duty: .inStock, id: bench)
        crib = try crib.addingStall(name: "Crew hold", duty: .lent, id: crew)
        crib = try crib.opening(bench)

        let twelve = "036000291452"
        var outcome: SeatHop
        (crib, outcome) = try crib.seating(twelve, now: now, calendar: calendar)
        guard case .seated(let tagID) = outcome else {
            return XCTFail("scan of an unknown mark must seat a draft")
        }
        let drafted = try XCTUnwrap(crib.tag(id: tagID))
        XCTAssertEqual(drafted.status, .inStock, "scan finds or creates draft inStock")
        XCTAssertTrue(drafted.needsName)
        XCTAssertEqual(crib.seats.count, 1)
        XCTAssertEqual(crib.seat(for: tagID)?.stallID, bench)
        XCTAssertEqual(drafted.code, "0036000291452")
        XCTAssertEqual(drafted.qrPayload, drafted.code, "QR is code when present")

        (crib, outcome) = try crib.seating(twelve, now: now, calendar: calendar)
        guard case .focused(let focusedID) = outcome else {
            return XCTFail("a second scan in the same stall must focus, not duplicate")
        }
        XCTAssertEqual(focusedID, tagID)
        XCTAssertEqual(crib.tags.count, 1)

        crib = try crib.opening(crew)
        let issuedOn = calendar.date(byAdding: .day, value: -31, to: now) ?? now
        (crib, outcome) = try crib.seating(twelve, now: issuedOn, calendar: calendar, assignedTo: "Maya")
        guard case .hopped(let hoppedID, let hopID) = outcome else {
            return XCTFail("a known scan onto a different stall must hop")
        }
        XCTAssertEqual(hoppedID, tagID)
        let moved = try XCTUnwrap(crib.tag(id: tagID))
        XCTAssertEqual(moved.status, .issued)
        XCTAssertEqual(moved.assignedTo, "Maya")
        XCTAssertEqual(moved.stallID, crew)
        XCTAssertEqual(crib.hops.count, 1)
        XCTAssertEqual(crib.hops.first?.id, hopID)
        XCTAssertEqual(crib.trailMarks.count, 1)
        XCTAssertEqual(crib.trailMarks.first?.hopID, hopID)
        XCTAssertEqual(crib.seat(for: tagID)?.stallID, crew)

        XCTAssertFalse(moved.isOverdue(now: calendar.date(byAdding: .day, value: 30, to: issuedOn) ?? now, calendar: calendar))
        XCTAssertTrue(moved.isOverdue(now: now, calendar: calendar), "issued > 30 local days ranks overdue")
        XCTAssertEqual(crib.overdueTags(now: now, calendar: calendar).map(\.id), [tagID])

        let nameless = Tag(
            id: UUID(uuidString: "22222222-0001-4000-8000-000000000099")!,
            name: "",
            code: nil,
            stallID: bench,
            status: .inStock,
            assignedTo: nil,
            seatedDayKey: CribDay.from(now, calendar: calendar).rawValue,
            issuedDayKey: nil
        )
        XCTAssertEqual(nameless.qrPayload, nameless.id.uuidString, "QR is id when code is missing")
    }

    func test_familyInvariant_seedLeavesScanEnabledAndFillsTheCrib() throws {
        let crib = try CribSeed.crib(now: now, calendar: calendar)
        XCTAssertTrue(crib.onboardingComplete)
        XCTAssertTrue(crib.canSeatTag)
        XCTAssertGreaterThanOrEqual(crib.stalls.count, 4)
        XCTAssertGreaterThanOrEqual(crib.tags.count, 6)
        XCTAssertFalse(crib.hops.isEmpty)
        XCTAssertFalse(crib.trailMarks.isEmpty)
        XCTAssertFalse(crib.overdueTags(now: now, calendar: calendar).isEmpty)
        XCTAssertEqual(crib.openStall?.name, "Bench")
        XCTAssertGreaterThanOrEqual(crib.tags(in: try XCTUnwrap(crib.openStallID)).count, 3)
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
