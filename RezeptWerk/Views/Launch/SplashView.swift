import SwiftUI

/// Der animierte Startbildschirm (Splashscreen) von RezeptWerk.
///
/// Rein visuell — er ändert nichts an der App-Funktion, sondern wird beim
/// Start kurz gezeigt und blendet dann in die App über (siehe
/// `LaunchRootView`).
///
/// Stil: dunkler Anthrazit-Verlauf wie das App-Icon, das kupferne
/// Serifen-„R“ mit metallischem Glanz, der aufziehende Unterstrich-Balken,
/// aufsteigende Glut-Funken (Räucher-/Grill-Motiv), Wortmarke und Claim.
///
/// Barrierefreiheit: Bei aktivem „Bewegung reduzieren“ entfallen Funken
/// und Glanz-Sweep; es bleibt ein ruhiges Ein- und Ausblenden.
struct SplashView: View {

    /// Wird aufgerufen, wenn die Inszenierung fertig ist.
    let onFinished: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Animationsstufen.
    @State private var emblemIn = false        // Emblem skaliert/blendet ein
    @State private var underlineWidth: CGFloat = 0
    @State private var wordmarkIn = false
    @State private var taglineIn = false
    @State private var glowPulse = false
    @State private var shimmerX: CGFloat = -90
    @State private var isLeaving = false

    private let emblemSize: CGFloat = 168

    var body: some View {
        ZStack {
            background

            if !reduceMotion {
                EmberField()
                    .opacity(emblemIn ? 1 : 0)
                    .allowsHitTesting(false)
            }

            VStack(spacing: AppSpacing.xl) {
                emblem
                wordmark
            }
            .scaleEffect(isLeaving ? 1.06 : 1)
            .opacity(isLeaving ? 0 : 1)
        }
        .ignoresSafeArea()
        .onAppear(perform: runSequence)
        // VoiceOver liest den Markennamen vor.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("RezeptWerk")
    }

    // MARK: Hintergrund

    private var background: some View {
        ZStack {
            // Tiefer, warmer Anthrazit-Verlauf (geräuchertes Holz).
            LinearGradient(
                colors: [
                    Color(red: 0.176, green: 0.149, blue: 0.122),
                    Color(red: 0.090, green: 0.075, blue: 0.063)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Kupfer-Glühen hinter dem Emblem.
            RadialGradient(
                colors: [AppColors.copper.opacity(0.32), .clear],
                center: .center,
                startRadius: 1,
                endRadius: 360
            )
            .scaleEffect(glowPulse ? 1.12 : 0.86)
            .opacity(emblemIn ? 1 : 0)
            .blur(radius: 12)
        }
    }

    // MARK: Emblem (Plate + „R“ + Balken)

    private var emblem: some View {
        ZStack {
            // Kupfer-umrandete Platte wie im App-Icon.
            RoundedRectangle(cornerRadius: 38, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.149, green: 0.125, blue: 0.106),
                            Color(red: 0.098, green: 0.082, blue: 0.067)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 38, style: .continuous)
                        .strokeBorder(AppColors.copper.opacity(0.5), lineWidth: 1.5)
                )
                .frame(width: emblemSize, height: emblemSize)
                .shadow(color: AppColors.copper.opacity(0.25), radius: 30, y: 10)

            VStack(spacing: 14) {
                copperLetter
                underlineBar
            }
        }
        .scaleEffect(emblemIn ? 1 : 0.7)
        .opacity(emblemIn ? 1 : 0)
    }

