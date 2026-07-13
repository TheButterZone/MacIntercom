import Foundation

final class ComputerToBluetoothEngine {

    private let buffer =
        AudioBuffer(name: "Computer→BT")

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

        capture.start()
        output.start()
    }
}
