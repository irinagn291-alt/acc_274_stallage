import Foundation

/// Role: TrailMark. One breadcrumb on a hop trail. Lifecycle reads these with hops and overdue issued tags.
struct TrailMark: Equatable, Sendable, Identifiable {
    var id: UUID
    var hopID: UUID
    var tagID: UUID
    var stallID: UUID
    var dayKey: Int
}
