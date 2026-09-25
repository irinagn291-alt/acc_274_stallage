import Foundation

/// Role: Crib. In-memory crib for previews and tests. Views never see this type.
actor CribHold: CribStoring {
    private var latest: Crib
    private var warning: CribWarning?

    init(crib: Crib = .empty, warning: CribWarning? = nil) {
        self.latest = crib
        self.warning = warning
    }

    func load() async -> (crib: Crib, warning: CribWarning?) {
        (latest, warning)
    }

    func snapshot() async -> Crib {
        latest
    }

    func seatTag(_ raw: String, now: Date, calendar: Calendar, assignedTo: String?) async throws -> SeatHop {
        let (next, outcome) = try latest.seating(raw, now: now, calendar: calendar, assignedTo: assignedTo)
        latest = next
        return outcome
    }

    func fuseName(tagID: UUID, name: String) async throws -> Crib {
        latest = try latest.fusingName(tagID, name)
        return latest
    }

    func openStall(_ stallID: UUID) async throws -> Crib {
        latest = try latest.opening(stallID)
        return latest
    }

    func peelLastHop(tagID: UUID?) async throws -> Crib {
        latest = try latest.peelLastHop(tagID: tagID)
        return latest
    }

    func relinquish(tagID: UUID) async throws -> Crib {
        latest = try latest.relinquishing(tagID)
        return latest
    }

    func addStall(name: String, duty: StallDuty) async throws -> Crib {
        latest = try latest.addingStall(name: name, duty: duty)
        return latest
    }

    func renameStall(_ stallID: UUID, name: String) async throws -> Crib {
        latest = try latest.renamingStall(stallID, name: name)
        return latest
    }

    func setOnboardingComplete(_ flag: Bool) async -> Crib {
        if flag {
            latest = latest.completingOnboarding()
        } else {
            latest.onboardingComplete = false
        }
        return latest
    }

    func flush() async throws {}

    func resetAllData() async throws {
        latest = .empty
        warning = nil
    }

    func seedDemoIfNeeded(now: Date, calendar: Calendar) async throws -> Crib? {
        _ = now
        _ = calendar
        return nil
    }
}
