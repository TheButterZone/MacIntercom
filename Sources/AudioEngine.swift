import Foundation
import CoreAudio

final class AudioEngine {

    let capture: AudioCapture

    init(route: IntercomRoute) {
        self.capture = AudioCapture(device: route.input)
    }

    func start() {
        capture.start()
    }

}
