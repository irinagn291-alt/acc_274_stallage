import Foundation

/// Role: Hop. Peels the last Hop on a tag, or the Tag itself when it has none.
extension Crib {
    func peelLastHop(tagID: UUID? = nil) throws -> Crib {
        let targetID = tagID ?? focusedTagID ?? hops.last?.tagID
        guard let targetID, let existing = tag(id: targetID) else {
            throw CribFault.unknownTag
        }

        let owned = hops.filter { $0.tagID == targetID }
        if let last = owned.last {
            return peeling(last, of: existing)
        }
        return removingTag(targetID)
    }

    private func peeling(_ hop: Hop, of existing: Tag) -> Crib {
        var restored = existing
        restored.stallID = hop.fromStallID
        restored.status = hop.priorStatus
        restored.assignedTo = hop.priorAssignedTo
        restored.issuedDayKey = hop.priorIssuedDayKey
        restored.seatedDayKey = hop.dayKey

        var next = self
        if let index = next.tags.firstIndex(where: { $0.id == existing.id }) {
            next.tags[index] = restored
        }
        if let seatIndex = next.seats.firstIndex(where: { $0.tagID == existing.id }) {
            next.seats[seatIndex].stallID = hop.fromStallID
            next.seats[seatIndex].dayKey = hop.dayKey
        }
        next.hops.removeAll { $0.id == hop.id }
        next.trailMarks.removeAll { $0.hopID == hop.id }
        next.focusedTagID = existing.id
        return next
    }

    private func removingTag(_ tagID: UUID) -> Crib {
        var next = self
        next.tags.removeAll { $0.id == tagID }
        next.seats.removeAll { $0.tagID == tagID }
        next.hops.removeAll { $0.tagID == tagID }
        next.trailMarks.removeAll { $0.tagID == tagID }
        if next.focusedTagID == tagID {
            next.focusedTagID = nil
        }
        return next
    }
}
