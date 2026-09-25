import XCTest
@testable import Stallage

final class TagMarkTests: XCTestCase {
    func test_extractsDigitRunsFromQRURLAndPadsUPCA() {
        let fromURL = TagMark.candidates(from: "https://stallage-crib.pro/p/036000291452")
        XCTAssertTrue(fromURL.contains("0036000291452"))
        XCTAssertTrue(fromURL.contains("036000291452"))

        XCTAssertEqual(TagMark.storedCode(from: "036000291452"), "0036000291452")
        XCTAssertEqual(TagMark.storedCode(from: "5901234123457"), "5901234123457")
        XCTAssertEqual(TagMark.storedCode(from: "12345670"), "12345670")
        XCTAssertNil(TagMark.storedCode(from: "B2B2B2B2-0001-4000-8000-000000000005"))
        XCTAssertEqual(TagMark.digitRuns(in: "kit 12345670 and 5901234123457"), ["12345670", "5901234123457"])
    }

    func test_emptyAndShortPayloadsYieldNoStoredBarcode() {
        XCTAssertEqual(TagMark.candidates(from: "   "), [])
        XCTAssertNil(TagMark.storedCode(from: "   "))
        XCTAssertEqual(TagMark.candidates(from: "1234567").contains("1234567"), true)
        XCTAssertEqual(TagMark.storedCode(from: "1234567"), "1234567")
    }
}
