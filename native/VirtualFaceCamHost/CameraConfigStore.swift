import Foundation

@MainActor
final class CameraConfigStore: ObservableObject {
    @Published var statusText = "Choose an image to send to the virtual camera."

    private var currentConfig = VFCCameraConfig.fallback

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
        } catch {
            statusText = "Could not update mode: \(error.localizedDescription)"
        }
    }
}
