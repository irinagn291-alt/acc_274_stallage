import SwiftUI

/// Role: Crib. SF Pro via Font.system only. Six steps: display, title, headline, body, caption, micro. Display is the open stall name. Body is about 17pt.
enum CribFace {
    enum Step: CaseIterable {
        case display
        case title
        case headline
        case body
        case caption
        case micro

        var font: Font {
            switch self {
            case .display:
                .system(.largeTitle).weight(.semibold)
            case .title:
                .system(.title2).weight(.semibold)
            case .headline:
                .system(.headline)
            case .body:
                .system(.body)
            case .caption:
                .system(.footnote)
            case .micro:
                .system(.caption)
            }
        }
    }

    static func font(_ step: Step) -> Font {
        step.font
    }
}
