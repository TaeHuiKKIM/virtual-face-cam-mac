import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject private var installer: SystemExtensionInstaller
    @EnvironmentObject private var store: CameraConfigStore

    @State private var isImportingImage = false
    @State private var fillMode: VFCCameraConfig.FillMode = .fit

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(nsColor: .windowBackgroundColor),
                    Color(nsColor: .controlBackgroundColor),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            HStack(spacing: 0) {
                SidebarView(
                    installer: installer,
                    store: store,
                    fillMode: $fillMode,
                    isImportingImage: $isImportingImage
                )
                .frame(width: 320)

                Divider()

                PreviewPanel(store: store, fillMode: fillMode)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(.regularMaterial)
        }
        .frame(minWidth: 960, minHeight: 640)
        .fileImporter(
            isPresented: $isImportingImage,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                store.copyImageAndSaveConfig(from: url, fillMode: fillMode)
            case .failure(let error):
                store.statusText = "Could not open image: \(error.localizedDescription)"
            }
        }
    }
}

private struct SidebarView: View {
    @ObservedObject var installer: SystemExtensionInstaller
    @ObservedObject var store: CameraConfigStore

    @Binding var fillMode: VFCCameraConfig.FillMode
    @Binding var isImportingImage: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.green.gradient)
                    Image(systemName: "video.badge.waveform")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(width: 58, height: 58)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Virtual Face Cam")
                        .font(.title2.bold())
                    Text("Standalone macOS camera")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(spacing: 12) {
                StatusCard(
                    title: "Camera Extension",
                    value: extensionStatusLabel,
                    detail: installer.statusText,
                    symbol: extensionSymbol,
                    tint: extensionTint
                )

                StatusCard(
                    title: "Image Source",
                    value: store.selectedImageName,
                    detail: store.statusText,
                    symbol: "photo.on.rectangle",
                    tint: .teal
                )

                StatusCard(
                    title: "Output",
                    value: "1280 x 720 at 30 FPS",
                    detail: "Choose Virtual Face Cam in Zoom, Teams, Chrome, or FaceTime.",
                    symbol: "rectangle.inset.filled.and.person.filled",
                    tint: .blue
                )
            }

            VStack(alignment: .leading, spacing: 12) {
                Button {
                    installer.install()
                } label: {
                    Label("Install / Refresh Camera", systemImage: "puzzlepiece.extension")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button {
                    isImportingImage = true
                } label: {
                    Label("Choose Image", systemImage: "photo.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Picker("Frame Mode", selection: $fillMode) {
                    Label("Fit", systemImage: "rectangle.and.arrow.up.right.and.arrow.down.left").tag(VFCCameraConfig.FillMode.fit)
                    Label("Fill", systemImage: "rectangle.fill").tag(VFCCameraConfig.FillMode.fill)
                }
                .pickerStyle(.segmented)
                .onChange(of: fillMode) { newValue in
                    store.updateFillMode(newValue)
                }
            }

            Spacer()

            VStack(alignment: .leading, spacing: 8) {
                Text("Next step")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Text("After installation, restart the video app and select Virtual Face Cam from the camera list.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(24)
    }

    private var extensionStatusLabel: String {
        switch installer.state {
        case .idle:
            return "Not installed"
        case .waiting:
            return "Waiting"
        case .needsApproval:
            return "Needs approval"
        case .installed:
            return "Installed"
        case .failed:
            return "Failed"
        }
    }

    private var extensionSymbol: String {
        switch installer.state {
        case .installed:
            return "checkmark.seal.fill"
        case .failed:
            return "exclamationmark.triangle.fill"
        case .needsApproval:
            return "hand.raised.fill"
        default:
            return "camera.aperture"
        }
    }

    private var extensionTint: Color {
        switch installer.state {
        case .installed:
            return .green
        case .failed:
            return .red
        case .needsApproval:
            return .orange
        default:
            return .indigo
        }
    }
}

private struct PreviewPanel: View {
    @ObservedObject var store: CameraConfigStore
    let fillMode: VFCCameraConfig.FillMode

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Live Source")
                        .font(.largeTitle.bold())
                    Text("This is the image the Camera Extension will render.")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Badge(text: fillMode == .fit ? "FIT" : "FILL")
                Badge(text: store.lastUpdatedText)
            }

            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.black)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.20), radius: 22, x: 0, y: 12)

                if let image = previewImage {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: fillMode == .fit ? .fit : .fill)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .padding(18)
                } else {
                    VStack(spacing: 18) {
                        Image(systemName: "photo")
                            .font(.system(size: 72, weight: .light))
                            .foregroundStyle(.white.opacity(0.62))
                        VStack(spacing: 6) {
                            Text("No image selected")
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                            Text("Choose an image to prepare the virtual camera source.")
                                .foregroundStyle(.white.opacity(0.66))
                        }
                    }
                }
            }
            .aspectRatio(16.0 / 9.0, contentMode: .fit)
            .frame(maxWidth: 900)

            HStack(spacing: 14) {
                MetricCard(title: "Resolution", value: "1280 x 720")
                MetricCard(title: "Frame Rate", value: "30 FPS")
                MetricCard(title: "Camera Name", value: "Virtual Face Cam")
            }
        }
        .padding(30)
    }

    private var previewImage: NSImage? {
        guard let url = store.selectedImageURL else {
            return nil
        }
        return NSImage(contentsOf: url)
    }
}

private struct StatusCard: View {
    let title: String
    let value: String
    let detail: String
    let symbol: String
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(tint.opacity(0.16))
                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(tint)
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.headline)
                    .lineLimit(1)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct MetricCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct Badge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption.bold())
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.thinMaterial, in: Capsule())
    }
}
