import SwiftUI

/// Role: Tag. One ink line on the open stall. Lists are lines, not cards. Numbers keep the trailing edge.
struct TagLine: View {
    var tag: Tag
    var stallName: String
    var showStall: Bool
    var focused: Bool
    var overdueDays: String?
    var ink: [String] = []
    var onFocus: () -> Void

    var body: some View {
        Button(action: onFocus) {
            VStack(alignment: .leading, spacing: CribCraft.space(1)) {
                HStack(alignment: .firstTextBaseline, spacing: CribCraft.space(1)) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(title)
                            .font(CribFace.font(.body))
                            .foregroundStyle(CribInk.Palette.ink)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Text(subtitle)
                            .font(CribFace.font(.caption))
                            .foregroundStyle(CribInk.Palette.muted)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    if let overdueDays {
                        Text(overdueDays)
                            .font(CribFace.font(.caption))
                            .monospacedDigit()
                            .foregroundStyle(CribInk.Palette.ink)
                            .lineLimit(2)
                            .multilineTextAlignment(.trailing)
                            .layoutPriority(1)
                            .accessibilityLabel(overdueDays)
                    }
                }
                ForEach(Array(ink.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(CribFace.font(.caption))
                        .foregroundStyle(CribInk.Palette.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .minimumScaleFactor(0.8)
                }
            }
            .padding(.vertical, CribCraft.space(1))
            .frame(maxWidth: .infinity, minHeight: CribCraft.tap, alignment: .topLeading)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(CribInk.Palette.muted.opacity(focused ? 0.9 : 0.35))
                    .frame(height: focused ? CribCraft.hairline * 2 : CribCraft.hairline)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(CribPressStyle(enabled: true))
        .accessibilityLabel(title)
        .accessibilityValue(spokenValue)
        .accessibilityAddTraits(focused ? .isSelected : [])
    }

    private var title: String {
        let trimmed = tag.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return tag.code ?? "Unnamed Tag"
        }
        return trimmed
    }

    private var subtitle: String {
        var parts = [CribCopy.status(tag.status)]
        if showStall {
            parts.append(stallName)
        }
        if let assigned = tag.assignedTo, !assigned.isEmpty {
            parts.append(assigned)
        }
        if let code = tag.code, !tag.needsName {
            parts.append(code)
        }
        return parts.joined(separator: ", ")
    }

    private var spokenValue: String {
        ([subtitle] + ink).joined(separator: ". ")
    }
}
