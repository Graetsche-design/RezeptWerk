import SwiftUI

/// Der Schritt-Timer im Kochmodus: Fortschrittsring, große Restzeit,
/// Start/Pause und Zurücksetzen.
struct StepTimerView: View {

    let viewModel: CookingModeViewModel
    let fontScale: Double

    var body: some View {
        HStack(spacing: AppSpacing.xl) {
            // Fortschrittsring mit Restzeit.
            ZStack {
                Circle()
                    .stroke(AppColors.separator, lineWidth: 6)

                Circle()
                    .trim(from: 0, to: viewModel.timerProgress)
                    .stroke(AppColors.copper, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.4), value: viewModel.timerProgress)

                Text(FormatHelpers.timerText(seconds: viewModel.timerRemainingSeconds))
                    .font(AppTypography.cookingTimer(scale: fontScale * 0.62))
                    .foregroundStyle(viewModel.timerDidFinish
                                     ? AppColors.copper
                                     : AppColors.textPrimary)
            }
            .frame(width: 110, height: 110)

            VStack(alignment: .leading, spacing: AppSpacing.m) {
                if viewModel.timerDidFinish {
                    Label("Zeit abgelaufen!", systemImage: "bell.fill")
                        .font(AppTypography.cookingMeta(scale: fontScale).weight(.semibold))
                        .foregroundStyle(AppColors.copper)
                } else if viewModel.timerIsRunning {
                    Text("Läuft weiter, auch wenn du blätterst")
                        .font(AppTypography.cookingMeta(scale: fontScale * 0.9))
                        .foregroundStyle(AppColors.textSecondary)
                } else {
                    Text("Timer für diesen Schritt")
                        .font(AppTypography.cookingMeta(scale: fontScale * 0.9))
                        .foregroundStyle(AppColors.textSecondary)
                }

                HStack(spacing: AppSpacing.m) {
                    Button {
                        viewModel.toggleTimer()
                    } label: {
                        Label(
                            viewModel.timerIsRunning ? "Pause" : "Start",
                            systemImage: viewModel.timerIsRunning ? "pause.fill" : "play.fill"
                        )
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, AppSpacing.l)
                        .frame(minHeight: 44)
                        .background(AppColors.copperGradient)
                        .clipShape(Capsule())
                    }
                    .disabled(viewModel.timerRemainingSeconds == 0 && !viewModel.timerDidFinish)

                    Button {
                        viewModel.resetTimer()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(AppColors.textPrimary)
                            .frame(width: 44, height: 44)
                            .background(AppColors.backgroundElevated, in: Circle())
                            .overlay(Circle().strokeBorder(AppColors.separator, lineWidth: 1))
                    }
                    .accessibilityLabel("Timer zurücksetzen")
                }
            }

            Spacer(minLength: 0)
        }
        .padding(AppSpacing.l)
        .background(AppColors.backgroundElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .strokeBorder(
                    viewModel.timerDidFinish ? AppColors.copper : AppColors.separator,
                    lineWidth: viewModel.timerDidFinish ? 2 : 1
                )
        )
    }
}
