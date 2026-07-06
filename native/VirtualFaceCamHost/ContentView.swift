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
            AppBackground()

            VStack(spacing: 0) {
                TopBar(installer: installer)

                Divider()
                    .opacity(0.45)

                HStack(spacing: 0) {
                    SidebarView(
                        installer: installer,
                        store: store,
                        fillMode: $fillMode,
                        isImportingImage: $isImportingImage
                    )
                    .frame(width: 344)

                    Divider()
                        .opacity(0.45)

                    PreviewPanel(store: store, fillMode: fillMode)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .background(.ultraThinMaterial)
        }
        .frame(minWidth: 1080, minHeight: 700)
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

private struct AppBackground: View {
    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)

            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.18, blue: 0.15).opacity(0.48),
                    Color(red: 0.07, green: 0.08, blue: 0.10).opacity(0.30),
                    Color(red: 0.12, green: 0.11, blue: 0.17).opacity(0.40),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .ignoresSafeArea()
    }
}

private struct TopBar: View {
    @ObservedObject var installer: SystemExtensionInstaller

    var body: some View {
        HStack(spacing: 14) {
            AppIconMark(size: 42, cornerRadius: 12)

            VStack(alignment: .leading, spacing: 1) {
                Text("Virtual Face Cam")
                    .font(.headline.weight(.semibold))
                Text("Native macOS camera source")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            StatusPill(
                title: "Camera",
                value: extensionStatusLabel,
                symbol: extensionSymbol,
                tint: extensionTint
            )

            StatusPill(
                title: "Output",
                value: "720p / 30 FPS",
                symbol: "rectangle.inset.filled",
                tint: .blue
            )
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
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

private struct SidebarView: View {
    @ObservedObject var installer: SystemExtensionInstaller
    @ObservedObject var store: CameraConfigStore

    @Binding var fillMode: VFCCameraConfig.FillMode
    @Binding var isImportingImage: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Control Room")
                    .font(.title2.weight(.bold))
                Text("Install the camera extension, select a source image, then pick Virtual Face Cam in your video app.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
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
                    symbol: "photo.on.rectangle.angled",
                    tint: .teal
                )
            }

            ControlSection(title: "Camera") {
                Button {
                    installer.install()
                } label: {
                    Label("Install / Refresh Camera", systemImage: "puzzlepiece.extension")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }

            ControlSection(title: "Source") {
                Button {
                    isImportingImage = true
                } label: {
                    Label("Choose Image", systemImage: "photo.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }

            ControlSection(title: "Frame Mode") {
                Picker("Frame Mode", selection: $fillMode) {
                    Label("Fit", systemImage: "rectangle.and.arrow.up.right.and.arrow.down.left").tag(VFCCameraConfig.FillMode.fit)
                    Label("Fill", systemImage: "rectangle.fill").tag(VFCCameraConfig.FillMode.fill)
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .onChange(of: fillMode) { newValue in
                    store.updateFillMode(newValue)
                }
            }

            Spacer()

            NextStepPanel()
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
        VStack(alignment: .leading, spacing: 22) {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Live Source")
                        .font(.system(size: 36, weight: .bold))
                    Text("Preview the frame that will be rendered by the Camera Extension.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                StatusPill(
                    title: "Mode",
                    value: fillMode == .fit ? "Fit" : "Fill",
                    symbol: fillMode == .fit ? "rectangle.and.arrow.up.right.and.arrow.down.left" : "rectangle.fill",
                    tint: .mint
                )

                StatusPill(
                    title: "Updated",
                    value: store.lastUpdatedText,
                    symbol: "clock",
                    tint: .orange
                )
            }

            CameraPreviewFrame(store: store, fillMode: fillMode)

            HStack(spacing: 14) {
                MetricCard(title: "Resolution", value: "1280 x 720", symbol: "rectangle.dashed")
                MetricCard(title: "Frame Rate", value: "30 FPS", symbol: "speedometer")
                MetricCard(title: "Camera Name", value: "Virtual Face Cam", symbol: "video.fill")
            }
        }
        .padding(34)
    }
}

private struct CameraPreviewFrame: View {
    @ObservedObject var store: CameraConfigStore
    let fillMode: VFCCameraConfig.FillMode

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color.black)
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .strokeBorder(.white.opacity(0.10), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.28), radius: 28, x: 0, y: 18)

            if let image = previewImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: fillMode == .fit ? .fit : .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .padding(18)
            } else {
                EmptyPreviewState()
            }

            VStack {
                HStack {
                    Badge(text: "Virtual Face Cam")
                    Spacer()
                    Badge(text: "1280 x 720")
                }
                Spacer()
            }
            .padding(20)
        }
        .aspectRatio(16.0 / 9.0, contentMode: .fit)
        .frame(maxWidth: 940)
    }

    private var previewImage: NSImage? {
        guard let url = store.selectedImageURL else {
            return nil
        }
        return NSImage(contentsOf: url)
    }
}

private struct EmptyPreviewState: View {
    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.08))
                    .frame(width: 120, height: 120)
                Image(systemName: "photo")
                    .font(.system(size: 64, weight: .light))
                    .foregroundStyle(.white.opacity(0.68))
            }

            VStack(spacing: 7) {
                Text("No image selected")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                Text("Choose an image to prepare the virtual camera source.")
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.66))
            }
        }
    }
}

private struct AppIconMark: View {
    let size: CGFloat
    let cornerRadius: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.20, green: 0.93, blue: 0.38),
                            Color(red: 0.08, green: 0.65, blue: 0.94),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Image(systemName: "video.badge.waveform")
                .font(.system(size: size * 0.48, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 6)
    }
}

private struct StatusCard: View {
    let title: String
    let value: String
    let detail: String
    let symbol: String
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 13) {
            IconTile(symbol: symbol, tint: tint)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.headline.weight(.semibold))
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
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.white.opacity(0.07), lineWidth: 1)
        )
    }
}

private struct ControlSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            content
        }
    }
}

private struct NextStepPanel: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            IconTile(symbol: "arrow.triangle.2.circlepath.camera", tint: .orange)
                .frame(width: 38, height: 38)

            VStack(alignment: .leading, spacing: 5) {
                Text("Next step")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text("After installation, restart the video app and select Virtual Face Cam from the camera list.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct MetricCard: View {
    let title: String
    let value: String
    let symbol: String

    var body: some View {
        HStack(spacing: 12) {
            IconTile(symbol: symbol, tint: .blue)
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.headline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(15)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.white.opacity(0.07), lineWidth: 1)
        )
    }
}

private struct IconTile: View {
    let symbol: String
    let tint: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(tint.opacity(0.16))
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(tint)
        }
        .frame(width: 42, height: 42)
    }
}

private struct StatusPill: View {
    let title: String
    let value: String
    let symbol: String
    let tint: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(tint)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.caption.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.thinMaterial, in: Capsule())
        .overlay(
            Capsule()
                .strokeBorder(.white.opacity(0.07), lineWidth: 1)
        )
    }
}

private struct Badge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption.weight(.bold))
            .foregroundStyle(.white.opacity(0.80))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.black.opacity(0.34), in: Capsule())
    }
}
