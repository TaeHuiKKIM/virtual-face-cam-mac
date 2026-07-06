import CoreImage
import CoreMedia
import CoreMediaIO
import CoreVideo
import Foundation
import IOKit.audio
import os.log

private let vfcFrameRate = VFCShared.defaultFPS
private let vfcWidth = VFCShared.defaultWidth
private let vfcHeight = VFCShared.defaultHeight

final class VirtualFaceCamFrameRenderer {
    private let context = CIContext(options: nil)
    private let colorSpace = CGColorSpaceCreateDeviceRGB()
    private var lastConfigModifiedDate: Date?
    private var cachedConfig = VFCCameraConfig.fallback
    private var cachedImageURL: URL?
    private var cachedImage: CIImage?

    func makePixelBuffer(from pool: CVPixelBufferPool) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let err = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &pixelBuffer)
        guard err == kCVReturnSuccess, let pixelBuffer else {
            os_log(.error, "Could not allocate pixel buffer: %{public}d", err)
            return nil
        }

        let frame = makeFrameImage(width: vfcWidth, height: vfcHeight)
        context.render(
            frame,
            to: pixelBuffer,
            bounds: CGRect(x: 0, y: 0, width: vfcWidth, height: vfcHeight),
            colorSpace: colorSpace
        )
        return pixelBuffer
    }

    private func makeFrameImage(width: Int, height: Int) -> CIImage {
        refreshConfigIfNeeded()

        let bounds = CGRect(x: 0, y: 0, width: width, height: height)
        let background = CIImage(color: CIColor(red: 0.04, green: 0.05, blue: 0.06))
            .cropped(to: bounds)

        guard let image = loadCurrentImage() else {
            return placeholderFrame(in: bounds).composited(over: background).cropped(to: bounds)
        }

        let normalized = image.transformed(
            by: CGAffineTransform(translationX: -image.extent.origin.x, y: -image.extent.origin.y)
        )
        let sourceWidth = max(normalized.extent.width, 1)
        let sourceHeight = max(normalized.extent.height, 1)
        let scaleX = CGFloat(width) / sourceWidth
        let scaleY = CGFloat(height) / sourceHeight
        let scale = cachedConfig.fillMode == .fill ? max(scaleX, scaleY) : min(scaleX, scaleY)
        let scaled = normalized.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let x = (CGFloat(width) - scaled.extent.width) / 2
        let y = (CGFloat(height) - scaled.extent.height) / 2
        let positioned = scaled.transformed(by: CGAffineTransform(translationX: x, y: y))

        return positioned.composited(over: background).cropped(to: bounds)
    }

    private func refreshConfigIfNeeded() {
        guard let url = VFCShared.configURL() else {
            cachedConfig = .fallback
            return
        }

        let modifiedDate = (try? FileManager.default
            .attributesOfItem(atPath: url.path)[.modificationDate]) as? Date
        guard modifiedDate != lastConfigModifiedDate else {
            return
        }

        lastConfigModifiedDate = modifiedDate
        guard
            let data = try? Data(contentsOf: url),
            let config = try? JSONDecoder().decode(VFCCameraConfig.self, from: data)
        else {
            cachedConfig = .fallback
            cachedImage = nil
            cachedImageURL = nil
            return
        }

        cachedConfig = config
        cachedImage = nil
        cachedImageURL = nil
    }

    private func loadCurrentImage() -> CIImage? {
        let imageURL = VFCShared.imageURL(fileName: cachedConfig.imageFileName)
        guard imageURL != cachedImageURL else {
            return cachedImage
        }

        cachedImageURL = imageURL
        cachedImage = nil

        guard let imageURL else {
            return nil
        }

        cachedImage = CIImage(
            contentsOf: imageURL,
            options: [.applyOrientationProperty: true]
        )
        return cachedImage
    }

    private func placeholderFrame(in bounds: CGRect) -> CIImage {
        let base = CIImage(color: CIColor(red: 0.02, green: 0.03, blue: 0.04)).cropped(to: bounds)
        let stripeHeight = max(bounds.height * 0.08, 48)
        let topStripe = CIImage(color: CIColor(red: 0.08, green: 0.47, blue: 0.39))
            .cropped(to: CGRect(x: 0, y: bounds.midY - stripeHeight / 2, width: bounds.width, height: stripeHeight))
        let center = CIImage(color: CIColor(red: 0.92, green: 0.98, blue: 0.95))
            .cropped(to: CGRect(x: bounds.midX - 150, y: bounds.midY - 3, width: 300, height: 6))
        return center.composited(over: topStripe.composited(over: base))
    }
}

