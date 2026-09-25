import Foundation

/// Role: Tag. Current placement of a Tag in a Stall. A new scan writes Tag and Seat together.
struct Seat: Equatable, Sendable, Identifiable {
    var id: UUID
    var tagID: UUID
    var stallID: UUID
    var dayKey: Int
}
