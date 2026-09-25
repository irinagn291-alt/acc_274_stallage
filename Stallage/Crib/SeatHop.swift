import Foundation

/// Role: Crib. Outcome of one scan against the open stall. Seat and hop fuse on Inventory.
enum SeatHop: Equatable, Sendable {
    case seated(tagID: UUID)
    case hopped(tagID: UUID, hopID: UUID)
    case focused(tagID: UUID)
    case frozen(tagID: UUID)
    case openedStall(stallID: UUID)
}
