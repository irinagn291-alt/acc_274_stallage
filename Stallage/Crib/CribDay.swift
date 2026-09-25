import Foundation

/// Role: Crib. Local day as Int YYYYMMDD from Calendar.startOfDay. Overdue spans count these days, never Date keys.
struct CribDay: RawRepresentable, Hashable, Sendable, Codable, Comparable {
    let rawValue: Int

    init(rawValue: Int) {
        self.rawValue = rawValue
    }

    static func from(_ date: Date, calendar: Calendar) -> CribDay {
        let start = calendar.startOfDay(for: date)
        let parts = calendar.dateComponents([.year, .month, .day], from: start)
        let year = parts.year ?? 1970
        let month = parts.month ?? 1
        let day = parts.day ?? 1
        return CribDay(rawValue: year * 10_000 + month * 100 + day)
    }

    func startDate(calendar: Calendar) -> Date? {
        var parts = DateComponents()
        parts.year = rawValue / 10_000
        parts.month = (rawValue / 100) % 100
        parts.day = rawValue % 100
        return calendar.date(from: parts)
    }

    static func days(from start: CribDay, to end: CribDay, calendar: Calendar) -> Int {
        guard
            let startDate = start.startDate(calendar: calendar),
            let endDate = end.startDate(calendar: calendar)
        else { return 0 }
        return calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }

    static func < (lhs: CribDay, rhs: CribDay) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
