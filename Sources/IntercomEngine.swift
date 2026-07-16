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
