import Foundation
import SystemExtensions

enum ExtensionInstallState {
    case idle
    case waiting
    case needsApproval
    case installed
    case failed
}

final class SystemExtensionInstaller: NSObject, ObservableObject {
    @Published var statusText = "Camera extension is not installed yet."
    @Published var state: ExtensionInstallState = .idle

    private let extensionIdentifier = "com.taehui.virtualfacecam.CameraExtension"

    func install() {
        let request = OSSystemExtensionRequest.activationRequest(
            forExtensionWithIdentifier: extensionIdentifier,
            queue: .main
        )
        request.delegate = self
        OSSystemExtensionManager.shared.submitRequest(request)
        statusText = "Waiting for macOS approval..."
        state = .waiting
    }
}

extension SystemExtensionInstaller: OSSystemExtensionRequestDelegate {
    func request(
        _ request: OSSystemExtensionRequest,
        actionForReplacingExtension existing: OSSystemExtensionProperties,
        withExtension replacement: OSSystemExtensionProperties
    ) -> OSSystemExtensionRequest.ReplacementAction {
        .replace
    }

    func requestNeedsUserApproval(_ request: OSSystemExtensionRequest) {
        statusText = "Approve the system extension in System Settings."
        state = .needsApproval
    }

    func request(_ request: OSSystemExtensionRequest, didFinishWithResult result: OSSystemExtensionRequest.Result) {
        statusText = "Camera extension is installed. Choose Virtual Face Cam in your video app."
        state = .installed
    }

    func request(_ request: OSSystemExtensionRequest, didFailWithError error: Error) {
        statusText = "Install failed: \(error.localizedDescription)"
        state = .failed
    }
}
