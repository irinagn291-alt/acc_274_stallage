import Foundation

/// Role: Crib. Segment chrome. The crib never leaves. Inventory, Lifecycle, and Settings swap in place. No Game tab.
enum CribSegment: String, Hashable, Sendable, CaseIterable {
    case inventory
    case lifecycle
    case settings
}

/// Role: Crib. Launch keys for live shots. today, log, and goals open three different segments.
enum CribPane: String, Equatable, Sendable {
    case today
    case log
    case goals

    var segment: CribSegment {
        switch self {
        case .today: .inventory
        case .log: .lifecycle
        case .goals: .settings
        }
    }
}

/// Role: Crib. Reads `-ReviewScreen today|log|goals` once, only after onboarding. Never hosts a View.
enum CribLaunch {
    static func consume(
        arguments: [String] = ProcessInfo.processInfo.arguments,
        onboardingComplete: Bool,
        consumed: inout Bool
    ) -> CribPane? {
        guard onboardingComplete, !consumed else { return nil }
        consumed = true
        guard let index = arguments.firstIndex(of: "-ReviewScreen") else { return nil }
        let next = arguments.index(after: index)
        guard arguments.indices.contains(next) else { return nil }
        return CribPane(rawValue: arguments[next])
    }
}
