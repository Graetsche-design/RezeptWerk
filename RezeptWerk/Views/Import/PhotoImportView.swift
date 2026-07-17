import SwiftUI
import VisionKit

/// Foto-Import: Rezept mit der Kamera scannen (Dokumentenscanner) oder
/// ein Foto aus der Mediathek wählen → Texterkennung → Vorschau.
struct PhotoImportView: View {

    @State private var viewModel = ImportViewModel()
    @State private var showScanner = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.l) {
                tipCard

                // Dokumentenscanner — nur auf Geräten mit Kamera verfügbar
                // (im Simulator ausgeblendet).
                if VNDocumentCameraViewController.isSupported {
                    Button {
                        showScanner = true
                    } label: {
                        Label("Mit der Kamera scannen", systemImage: "camera.viewfinder")
                    }
                    .buttonStyle(.rwPrimary)
                }

                PhotoPickerButton(maxSelection: 1, onPicked: { images in
                    guard let imageData = images.first else { return }
                    Task {
                        await viewModel.importPhoto(imageData: imageData)
                    }
                }) {
                    Label("Foto aus der Mediathek wählen", systemImage: "photo.on.rectangle.angled")
                        .font(.headline)
                        .foregroundStyle(AppColors.textPrimary)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(AppColors.backgroundElevated)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
                                .strokeBorder(AppColors.wood.opacity(0.45), lineWidth: 1.5)
                        )
                }
            }
            .padding(AppSpacing.screen)
        }
        .screenBackground()
        .navigationTitle("Foto oder Scan")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if viewModel.isWorking {
                workingOverlay
            }
        }
        .navigationDestination(item: $viewModel.parsedRecipe) { parsed in
            ImportPreviewView(parsed: parsed)
        }
        .importErrorAlert($viewModel.error)
        .fullScreenCover(isPresented: $showScanner) {
            DocumentScannerView { pageImageDatas in
                Task {
                    await viewModel.importScannedPages(imageDatas: pageImageDatas)
                }
            }
            .ignoresSafeArea()
        }
    }

    private var tipCard: some View {
        HStack(alignment: .top, spacing: AppSpacing.m) {
            Image(systemName: "lightbulb")
                .font(.system(size: 18))
                .foregroundStyle(AppColors.copper)

            Text("Am besten klappt es bei gutem Licht, gerade von oben fotografiert und mit scharfem Text. Nach der Erkennung kannst du alles korrigieren.")
                .font(AppTypography.secondary)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    private var workingOverlay: some View {
        VStack(spacing: AppSpacing.m) {
            ProgressView()
                .controlSize(.large)
            Text(viewModel.workingMessage)
                .font(AppTypography.secondary)
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(AppSpacing.xxl)
        .background(AppColors.backgroundElevated, in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .shadow(color: AppColors.cardShadow, radius: 16, y: 6)
    }
}