final class VirtualFaceCamDeviceSource: NSObject, CMIOExtensionDeviceSource {
    private(set) var device: CMIOExtensionDevice!

    private var streamSource: VirtualFaceCamStreamSource!
    private var streamingCounter: UInt32 = 0
    private var timer: DispatchSourceTimer?
    private let timerQueue = DispatchQueue(
        label: "VirtualFaceCam.timerQueue",
        qos: .userInteractive,
        autoreleaseFrequency: .workItem
    )

    private var videoDescription: CMFormatDescription!
    private var bufferPool: CVPixelBufferPool!
    private let renderer = VirtualFaceCamFrameRenderer()

    init(localizedName: String) {
        super.init()

        let deviceID = UUID(uuidString: "9236A8BC-2D98-42FA-8E4F-5E2A88F10101")!
        device = CMIOExtensionDevice(
            localizedName: localizedName,
            deviceID: deviceID,
            legacyDeviceID: nil,
            source: self
        )

        let dimensions = CMVideoDimensions(width: Int32(vfcWidth), height: Int32(vfcHeight))
        CMVideoFormatDescriptionCreate(
            allocator: kCFAllocatorDefault,
            codecType: kCVPixelFormatType_32BGRA,
            width: dimensions.width,
            height: dimensions.height,
            extensions: nil,
            formatDescriptionOut: &videoDescription
        )

        let pixelBufferAttributes: NSDictionary = [
            kCVPixelBufferWidthKey: dimensions.width,
            kCVPixelBufferHeightKey: dimensions.height,
            kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA,
            kCVPixelBufferIOSurfacePropertiesKey: [:] as NSDictionary,
        ]
        CVPixelBufferPoolCreate(kCFAllocatorDefault, nil, pixelBufferAttributes, &bufferPool)

        let frameDuration = CMTime(value: 1, timescale: Int32(vfcFrameRate))
        let streamFormat = CMIOExtensionStreamFormat(
            formatDescription: videoDescription,
            maxFrameDuration: frameDuration,
            minFrameDuration: frameDuration,
            validFrameDurations: nil
        )

        let streamID = UUID(uuidString: "9236A8BC-2D98-42FA-8E4F-5E2A88F10202")!
        streamSource = VirtualFaceCamStreamSource(
            localizedName: "Virtual Face Cam",
            streamID: streamID,
            streamFormat: streamFormat,
            device: device
        )

        do {
            try device.addStream(streamSource.stream)
        } catch {
            fatalError("Failed to add stream: \(error.localizedDescription)")
        }
    }

    var availableProperties: Set<CMIOExtensionProperty> {
        [.deviceTransportType, .deviceModel]
    }

    func deviceProperties(forProperties properties: Set<CMIOExtensionProperty>) throws -> CMIOExtensionDeviceProperties {
        let deviceProperties = CMIOExtensionDeviceProperties(dictionary: [:])
        if properties.contains(.deviceTransportType) {
            deviceProperties.transportType = kIOAudioDeviceTransportTypeVirtual
        }
        if properties.contains(.deviceModel) {
            deviceProperties.model = "Virtual Face Cam"
        }
        return deviceProperties
    }

    func setDeviceProperties(_ deviceProperties: CMIOExtensionDeviceProperties) throws {}

    func startStreaming() {
        guard bufferPool != nil else {
            return
        }

        streamingCounter += 1
        guard timer == nil else {
            return
        }

        let frameDurationSeconds = 1.0 / Double(vfcFrameRate)
        let timer = DispatchSource.makeTimerSource(flags: .strict, queue: timerQueue)
        timer.schedule(deadline: .now(), repeating: frameDurationSeconds, leeway: .milliseconds(2))
        timer.setEventHandler { [weak self] in
            self?.sendFrame()
        }
        self.timer = timer
        timer.resume()
    }

    func stopStreaming() {
        if streamingCounter > 1 {
            streamingCounter -= 1
            return
        }

        streamingCounter = 0
        timer?.cancel()
        timer = nil
    }

