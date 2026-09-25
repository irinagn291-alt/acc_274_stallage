import SwiftUI

/// Role: Tag. Name fusion cover. A new scan writes an unnamed Tag, then fuses a name in place.
struct TagFuse: View {
    @Bindable var watch: CribWatch
    @FocusState private var named: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: CribCraft.space(2)) {
            CribSheetBar(title: "Name this Tag") {
                watch.dismissFuse()
            }
            if CribArt.present("slg_SuccessMark") {
                Image("slg_SuccessMark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: CribCraft.space(10), height: CribCraft.space(10))
                    .accessibilityHidden(true)
            }
            Text("It is seated in \(watch.openStall?.name ?? "the open stall"). Give it a name you will recognise.")
                .font(CribFace.font(.body))
                .foregroundStyle(CribInk.Palette.muted)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let code = fuseCode {
                Text(code)
                    .font(CribFace.font(.caption))
                    .monospacedDigit()
                    .foregroundStyle(CribInk.Palette.ink)
                    .lineLimit(2)
            }
            if let fault = watch.fault {
                CribBanner(text: fault) {
                    watch.fault = nil
                }
            }
            TextField("Tag name", text: $watch.fuseDraft)
                .font(CribFace.font(.body))
                .foregroundStyle(CribInk.Palette.ink)
                .textInputAutocapitalization(.words)
                .focused($named)
                .submitLabel(.done)
                .onSubmit {
                    Task { await watch.fuseName() }
                }
                .padding(.horizontal, CribCraft.space(2))
                .frame(maxWidth: .infinity, minHeight: CribCraft.tap)
                .background(CribInk.Palette.surface, in: CribCraft.chipShape)
                .overlay {
                    CribCraft.chipShape.stroke(CribInk.Palette.muted.opacity(0.45), lineWidth: CribCraft.hairline)
                }
                .cribLift()
                .accessibilityLabel("Tag name")
            Spacer(minLength: CribCraft.space(2))
            CribVerbButton(
                title: "Continue",
                kind: .primary,
                enabled: !watch.fuseDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !watch.isCommitting,
                loading: watch.isCommitting
            ) {
                Task { await watch.fuseName() }
            }
            CribVerbButton(title: "Later", kind: .quiet) {
                watch.dismissFuse()
            }
        }
        .padding(CribCraft.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(CribInk.Palette.background.ignoresSafeArea())
        .scrollDismissesKeyboard(.interactively)
        .cribDismissKeyboardOnBackground()
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    named = false
                }
                .font(CribFace.font(.body))
            }
        }
        .onAppear {
            named = true
        }
    }

    private var fuseCode: String? {
        guard let id = watch.fuseTagID else { return nil }
        return watch.crib.tag(id: id)?.code
    }
}
