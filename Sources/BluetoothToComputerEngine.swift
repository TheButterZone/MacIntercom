import Foundation

final class BluetoothToComputerEngine {

    private let buffer =
        AudioBuffer(name: "BT→Computer")

    private let capture: AudioCapture
    private let output: AudioOutput

    init(route: IntercomRoute) {

capture = AudioCapture(
    device: route.input,
    audioBuffer: buffer
)

        output = AudioOutput(
            device: route.output,
            audioBuffer: buffer
        )
    }

func start() {

    print("Bluetooth engine: starting CAPTURE")
    capture.start()

    sleep(5)

    print("Bluetooth engine: starting OUTPUT")
    output.start()
}
}