    private func sendFrame() {
        guard let pixelBuffer = renderer.makePixelBuffer(from: bufferPool) else {
            return
        }

        var timingInfo = CMSampleTimingInfo()
        timingInfo.presentationTimeStamp = CMClockGetTime(CMClockGetHostTimeClock())
        timingInfo.duration = CMTime(value: 1, timescale: Int32(vfcFrameRate))
        timingInfo.decodeTimeStamp = .invalid

        var sampleBuffer: CMSampleBuffer?
        let err = CMSampleBufferCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            dataReady: true,
            makeDataReadyCallback: nil,
            refcon: nil,
            formatDescription: videoDescription,
            sampleTiming: &timingInfo,
            sampleBufferOut: &sampleBuffer
        )

        guard err == noErr, let sampleBuffer else {
            os_log(.error, "Could not create sample buffer: %{public}d", err)
            return
        }

        streamSource.stream.send(
            sampleBuffer,
            discontinuity: [],
            hostTimeInNanoseconds: UInt64(timingInfo.presentationTimeStamp.seconds * Double(NSEC_PER_SEC))
        )
    }
}

final class VirtualFaceCamStreamSource: NSObject, CMIOExtensionStreamSource {
    private(set) var stream: CMIOExtensionStream!

    private let device: CMIOExtensionDevice
    private let streamFormat: CMIOExtensionStreamFormat

    init(localizedName: String, streamID: UUID, streamFormat: CMIOExtensionStreamFormat, device: CMIOExtensionDevice) {
        self.device = device
        self.streamFormat = streamFormat
        super.init()
        stream = CMIOExtensionStream(
            localizedName: localizedName,
            streamID: streamID,
            direction: .source,
            clockType: .hostTime,
            source: self
        )
    }

    var formats: [CMIOExtensionStreamFormat] {
        [streamFormat]
    }

    var activeFormatIndex: Int = 0

    var availableProperties: Set<CMIOExtensionProperty> {
        [.streamActiveFormatIndex, .streamFrameDuration]
    }

    func streamProperties(forProperties properties: Set<CMIOExtensionProperty>) throws -> CMIOExtensionStreamProperties {
        let streamProperties = CMIOExtensionStreamProperties(dictionary: [:])
        if properties.contains(.streamActiveFormatIndex) {
            streamProperties.activeFormatIndex = 0
        }
        if properties.contains(.streamFrameDuration) {
            streamProperties.frameDuration = CMTime(value: 1, timescale: Int32(vfcFrameRate))
        }
        return streamProperties
    }

    func setStreamProperties(_ streamProperties: CMIOExtensionStreamProperties) throws {
        if let activeFormatIndex = streamProperties.activeFormatIndex {
            self.activeFormatIndex = activeFormatIndex
        }
    }

    func authorizedToStartStream(for client: CMIOExtensionClient) -> Bool {
        true
    }

    func startStream() throws {
        guard let source = device.source as? VirtualFaceCamDeviceSource else {
            fatalError("Unexpected device source: \(String(describing: device.source))")
        }
        source.startStreaming()
    }

    func stopStream() throws {
        guard let source = device.source as? VirtualFaceCamDeviceSource else {
            fatalError("Unexpected device source: \(String(describing: device.source))")
        }
        source.stopStreaming()
    }
}

final class VirtualFaceCamProviderSource: NSObject, CMIOExtensionProviderSource {
    private(set) var provider: CMIOExtensionProvider!
    private var deviceSource: VirtualFaceCamDeviceSource!

    init(clientQueue: DispatchQueue?) {
        super.init()
        provider = CMIOExtensionProvider(source: self, clientQueue: clientQueue)
        deviceSource = VirtualFaceCamDeviceSource(localizedName: "Virtual Face Cam")
        do {
            try provider.addDevice(deviceSource.device)
        } catch {
            fatalError("Failed to add device: \(error.localizedDescription)")
        }
    }

    func connect(to client: CMIOExtensionClient) throws {}

    func disconnect(from client: CMIOExtensionClient) {}

    var availableProperties: Set<CMIOExtensionProperty> {
        [.providerManufacturer]
    }

    func providerProperties(forProperties properties: Set<CMIOExtensionProperty>) throws -> CMIOExtensionProviderProperties {
        let providerProperties = CMIOExtensionProviderProperties(dictionary: [:])
        if properties.contains(.providerManufacturer) {
            providerProperties.manufacturer = "TaeHuiKKIM"
        }
        return providerProperties
    }

    func setProviderProperties(_ providerProperties: CMIOExtensionProviderProperties) throws {}
}
