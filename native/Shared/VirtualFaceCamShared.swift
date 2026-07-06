import Foundation

enum VFCShared {
    static let appGroupIdentifier = "group.com.taehui.virtualfacecam"
    static let configFileName = "camera-config.json"
    static let imageFileName = "current-image"
    static let defaultWidth = 1280
    static let defaultHeight = 720
    static let defaultFPS = 30

    static func containerURL() -> URL? {
        if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            return appGroupURL
        }

        return FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("VirtualFaceCam", isDirectory: true)
    }

    static func configURL() -> URL? {
        containerURL()?.appendingPathComponent(configFileName)
    }

    static func imageURL(fileName: String = imageFileName) -> URL? {
        containerURL()?.appendingPathComponent(fileName)
    }
}

struct VFCCameraConfig: Codable, Equatable {
    enum FillMode: String, Codable {
        case fit
        case fill
    }

    var imageFileName: String
    var width: Int
    var height: Int
    var fps: Int
    var fillMode: FillMode
    var updatedAt: TimeInterval

    static let fallback = VFCCameraConfig(
        imageFileName: VFCShared.imageFileName,
        width: VFCShared.defaultWidth,
        height: VFCShared.defaultHeight,
        fps: VFCShared.defaultFPS,
        fillMode: .fit,
        updatedAt: 0
    )
}
