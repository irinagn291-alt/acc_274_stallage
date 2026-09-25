import Foundation

/// Role: Crib. Simulator demo crib. Device never writes this. Key: slg.demo.v1.
enum CribSeed {
    private static func fixed(_ value: String) -> UUID {
        UUID(uuidString: value) ?? UUID()
    }

    static func skippedDefaults() throws -> Crib {
        var crib = Crib.empty.completingOnboarding()
        crib = try crib.addingStall(name: "Bench", duty: .inStock, id: fixed("A1A1A1A1-0001-4000-8000-000000000001"))
        crib = try crib.addingStall(name: "Crew hold", duty: .lent, id: fixed("A1A1A1A1-0001-4000-8000-000000000002"))
        crib = try crib.addingStall(name: "Repair pane", duty: .repair, id: fixed("A1A1A1A1-0001-4000-8000-000000000003"))
        return crib
    }

    static func crib(now: Date = Date(), calendar: Calendar = .current) throws -> Crib {
        let bench = fixed("A1A1A1A1-0001-4000-8000-000000000001")
        let crew = fixed("A1A1A1A1-0001-4000-8000-000000000002")
        let repair = fixed("A1A1A1A1-0001-4000-8000-000000000003")
        let relic = fixed("A1A1A1A1-0001-4000-8000-000000000004")

        let loom = fixed("B2B2B2B2-0001-4000-8000-000000000001")
        let body = fixed("B2B2B2B2-0001-4000-8000-000000000002")
        let bodice = fixed("B2B2B2B2-0001-4000-8000-000000000003")
        let clamp = fixed("B2B2B2B2-0001-4000-8000-000000000004")
        let wallet = fixed("B2B2B2B2-0001-4000-8000-000000000005")
        let tape = fixed("B2B2B2B2-0001-4000-8000-000000000006")

        var crib = Crib.empty.completingOnboarding()
        crib = try crib.addingStall(name: "Bench", duty: .inStock, id: bench)
        crib = try crib.addingStall(name: "Crew hold", duty: .lent, id: crew)
        crib = try crib.addingStall(name: "Repair pane", duty: .repair, id: repair)
        crib = try crib.addingStall(name: "Relic shelf", duty: .inStock, id: relic)
        crib = try crib.opening(bench)

        let fortyDaysAgo = calendar.date(byAdding: .day, value: -40, to: now) ?? now
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: now) ?? now

        (crib, _) = try crib.seating(
            "036000291452",
            now: fortyDaysAgo,
            calendar: calendar,
            tagID: body,
            seatID: fixed("C3C3C3C3-0001-4000-8000-000000000002")
        )
        crib = try crib.fusingName(body, "Body 5D")
        crib = try crib.opening(crew)
        (crib, _) = try crib.seating(
            "036000291452",
            now: fortyDaysAgo,
            calendar: calendar,
            assignedTo: "Maya",
            hopID: fixed("D4D4D4D4-0001-4000-8000-000000000002"),
            trailID: fixed("E5E5E5E5-0001-4000-8000-000000000002")
        )

        crib = try crib.opening(bench)
        (crib, _) = try crib.seating(
            "5901234123457",
            now: twoDaysAgo,
            calendar: calendar,
            tagID: clamp,
            seatID: fixed("C3C3C3C3-0001-4000-8000-000000000004")
        )
        crib = try crib.fusingName(clamp, "Clamp light")
        crib = try crib.opening(crew)
        (crib, _) = try crib.seating(
            "5901234123457",
            now: now,
            calendar: calendar,
            assignedTo: "Jonah",
            hopID: fixed("D4D4D4D4-0001-4000-8000-000000000004"),
            trailID: fixed("E5E5E5E5-0001-4000-8000-000000000004")
        )

        crib = try crib.opening(repair)
        (crib, _) = try crib.seating(
            "4006381333931",
            now: twoDaysAgo,
            calendar: calendar,
            tagID: bodice,
            seatID: fixed("C3C3C3C3-0001-4000-8000-000000000003")
        )
        crib = try crib.fusingName(bodice, "Bodice pin")

        crib = try crib.opening(bench)
        (crib, _) = try crib.seating(
            "12345670",
            now: now,
            calendar: calendar,
            tagID: loom,
            seatID: fixed("C3C3C3C3-0001-4000-8000-000000000001")
        )
        crib = try crib.fusingName(loom, "XLR loom")

        (crib, _) = try crib.seating(
            wallet.uuidString,
            now: now,
            calendar: calendar,
            tagID: wallet,
            seatID: fixed("C3C3C3C3-0001-4000-8000-000000000005")
        )
        crib = try crib.fusingName(wallet, "Gel sleeve")

        (crib, _) = try crib.seating(
            "500015941125",
            now: now,
            calendar: calendar,
            tagID: tape,
            seatID: fixed("C3C3C3C3-0001-4000-8000-000000000006")
        )
        crib = try crib.fusingName(tape, "Tape brick")

        crib = try crib.opening(bench)
        return crib
    }
}
