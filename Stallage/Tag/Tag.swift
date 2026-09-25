import Foundation

/// Role: Tag. One belonging. Asset in this lexicon. QR is code if present, else id. Relinquished freezes hops.
struct Tag: Equatable, Sendable, Identifiable {
    var id: UUID
    var name: String
    var code: String?
    var stallID: UUID
    var status: TagStatus
    var assignedTo: String?
    var seatedDayKey: Int
    var issuedDayKey: Int?

    var needsName: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var isFrozen: Bool { status.isFrozen }

    var qrPayload: String {
        if let code, !code.isEmpty { return code }
        return id.uuidString
    }

    func isOverdue(now: Date, calendar: Calendar) -> Bool {
        isOverdue(on: CribDay.from(now, calendar: calendar), calendar: calendar)
    }

    func isOverdue(on today: CribDay, calendar: Calendar) -> Bool {
        guard status == .issued, let issuedDayKey else { return false }
        return CribDay.days(from: CribDay(rawValue: issuedDayKey), to: today, calendar: calendar) > 30
    }
}
