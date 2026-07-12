import Foundation
import CoreAudio

final class AudioEngine {

    let capture: AudioCapture
    let output: AudioOutput

    init(route: IntercomRoute) {
        self.capture = AudioCapture(device: route.input)
        self.output = AudioOutput(device: route.output)
    }

    func start() {
        capture.start()
        output.start()
    }

}
