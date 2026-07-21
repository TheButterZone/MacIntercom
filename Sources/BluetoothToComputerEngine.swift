import Foundation

final class BluetoothToComputerEngine {

    private let buffer =
        AudioBuffer(name: "BT→Computer")

    private let capture: AudioCapture
    private let output: AudioOutput

    init(route: IntercomRoute) {

capture = AudioCapture(
    device: route.input,
    outputDevice: route.output,
    audioBuffer: buffer,
    shouldDownsample: false
)

        output = AudioOutput(
            device: route.output,
            audioBuffer: buffer
        )
    }

func start() {

    capture.start()

    // Wait until we have enough audio buffered that the
    // output callback won't immediately underrun.

    while buffer.sampleCount() < 4096 {

        usleep(1000) // 1 ms
    }

DebugTelemetry.output.log(
    """
    AUDIO READY
    🎤 \(capture.device.name) → 🔊 \(output.device.name)
    queued=\(buffer.sampleCount())
    """
)

    output.start()
}
}
