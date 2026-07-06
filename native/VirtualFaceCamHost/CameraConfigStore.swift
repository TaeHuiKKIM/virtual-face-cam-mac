import Foundation

@MainActor
final class CameraConfigStore: ObservableObject {
    @Published var statusText = "Choose an image to send to the virtual camera."
    @Published var selectedImageName = "No image selected"
    @Published var selectedImageURL: URL?
    @Published var lastUpdatedText = "Not configured yet"

    private var currentConfig = VFCCameraConfig.fallback

    init() {
        loadExistingConfig()
    }

    func copyImageAndSaveConfig(from sourceURL: URL, fillMode: VFCCameraConfig.FillMode) {
        guard let imageURL = VFCShared.imageURL(), let configURL = VFCShared.configURL() else {
            statusText = "App Group container is not available. Check signing settings."
            return
        }

        let didAccess = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        do {
            try FileManager.default.createDirectory(
                at: imageURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            if FileManager.default.fileExists(atPath: imageURL.path) {
                try FileManager.default.removeItem(at: imageURL)
            }
            try FileManager.default.copyItem(at: sourceURL, to: imageURL)

            currentConfig = VFCCameraConfig(
                imageFileName: VFCShared.imageFileName,
                width: VFCShared.defaultWidth,
                height: VFCShared.defaultHeight,
                fps: VFCShared.defaultFPS,
                fillMode: fillMode,
                updatedAt: Date().timeIntervalSince1970
            )
            let data = try JSONEncoder().encode(currentConfig)
            try data.write(to: configURL, options: [.atomic])
            statusText = "Loaded: \(sourceURL.lastPathComponent)"
            selectedImageName = sourceURL.lastPathComponent
            selectedImageURL = imageURL
            lastUpdatedText = Date().formatted(date: .abbreviated, time: .shortened)
        } catch {
            statusText = "Could not save image: \(error.localizedDescription)"
        }
    }

    func updateFillMode(_ fillMode: VFCCameraConfig.FillMode) {
        guard let configURL = VFCShared.configURL() else {
            return
        }
        currentConfig.fillMode = fillMode
        currentConfig.updatedAt = Date().timeIntervalSince1970
        do {
            let data = try JSONEncoder().encode(currentConfig)
            try data.write(to: configURL, options: [.atomic])
            lastUpdatedText = Date().formatted(date: .abbreviated, time: .shortened)
        } catch {
            statusText = "Could not update mode: \(error.localizedDescription)"
        }
    }

    private func loadExistingConfig() {
        guard let configURL = VFCShared.configURL(), let imageURL = VFCShared.imageURL() else {
            return
        }

        if
            let data = try? Data(contentsOf: configURL),
            let config = try? JSONDecoder().decode(VFCCameraConfig.self, from: data)
        {
            currentConfig = config
        }

        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            return
        }

        selectedImageURL = imageURL
        selectedImageName = "Saved source"
        statusText = "Ready to render the saved image."

        if currentConfig.updatedAt > 0 {
            lastUpdatedText = Date(timeIntervalSince1970: currentConfig.updatedAt)
                .formatted(date: .abbreviated, time: .shortened)
        } else {
            lastUpdatedText = "Saved source"
        }
    }
}
