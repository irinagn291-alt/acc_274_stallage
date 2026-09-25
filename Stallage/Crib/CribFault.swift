import Foundation

/// Role: Crib. Typed faults of seat, hop, peel, and stall edits. Views map these; they never mutate the crib.
enum CribFault: Error, Equatable, Sendable {
    case emptyMark
    case noOpenStall
    case unknownStall
    case unknownTag
    case emptyName
    case emptyStallName
}

/// Role: Crib. Recoverable load outcome. Never crash on a corrupt snapshot.
enum CribWarning: Equatable, Sendable {
    case recoveredFromBackup
    case startedEmpty
}
