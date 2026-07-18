import Foundation

final class IntercomEngine {

    private let buffer: AudioBuffer

    let capture: AudioCapture
    private let output: AudioOutput

    private let primeBuffer: Bool

    init(
        name: String,
        route: IntercomRoute,
        shouldDownsample: Bool,
        primeBuffer: Bool
    ) {

        self.primeBuffer = primeBuffer

        buffer = AudioBuffer(name: name)

DebugTelemetry.capture.log(
    """
ENGINE=\(name)
INPUT=\(route.input.name)
INPUT_RATE=\(route.input.sampleRate)
OUTPUT=\(route.output.name)
OUTPUT_RATE=\(route.output.sampleRate)
DOWNSAMPLE=\(shouldDownsample)
"""
)

        capture = AudioCapture(
            device: route.input,
            outputDevice: route.output,
            audioBuffer: buffer,
            shouldDownsample: shouldDownsample
        )

        output = AudioOutput(
            device: route.output,
            audioBuffer: buffer
        )
    }

    func start() {

        Logger.audio("Starting capture")
        capture.start()
	output.start()
    }
}
