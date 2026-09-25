import Foundation

/// Role: Tag. Turns camera text, typed marks, and pasted URLs into match candidates. Digit runs 8-14. UPC-A of 12 digits gets a leading 0.
enum TagMark {
    static func candidates(from raw: String) -> [String] {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        var ordered: [String] = []
        var seen = Set<String>()

        func take(_ value: String) {
            guard !value.isEmpty, seen.insert(value).inserted else { return }
            ordered.append(value)
        }

        take(trimmed)
        let lowered = trimmed.lowercased()
        if lowered != trimmed {
            take(lowered)
        }
        if UUID(uuidString: trimmed) != nil {
            return ordered
        }
        for uuid in uuidRuns(in: trimmed) {
            take(uuid)
            take(uuid.lowercased())
        }
        for run in digitRuns(in: trimmed) {
            guard (8...14).contains(run.count) else { continue }
            if run.count == 12 {
                take("0" + run)
                take(run)
            } else {
                take(run)
            }
        }
        return ordered
    }

    /// Canonical stored barcode when the payload carries one. UUID-only QR stores nil so QR falls back to id.
    static func storedCode(from raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if UUID(uuidString: trimmed) != nil {
            return nil
        }
        let marks = candidates(from: trimmed)
        if let thirteen = marks.first(where: { $0.count == 13 && $0.unicodeScalars.allSatisfy(CharacterSet.decimalDigits.contains) }) {
            return thirteen
        }
        if let run = marks.first(where: { (8...14).contains($0.count) && $0.unicodeScalars.allSatisfy(CharacterSet.decimalDigits.contains) }) {
            return run
        }
        return trimmed
    }

    static func digitRuns(in raw: String) -> [String] {
        var runs: [String] = []
        var current = ""
        for character in raw where character.isASCII {
            if character.isNumber {
                current.append(character)
            } else if !current.isEmpty {
                runs.append(current)
                current = ""
            }
        }
        if !current.isEmpty {
            runs.append(current)
        }
        return runs
    }

    private static func uuidRuns(in raw: String) -> [String] {
        let pattern = /[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}/
        return raw.matches(of: pattern).map { String($0.output) }
    }
}
