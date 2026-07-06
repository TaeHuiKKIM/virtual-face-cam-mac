import Foundation
import SystemExtensions

final class SystemExtensionInstaller: NSObject, ObservableObject {
    @Published var statusText = "Camera extension is not installed yet."

    private let extensionIdentifier = "com.taehui.virtualfacecam.CameraExtension"

    func install() {
        let request = OSSystemExtensionRequest.activationRequest(
            forExtensionWithIdentifier: extensionIdentifier,
            queue: .main
        )
        request.delegate = self
        OSSystemExtensionManager.shared.submitRequest(request)
        statusText = "Waiting for macOS approval..."
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
    }

    func request(_ request: OSSystemExtensionRequest, didFinishWithResult result: OSSystemExtensionRequest.Result) {
        statusText = "Camera extension is installed. Choose Virtual Face Cam in your video app."
    }

    func request(_ request: OSSystemExtensionRequest, didFailWithError error: Error) {
        statusText = "Install failed: \(error.localizedDescription)"
    }
}
