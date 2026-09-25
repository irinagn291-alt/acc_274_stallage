import Foundation

/// Role: Crib. Display fold for hop counts, overdue days, and daykeys. Round only here. Tabular figures.
enum CribFigures {
    static func integer(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }

    static func day(_ date: Date, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = .current
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: calendar.startOfDay(for: date))
    }

    static func dayKey(_ value: Int, calendar: Calendar) -> String {
        let day = CribDay(rawValue: value)
        guard let start = day.startDate(calendar: calendar) else {
            return integer(value)
        }
        return Self.day(start, calendar: calendar)
    }

    static func issuedDays(issuedDayKey: Int, now: Date, calendar: Calendar) -> Int {
        let days = CribDay.days(
            from: CribDay(rawValue: issuedDayKey),
            to: CribDay.from(now, calendar: calendar),
            calendar: calendar
        )
        return max(0, days)
    }

    static func issuedSpan(issuedDayKey: Int, now: Date, calendar: Calendar) -> String {
        let days = issuedDays(issuedDayKey: issuedDayKey, now: now, calendar: calendar)
        if days == 1 {
            return "\(integer(days)) day overdue"
        }
        return "\(integer(days)) days overdue"
    }
}

/// Role: Crib. Spoken duty and status. Axis values never appear as titles.
enum CribCopy {
    static func duty(_ duty: StallDuty) -> String {
        switch duty {
        case .inStock: "In stall"
        case .lent: "Lent"
        case .repair: "Repair"
        case .relinquished: "Relinquished"
        }
    }

    static func status(_ status: TagStatus) -> String {
        switch status {
        case .inStock: "In stall"
        case .issued: "Issued"
        case .repair: "Repair"
        case .relinquished: "Relinquished"
        }
    }

    static func fault(_ error: Error) -> String {
        switch error as? CribFault {
        case .emptyMark:
            "Scan a barcode or QR, or type a code."
        case .noOpenStall:
            "Open a stall first. Add one in Settings."
        case .unknownStall:
            "That stall is not in this crib."
        case .unknownTag:
            "That Tag is not in this crib."
        case .emptyName:
            "Give this Tag a name."
        case .emptyStallName:
            "Name the stall first."
        case .none:
            "The crib could not be updated."
        }
    }
}
