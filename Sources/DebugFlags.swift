import Foundation

enum DebugFlags {

    // MARK: - Device startup

    static let enableComputerCapture  = false
    static let enableComputerOutput   = true
    static let enableBluetoothCapture = false
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
    static let bluetoothDebug = false
    static let audioTelemetry = true

    // MARK: - Test tools

    static let generateTestTone = true
    static let computerOutputToneFrequency: Float = 220
    static let bluetoothOutputToneFrequency: Float = 440
    static let testToneAmplitude: Float = 0.25

}