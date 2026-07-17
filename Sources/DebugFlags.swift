import Foundation

enum DebugFlags {

    // MARK: - Device startup

    static let enableComputerCapture  = true
    static let enableComputerOutput   = true
    static let enableBluetoothCapture = true
    static let enableBluetoothOutput  = true

    // MARK: - Audio processing

    static let enableAGC          = true
    static let enableDownsampling = true
    static let enableUpsampling   = true

    // MARK: - Diagnostics

    static let logDeviceStartup = true
    static let logBufferDepth   = false
    static let logLevels        = false
    static let logCallbacks     = false
    static let logMediaRemote   = true
    static let showPerformanceStats = false

    // MARK: - Test tools

    static let generateTestTone = false

}