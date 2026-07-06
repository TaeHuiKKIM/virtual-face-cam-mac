import SwiftUI

@main
struct VirtualFaceCamApp: App {
    @StateObject private var installer = SystemExtensionInstaller()
    @StateObject private var store = CameraConfigStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(installer)
                .environmentObject(store)
        }
        .windowStyle(.hiddenTitleBar)
    }
}
