import SwiftUI

struct ContentView: View {
    @State private var watch = CribWatch.live()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        CribShell(watch: watch)
            .preferredColorScheme(.dark)
            .task {
                await watch.appear()
            }
            .onChange(of: scenePhase) { _, phase in
                watch.handlePhase(phase)
            }
    }
}

#Preview {
    CribShell(watch: .previewSeeded())
        .preferredColorScheme(.dark)
}