    /// Das Serifen-„R“ in Kupfer mit metallischem Glanz-Sweep.
    private var copperLetter: some View {
        Text("R")
            .font(.system(size: 96, weight: .bold, design: .serif))
            .foregroundStyle(AppColors.copper)
            .overlay {
                if !reduceMotion {
                    // Heller Lichtstreifen, der einmalig über das „R“ wandert.
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.85), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 50)
                    .offset(x: shimmerX)
                    .mask(
                        Text("R")
                            .font(.system(size: 96, weight: .bold, design: .serif))
                    )
                    .blendMode(.plusLighter)
                }
            }
            .shadow(color: AppColors.copper.opacity(0.6), radius: 18)
    }

    /// Der kupferne Unterstrich — die „Signatur“ der App.
    private var underlineBar: some View {
        Capsule()
            .fill(AppColors.copper)
            .frame(width: underlineWidth, height: 6)
            .shadow(color: AppColors.copper.opacity(0.6), radius: 8)
    }

    // MARK: Wortmarke + Claim

    private var wordmark: some View {
        VStack(spacing: AppSpacing.m) {
            Text("RezeptWerk")
                .font(.system(size: 34, weight: .bold, design: .serif))
                .foregroundStyle(Color(red: 0.96, green: 0.93, blue: 0.86))
                .opacity(wordmarkIn ? 1 : 0)
                .offset(y: wordmarkIn ? 0 : 14)

            Text("Kochen · Grillen · Wursten · Räuchern")
                .font(.system(size: 12, weight: .semibold))
                .textCase(.uppercase)
                .kerning(2.4)
                .foregroundStyle(AppColors.copper.opacity(0.95))
                .opacity(taglineIn ? 1 : 0)
        }
    }

    // MARK: Ablauf-Steuerung

    private func runSequence() {
        // Reduzierte Bewegung: schlichtes, schnelles Einblenden.
        guard !reduceMotion else {
            withAnimation(.easeOut(duration: 0.4)) {
                emblemIn = true
                underlineWidth = 96
                wordmarkIn = true
                taglineIn = true
            }
            Task {
                try? await Task.sleep(for: .seconds(1.3))
                withAnimation(.easeInOut(duration: 0.45)) { isLeaving = true }
                try? await Task.sleep(for: .seconds(0.45))
                onFinished()
            }
            return
        }

        // Emblem federt herein.
        withAnimation(.spring(response: 0.7, dampingFraction: 0.62)) {
            emblemIn = true
        }
        // Dauerhaftes, langsames Pulsieren des Glühens.
        withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
            glowPulse = true
        }
        // Unterstrich zieht sich auf.
        withAnimation(.easeOut(duration: 0.6).delay(0.45)) {
            underlineWidth = 96
        }
        // Glanz-Sweep über das „R“.
        withAnimation(.easeInOut(duration: 0.9).delay(0.55)) {
            shimmerX = 90
        }
        // Wortmarke und Claim.
        withAnimation(.easeOut(duration: 0.55).delay(0.7)) {
            wordmarkIn = true
        }
        withAnimation(.easeOut(duration: 0.55).delay(0.95)) {
            taglineIn = true
        }

        // Abschluss und Übergang in die App.
        Task {
            try? await Task.sleep(for: .seconds(2.2))
            withAnimation(.easeInOut(duration: 0.55)) { isLeaving = true }
            try? await Task.sleep(for: .seconds(0.55))
            onFinished()
        }
    }
}

/// Ein Feld aufsteigender Glut-Funken — dezentes Räucher-/Grill-Motiv.
private struct EmberField: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<10, id: \.self) { index in
                    EmberParticle(
                        size: CGFloat.random(in: 4...9),
                        startX: CGFloat.random(in: 0...geometry.size.width),
                        travel: geometry.size.height * 0.55,
                        delay: Double(index) * 0.32,
                        duration: Double.random(in: 3.2...5.0)
                    )
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

/// Ein einzelner, weich verlaufender Funke, der nach oben treibt und verglüht.
private struct EmberParticle: View {
    let size: CGFloat
    let startX: CGFloat
    let travel: CGFloat
    let delay: Double
    let duration: Double

    @State private var animate = false

    var body: some View {
        Circle()
            .fill(AppColors.copper)
            .frame(width: size, height: size)
            .blur(radius: size * 0.35)
            .position(x: startX, y: animate ? -travel * 0.2 : travel)
            .opacity(animate ? 0 : 0.7)
            .onAppear {
                withAnimation(
                    .easeOut(duration: duration)
                        .repeatForever(autoreverses: false)
                        .delay(delay)
                ) {
                    animate = true
                }
            }
    }
}

#Preview {
    SplashView(onFinished: {})
}
