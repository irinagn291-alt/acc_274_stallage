import Foundation

/// Role: Stall. Duty on a stall. A seat copies this onto Tag status. Lent maps to issued.
enum StallDuty: String, Equatable, Sendable, CaseIterable {
    case inStock
    case lent
    case repair
    case relinquished

    var status: TagStatus {
        switch self {
        case .inStock: .inStock
        case .lent: .issued
        case .repair: .repair
        case .relinquished: .relinquished
        }
    }

    var freezesTag: Bool { self == .relinquished }
}

/// Role: Tag. Living status of a belonging. Relinquished freezes hops. issued older than 30 local days is overdue.
enum TagStatus: String, Equatable, Sendable, CaseIterable {
    case inStock
    case issued
    case repair
    case relinquished

    var isFrozen: Bool { self == .relinquished }
}
