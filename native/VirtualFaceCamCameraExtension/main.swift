import CoreMediaIO
import Foundation

let providerSource = VirtualFaceCamProviderSource(clientQueue: nil)
CMIOExtensionProvider.startService(provider: providerSource.provider)
CFRunLoopRun()
