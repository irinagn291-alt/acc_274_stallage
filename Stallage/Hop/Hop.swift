import Foundation

/// Role: Hop. Transfer in this lexicon. A known scan onto a different stall writes Hop, TrailMark, and assignedTo.
struct Hop: Equatable, Sendable, Identifiable {
    var id: UUID
    var tagID: UUID
    var fromStallID: UUID
    var toStallID: UUID
    var assignedTo: String
    var priorAssignedTo: String?
    var priorStatus: TagStatus
    var priorIssuedDayKey: Int?
    var dayKey: Int
}
