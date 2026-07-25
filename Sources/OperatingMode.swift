import Foundation

enum OperatingMode {
    case mediaAware
    case standalone
    case testTone
}

struct AppConfiguration {
    static var mode: OperatingMode = .mediaAware
    
    static let computerOutputToneFrequency: Float = 220
    static let bluetoothOutputToneFrequency: Float = 440
    static let testToneAmplitude: Float = 0.25
}