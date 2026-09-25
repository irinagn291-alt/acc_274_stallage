import Foundation

/// Role: Crib. In-memory crib: stalls, tags, seats, hops, trail, the open stall, and onboarding. CribStore is the only mutator views talk to.
struct Crib: Equatable, Sendable {
    var onboardingComplete: Bool
    var stalls: [Stall]
    var tags: [Tag]
    var seats: [Seat]
    var hops: [Hop]
    var trailMarks: [TrailMark]
    var openStallID: UUID?
    var focusedTagID: UUID?

    static let empty = Crib(
        onboardingComplete: false,
        stalls: [],
        tags: [],
        seats: [],
        hops: [],
        trailMarks: [],
        openStallID: nil,
        focusedTagID: nil
    )

    var openStall: Stall? {
        if let openStallID, let match = stalls.first(where: { $0.id == openStallID }) {
            return match
        }
        return stalls.first
    }

    var focusedTag: Tag? {
        guard let focusedTagID else { return nil }
        return tag(id: focusedTagID)
    }

    /// Home primary verb. Enabled when an open stall can receive a scan.
    var canSeatTag: Bool { openStall != nil }

    func tag(id: UUID) -> Tag? {
        tags.first(where: { $0.id == id })
    }

    func stall(id: UUID) -> Stall? {
        stalls.first(where: { $0.id == id })
    }

    func seat(for tagID: UUID) -> Seat? {
        seats.first(where: { $0.tagID == tagID })
    }

    func hops(for tagID: UUID) -> [Hop] {
        hops.filter { $0.tagID == tagID }
    }

    func trail(for tagID: UUID) -> [TrailMark] {
        trailMarks.filter { $0.tagID == tagID }
    }

    func tags(in stallID: UUID) -> [Tag] {
        tags.filter { $0.stallID == stallID }
    }

    func overdueTags(now: Date, calendar: Calendar) -> [Tag] {
        tags.filter { $0.isOverdue(now: now, calendar: calendar) }
    }

