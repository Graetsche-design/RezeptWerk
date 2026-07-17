import SwiftUI

/// Zeigt zuerst den animierten Splashscreen und blendet danach in die
/// eigentliche App (`RootView`) über.
///
/// Bewusst minimal: Die gesamte App-Logik bleibt unverändert in `RootView`.
/// Diese Hülle steuert nur die kurze Einblendung beim Start.
struct LaunchRootView: View {

    @State private var showSplash = true

    var body: some View {
        ZStack {
            // Die echte App liegt bereits bereit darunter — beim Ausblenden
            // des Splashs erscheint sie ohne Ruckler.
            RootView()

            if showSplash {
                SplashView {
                    showSplash = false
                }
                .transition(.opacity)
                .zIndex(1)
            }
        }
    }
}

#Preview {
    LaunchRootView()
        .modelContainer(PreviewSupport.container)
}
