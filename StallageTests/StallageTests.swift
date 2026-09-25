import XCTest
@testable import Stallage

final class StallageTests: XCTestCase {
    func test_appModuleImports() {
        XCTAssertEqual(String(describing: StallageApp.self), "StallageApp")
        XCTAssertEqual(String(describing: CribStore.self), "CribStore")
        XCTAssertEqual(CribInk.face, "SF Pro")
        XCTAssertEqual(CribInk.Hex.background, "#1D161A")
        XCTAssertEqual(CribInk.Hex.surface, "#291E24")
        XCTAssertEqual(CribInk.Hex.ink, "#F2EDF0")
        XCTAssertEqual(CribInk.Hex.accent, "#DD5F9E")
        XCTAssertEqual(CribInk.Hex.muted, "#A8949E")
        XCTAssertEqual(CribFace.Step.allCases.count, 6)
        XCTAssertEqual(String(describing: InventoryView.self), "InventoryView")
        XCTAssertEqual(String(describing: LifecycleView.self), "LifecycleView")
        XCTAssertEqual(String(describing: CribSettings.self), "CribSettings")
    }
}
