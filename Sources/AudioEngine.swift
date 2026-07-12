import Foundation
import CoreAudio

final class AudioEngine {

    let capture: AudioCapture
    let output: AudioOutput
    let audioBuffer: AudioBuffer

    init(route: IntercomRoute) {

        let buffer = AudioBuffer()

        self.audioBuffer = buffer
        self.capture = AudioCapture(
            device: route.input,
            audioBuffer: buffer
        )
        self.output = AudioOutput(device: route.output)
    }

    func start() {
        capture.start()
        output.start()
    }

}
