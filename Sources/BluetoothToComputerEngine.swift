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

    print("Bluetooth engine: starting CAPTURE")
    capture.start()

    // Wait until we have enough audio buffered that the
    // output callback won't immediately underrun.

    while buffer.sampleCount() < 4096 {

        usleep(1000) // 1 ms
    }

    print(
        "Bluetooth buffer primed:",
        buffer.sampleCount(),
        "samples"
    )

    print("Bluetooth engine: starting OUTPUT")
    output.start()
}
}
