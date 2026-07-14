import Foundation
import CoreAudio

final class AudioEngine {

    private let bluetoothBuffer =
        AudioBuffer(name: "Computer→BT TEST")

    private let computerCapture: AudioCapture
    private let bluetoothOutput: AudioOutput

    init(
        bluetoothRoute: IntercomRoute,
        computerRoute: IntercomRoute
    ) {

computerCapture = AudioCapture(
    device: computerRoute.input,
    outputDevice: computerRoute.output,
    audioBuffer: bluetoothBuffer,
    shouldDownsample: true
)

        bluetoothOutput = AudioOutput(
            device: computerRoute.output,
            audioBuffer: bluetoothBuffer
        )

        print(
            "TEST buffer:",
            ObjectIdentifier(bluetoothBuffer)
        )

        print(
            "TEST path:",
            computerRoute.input.name,
            "→",
            computerRoute.output.name
        )
    }

    func start() {

        computerCapture.start()

        bluetoothOutput.start()
    }
}