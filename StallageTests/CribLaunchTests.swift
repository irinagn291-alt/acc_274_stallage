import XCTest
@testable import Stallage

final class CribLaunchTests: XCTestCase {
    func test_readsOnceAfterOnboarding() {
        var consumed = false
        XCTAssertNil(
            CribLaunch.consume(
                arguments: ["-ReviewScreen", "log"],
                onboardingComplete: false,
                consumed: &consumed
            )
        )
        XCTAssertFalse(consumed)

        let first = CribLaunch.consume(
            arguments: ["app", "-ReviewScreen", "log"],
            onboardingComplete: true,
            consumed: &consumed
        )
        XCTAssertEqual(first, .log)
        XCTAssertEqual(first?.segment, .lifecycle)
        XCTAssertTrue(consumed)
        XCTAssertNil(
            CribLaunch.consume(
                arguments: ["-ReviewScreen", "goals"],
                onboardingComplete: true,
                consumed: &consumed
            )
        )
    }

    func test_threeKeysAreDistinctScreens() {
        XCTAssertEqual(CribPane.today.rawValue, "today")
        XCTAssertEqual(CribPane.log.rawValue, "log")
        XCTAssertEqual(CribPane.goals.rawValue, "goals")
        XCTAssertNotEqual(CribPane.today, CribPane.log)
        XCTAssertNotEqual(CribPane.log, CribPane.goals)
        XCTAssertNotEqual(CribPane.today, CribPane.goals)
        XCTAssertEqual(CribPane.today.segment, .inventory)
        XCTAssertEqual(CribPane.log.segment, .lifecycle)
        XCTAssertEqual(CribPane.goals.segment, .settings)
        XCTAssertNotEqual(CribPane.today.segment, CribPane.log.segment)
        XCTAssertNotEqual(CribPane.log.segment, CribPane.goals.segment)
        XCTAssertNotEqual(CribPane.today.segment, CribPane.goals.segment)
        XCTAssertEqual(CribSegment.allCases.map(\.rawValue), ["inventory", "lifecycle", "settings"])
        XCTAssertFalse(CribSegment.allCases.map(\.rawValue).contains("game"))
        XCTAssertFalse(CribSegment.allCases.map(\.rawValue).contains("sweep"))

        var consumed = false
        XCTAssertEqual(
            CribLaunch.consume(
                arguments: ["-ReviewScreen", "today"],
                onboardingComplete: true,
                consumed: &consumed
            ),
            .today
        )
        consumed = false
        XCTAssertEqual(
            CribLaunch.consume(
                arguments: ["-ReviewScreen", "goals"],
                onboardingComplete: true,
                consumed: &consumed
            ),
            .goals
        )
    }

    func test_unknownKeyIsIgnored() {
        var consumed = false
        XCTAssertNil(
            CribLaunch.consume(
                arguments: ["-ReviewScreen", "aura"],
                onboardingComplete: true,
                consumed: &consumed
            )
        )
        XCTAssertTrue(consumed)
    }
}