    /// Local filter on name and code. Empty query lists the open stall. cgi search.pl stays dark.
    func seeking(_ query: String) -> [Tag] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if needle.isEmpty {
            guard let openStallID else { return [] }
            return tags(in: openStallID)
        }
        return tags.filter { tag in
            if tag.name.lowercased().contains(needle) { return true }
            if let code = tag.code?.lowercased(), code.contains(needle) { return true }
            return false
        }
    }

    func completingOnboarding() -> Crib {
        var next = self
        next.onboardingComplete = true
        return next
    }

    func resolvingOpenStall() -> Crib {
        var next = self
        if let openStallID, next.stalls.contains(where: { $0.id == openStallID }) {
            return next
        }
        next.openStallID = next.stalls.first?.id
        return next
    }

    func addingStall(name: String, duty: StallDuty, id: UUID = UUID(), mark: String? = nil) throws -> Crib {
        let stall = try Stall.named(name, duty: duty, id: id, mark: mark)
        var next = self
        next.stalls.append(stall)
        if next.openStallID == nil {
            next.openStallID = stall.id
        }
        return next
    }

    func renamingStall(_ stallID: UUID, name: String) throws -> Crib {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw CribFault.emptyStallName }
        guard let index = stalls.firstIndex(where: { $0.id == stallID }) else {
            throw CribFault.unknownStall
        }
        var next = self
        next.stalls[index].name = trimmed
        return next
    }

    func opening(_ stallID: UUID) throws -> Crib {
        guard stalls.contains(where: { $0.id == stallID }) else { throw CribFault.unknownStall }
        var next = self
        next.openStallID = stallID
        return next
    }

    func fusingName(_ tagID: UUID, _ name: String) throws -> Crib {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw CribFault.emptyName }
        guard let index = tags.firstIndex(where: { $0.id == tagID }) else {
            throw CribFault.unknownTag
        }
        var next = self
        next.tags[index].name = trimmed
        return next
    }

    func relinquishing(_ tagID: UUID) throws -> Crib {
        guard let index = tags.firstIndex(where: { $0.id == tagID }) else {
            throw CribFault.unknownTag
        }
        var next = self
        next.tags[index].status = .relinquished
        next.tags[index].issuedDayKey = nil
        next.focusedTagID = tagID
        return next
    }

    /// Seat-hop encoding. Unknown mark writes Tag and Seat. Known mark on another stall writes Hop and TrailMark.
    func seating(
        _ raw: String,
        now: Date,
        calendar: Calendar,
        assignedTo: String? = nil,
        tagID: UUID = UUID(),
        seatID: UUID = UUID(),
        hopID: UUID = UUID(),
        trailID: UUID = UUID()
    ) throws -> (Crib, SeatHop) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw CribFault.emptyMark }
        guard let open = openStall else { throw CribFault.noOpenStall }

        let marks = TagMark.candidates(from: trimmed)

        if let stall = stall(matching: marks) {
            var next = self
            next.openStallID = stall.id
            if stall.id != open.id {
                next.focusedTagID = nil
            }
            return (next, .openedStall(stallID: stall.id))
        }

        if let existing = tag(matching: marks) {
            return try registeringKnown(
                existing,
                into: open,
                now: now,
                calendar: calendar,
                assignedTo: assignedTo,
                hopID: hopID,
                trailID: trailID
            )
        }

        return seatingNew(
            code: TagMark.storedCode(from: trimmed),
            into: open,
            now: now,
            calendar: calendar,
            tagID: tagID,
            seatID: seatID
        )
    }

    private func registeringKnown(
        _ existing: Tag,
        into open: Stall,
        now: Date,
        calendar: Calendar,
        assignedTo: String?,
        hopID: UUID,
        trailID: UUID
    ) throws -> (Crib, SeatHop) {
        if existing.stallID == open.id {
            var next = self
            next.focusedTagID = existing.id
            return (next, .focused(tagID: existing.id))
        }
        if existing.isFrozen {
            var next = self
            next.focusedTagID = existing.id
            return (next, .frozen(tagID: existing.id))
        }

        let today = CribDay.from(now, calendar: calendar)
        let receiver = resolvedReceiver(assignedTo, stall: open)
        let newStatus = open.duty.status
        var moved = existing
        moved.stallID = open.id
        moved.status = newStatus
        moved.assignedTo = receiver
        moved.seatedDayKey = today.rawValue
        if newStatus == .issued {
            if moved.issuedDayKey == nil {
                moved.issuedDayKey = today.rawValue
            }
        } else {
            moved.issuedDayKey = nil
        }

        let hop = Hop(
            id: hopID,
            tagID: existing.id,
            fromStallID: existing.stallID,
            toStallID: open.id,
            assignedTo: receiver,
            priorAssignedTo: existing.assignedTo,
            priorStatus: existing.status,
            priorIssuedDayKey: existing.issuedDayKey,
            dayKey: today.rawValue
        )
        let trail = TrailMark(
            id: trailID,
            hopID: hop.id,
            tagID: existing.id,
            stallID: open.id,
            dayKey: today.rawValue
        )

        var next = self
        if let index = next.tags.firstIndex(where: { $0.id == existing.id }) {
            next.tags[index] = moved
        }
        next.placeSeat(tagID: existing.id, stallID: open.id, dayKey: today.rawValue)
        next.hops.append(hop)
        next.trailMarks.append(trail)
        next.focusedTagID = existing.id
        return (next, .hopped(tagID: existing.id, hopID: hop.id))
    }

    private func seatingNew(
        code: String?,
        into open: Stall,
        now: Date,
        calendar: Calendar,
        tagID: UUID,
        seatID: UUID
    ) -> (Crib, SeatHop) {
        let today = CribDay.from(now, calendar: calendar)
        let status = open.duty.status
        let tag = Tag(
            id: tagID,
            name: "",
            code: code,
            stallID: open.id,
            status: status,
            assignedTo: status == .issued ? open.name : nil,
            seatedDayKey: today.rawValue,
            issuedDayKey: status == .issued ? today.rawValue : nil
        )
        let seat = Seat(id: seatID, tagID: tag.id, stallID: open.id, dayKey: today.rawValue)
        var next = self
        next.tags.append(tag)
        next.seats.append(seat)
        next.focusedTagID = tag.id
        return (next, .seated(tagID: tag.id))
    }

    private mutating func placeSeat(tagID: UUID, stallID: UUID, dayKey: Int) {
        if let index = seats.firstIndex(where: { $0.tagID == tagID }) {
            seats[index].stallID = stallID
            seats[index].dayKey = dayKey
        } else {
            seats.append(Seat(id: UUID(), tagID: tagID, stallID: stallID, dayKey: dayKey))
        }
    }

    private func resolvedReceiver(_ assignedTo: String?, stall: Stall) -> String {
        let trimmed = assignedTo?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !trimmed.isEmpty { return trimmed }
        return stall.name
    }

    private func stall(matching marks: [String]) -> Stall? {
        let lowered = Set(marks.map { $0.lowercased() })
        return stalls.first { stall in
            var keys = [stall.id.uuidString.lowercased(), stall.qrPayload.lowercased()]
            if let mark = stall.mark?.lowercased() {
                keys.append(mark)
            }
            return keys.contains(where: { lowered.contains($0) })
        }
    }

    private func tag(matching marks: [String]) -> Tag? {
        let lowered = Set(marks.map { $0.lowercased() })
        return tags.first { tag in
            var keys = [tag.id.uuidString.lowercased(), tag.qrPayload.lowercased()]
            if let code = tag.code?.lowercased() {
                keys.append(code)
            }
            return keys.contains(where: { lowered.contains($0) })
        }
    }
}
