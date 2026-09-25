import SwiftUI

/// Role: Crib. Segment chrome. The crib never leaves. Inventory, Lifecycle, and Settings swap in place. No tab bar.
struct CribShell: View {
    @Bindable var watch: CribWatch
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if !watch.didLoad {
                loading
            } else {
                shell
            }
        }
        .tint(CribInk.Palette.accent)
        .background(CribInk.Palette.background.ignoresSafeArea())
        .fullScreenCover(isPresented: onboardingBind) {
            CribOnboard(watch: watch)
        }
        .fullScreenCover(item: $watch.cover) { cover in
            NavigationStack {
                Group {
                    switch cover {
                    case .capture:
                        StallCapture(watch: watch)
                    case .fuse:
                        TagFuse(watch: watch)
                    case .mark:
                        CribMarkShare(watch: watch)
                    case .hopTrail:
                        HopTrailPane(watch: watch)
                    }
                }
                .toolbar(.hidden, for: .navigationBar)
            }
        }
        .sensoryFeedback(.success, trigger: watch.commitTick)
        .onChange(of: scenePhase) { _, phase in
            watch.handlePhase(phase)
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            watch.refreshDay()
        }
    }

    private var loading: some View {
        ZStack {
            CribInk.Palette.background
            if watch.isHauling {
                ProgressView()
                    .tint(CribInk.Palette.accent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var shell: some View {
        NavigationStack {
            VStack(spacing: CribCraft.space(1)) {
                picker
                ZStack {
                    pane
                        .transition(.opacity)
                        .id(watch.segment)
                }
                .animation(CribCraft.motion(reduce: reduceMotion), value: watch.segment)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .toolbar(.hidden, for: .navigationBar)
            .background(CribInk.Palette.background.ignoresSafeArea())
        }
    }

    private var picker: some View {
        Picker("Crib", selection: $watch.segment) {
            Text("Inventory").tag(CribSegment.inventory)
            Text("Lifecycle").tag(CribSegment.lifecycle)
            Text("Settings").tag(CribSegment.settings)
        }
        .pickerStyle(.segmented)
        .frame(minHeight: CribCraft.tap)
        .padding(.horizontal, CribCraft.space(2))
        .padding(.top, CribCraft.space(1))
        .accessibilityLabel("Crib")
    }

    @ViewBuilder
    private var pane: some View {
        switch watch.segment {
        case .inventory:
            InventoryView(watch: watch)
        case .lifecycle:
            LifecycleView(watch: watch)
        case .settings:
            CribSettings(watch: watch)
        }
    }

    private var onboardingBind: Binding<Bool> {
        Binding(
            get: { watch.showsOnboarding },
            set: { presented in
                if !presented {
                    Task { await watch.finishOnboarding() }
                }
            }
        )
    }
}
