import Foundation

/// Role: Crib. Preference keys. Snapshot is JSON Data under slg.crib.v1. Demo is Simulator-only.
enum CribKey {
    static let snapshot = "slg.crib.v1"
    static let backup = "slg.crib.v1.backup"
    static let demo = "slg.demo.v1"
}

/// Role: Crib. Codable root. schemaVersion from 1. Overdue is never a stored field.
struct CribDocument: Equatable, Sendable {
    var schemaVersion: Int
    var crib: Crib
}

/// Role: Crib. schemaVersion switch and crib ↔ JSON mapping. UserDefaults never sees Tag raw.
enum CribCodec {
    static let currentSchema = 1

    enum Failure: Error, Equatable {
        case unsupportedSchema(Int)
        case corrupt
    }

    static func encode(_ document: CribDocument) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(RootRecord.from(document))
    }

    static func decode(_ data: Data) throws -> CribDocument {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        let probe: SchemaProbe
        do {
            probe = try decoder.decode(SchemaProbe.self, from: data)
        } catch {
            throw Failure.corrupt
        }
        switch probe.schemaVersion {
        case 1:
            do {
                return try decoder.decode(RootRecord.self, from: data).asDocument()
            } catch let failure as Failure {
                throw failure
            } catch {
                throw Failure.corrupt
            }
        default:
            throw Failure.unsupportedSchema(probe.schemaVersion)
        }
    }

    static func committed(from crib: Crib) -> CribDocument {
        CribDocument(schemaVersion: currentSchema, crib: crib.resolvingOpenStall())
    }
}

private struct SchemaProbe: Decodable {
    var schemaVersion: Int
}

private struct RootRecord: Codable {
    var schemaVersion: Int
    var onboardingComplete: Bool
    var openStallID: UUID?
    var focusedTagID: UUID?
    var stalls: [StallRecord]
    var tags: [TagRecord]
    var seats: [SeatRecord]
    var hops: [HopRecord]
    var trailMarks: [TrailRecord]

    static func from(_ document: CribDocument) -> RootRecord {
        let crib = document.crib.resolvingOpenStall()
        return RootRecord(
            schemaVersion: CribCodec.currentSchema,
            onboardingComplete: crib.onboardingComplete,
            openStallID: crib.openStallID,
            focusedTagID: crib.focusedTagID,
            stalls: crib.stalls.map(StallRecord.init(stall:)),
            tags: crib.tags.map(TagRecord.init(tag:)),
            seats: crib.seats.map(SeatRecord.init(seat:)),
            hops: crib.hops.map(HopRecord.init(hop:)),
            trailMarks: crib.trailMarks.map(TrailRecord.init(mark:))
        )
    }

    func asDocument() throws -> CribDocument {
        let crib = Crib(
            onboardingComplete: onboardingComplete,
            stalls: try stalls.map { try $0.asStall() },
            tags: try tags.map { try $0.asTag() },
            seats: try seats.map { try $0.asSeat() },
            hops: try hops.map { try $0.asHop() },
            trailMarks: try trailMarks.map { try $0.asMark() },
            openStallID: openStallID,
            focusedTagID: focusedTagID
        )
        return CribDocument(schemaVersion: schemaVersion, crib: crib.resolvingOpenStall())
    }
}

private struct StallRecord: Codable {
    var id: UUID
    var name: String
    var duty: String
    var mark: String?

    init(stall: Stall) {
        id = stall.id
        name = stall.name
        duty = stall.duty.rawValue
        mark = stall.mark
    }

    func asStall() throws -> Stall {
        guard let duty = StallDuty(rawValue: duty) else { throw CribCodec.Failure.corrupt }
        return try Stall.named(name, duty: duty, id: id, mark: mark)
    }
}

private struct TagRecord: Codable {
    var id: UUID
    var name: String
    var code: String?
    var stallID: UUID
    var status: String
    var assignedTo: String?
    var seatedDayKey: Int
    var issuedDayKey: Int?

    init(tag: Tag) {
        id = tag.id
        name = tag.name
        code = tag.code
        stallID = tag.stallID
        status = tag.status.rawValue
        assignedTo = tag.assignedTo
        seatedDayKey = tag.seatedDayKey
        issuedDayKey = tag.issuedDayKey
    }

    func asTag() throws -> Tag {
        guard let status = TagStatus(rawValue: status) else { throw CribCodec.Failure.corrupt }
        let codeValue = code?.trimmingCharacters(in: .whitespacesAndNewlines)
        return Tag(
            id: id,
            name: name,
            code: (codeValue?.isEmpty == false) ? codeValue : nil,
            stallID: stallID,
            status: status,
            assignedTo: assignedTo,
            seatedDayKey: seatedDayKey,
            issuedDayKey: issuedDayKey
        )
    }
}

private struct SeatRecord: Codable {
    var id: UUID
    var tagID: UUID
    var stallID: UUID
    var dayKey: Int

    init(seat: Seat) {
        id = seat.id
        tagID = seat.tagID
        stallID = seat.stallID
        dayKey = seat.dayKey
    }

    func asSeat() throws -> Seat {
        guard dayKey > 0 else { throw CribCodec.Failure.corrupt }
        return Seat(id: id, tagID: tagID, stallID: stallID, dayKey: dayKey)
    }
}

private struct HopRecord: Codable {
    var id: UUID
    var tagID: UUID
    var fromStallID: UUID
    var toStallID: UUID
    var assignedTo: String
    var priorAssignedTo: String?
    var priorStatus: String
    var priorIssuedDayKey: Int?
    var dayKey: Int

    init(hop: Hop) {
        id = hop.id
        tagID = hop.tagID
        fromStallID = hop.fromStallID
        toStallID = hop.toStallID
        assignedTo = hop.assignedTo
        priorAssignedTo = hop.priorAssignedTo
        priorStatus = hop.priorStatus.rawValue
        priorIssuedDayKey = hop.priorIssuedDayKey
        dayKey = hop.dayKey
    }

    func asHop() throws -> Hop {
        guard let priorStatus = TagStatus(rawValue: priorStatus) else { throw CribCodec.Failure.corrupt }
        guard !assignedTo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CribCodec.Failure.corrupt
        }
        return Hop(
            id: id,
            tagID: tagID,
            fromStallID: fromStallID,
            toStallID: toStallID,
            assignedTo: assignedTo,
            priorAssignedTo: priorAssignedTo,
            priorStatus: priorStatus,
            priorIssuedDayKey: priorIssuedDayKey,
            dayKey: dayKey
        )
    }
}

private struct TrailRecord: Codable {
    var id: UUID
    var hopID: UUID
    var tagID: UUID
    var stallID: UUID
    var dayKey: Int

    init(mark: TrailMark) {
        id = mark.id
        hopID = mark.hopID
        tagID = mark.tagID
        stallID = mark.stallID
        dayKey = mark.dayKey
    }

    func asMark() throws -> TrailMark {
        guard dayKey > 0 else { throw CribCodec.Failure.corrupt }
        return TrailMark(id: id, hopID: hopID, tagID: tagID, stallID: stallID, dayKey: dayKey)
    }
}
