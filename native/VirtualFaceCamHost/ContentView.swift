import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject private var installer: SystemExtensionInstaller
    @EnvironmentObject private var store: CameraConfigStore

    @State private var isImportingImage = false
    @State private var fillMode: VFCCameraConfig.FillMode = .fit

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Virtual Face Cam")
                        .font(.largeTitle.bold())
                    Text("Send a still image to a real macOS virtual camera.")
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            GroupBox("1. Install Camera Extension") {
                VStack(alignment: .leading, spacing: 10) {
                    Text(installer.statusText)
                        .foregroundStyle(.secondary)
                    Button("Install / Refresh Camera") {
                        installer.install()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            GroupBox("2. Choose Image") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Button("Choose Image") {
                            isImportingImage = true
                        }
                        .buttonStyle(.borderedProminent)

                        Picker("Mode", selection: $fillMode) {
                            Text("Fit").tag(VFCCameraConfig.FillMode.fit)
                            Text("Fill").tag(VFCCameraConfig.FillMode.fill)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 180)
                        .onChange(of: fillMode) { newValue in
                            store.updateFillMode(newValue)
                        }
                    }

                    Text(store.statusText)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            GroupBox("3. Use It") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Open Zoom, Teams, Chrome, FaceTime, or QuickTime.")
                    Text("Choose camera: Virtual Face Cam.")
                    Text("If the camera does not appear, quit and reopen the target app.")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer()
        }
        .padding(24)
        .frame(minWidth: 620, minHeight: 520)
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
