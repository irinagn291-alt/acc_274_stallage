import Foundation

/// Role: Stall. A named crib bay. Categories are stalls. QR is mark if present, else id.
struct Stall: Equatable, Sendable, Identifiable {
    var id: UUID
    var name: String
    var duty: StallDuty
    var mark: String?

    var qrPayload: String {
        if let mark, !mark.isEmpty { return mark }
        return id.uuidString
    }

    static func named(
        _ name: String,
        duty: StallDuty,
        id: UUID = UUID(),
        mark: String? = nil
    ) throws -> Stall {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw CribFault.emptyStallName }
        return Stall(id: id, name: trimmed, duty: duty, mark: mark)
    }
}
