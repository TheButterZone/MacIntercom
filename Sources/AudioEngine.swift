import Foundation
import CoreAudio

final class AudioEngine {

    let inputDevice: AudioDevice

    init(route: IntercomRoute) {
        self.inputDevice = route.input
    }

    func start() {

        print("Opening input device:")
        print("  \(inputDevice.name)")
        print("  Device ID: \(inputDevice.id)")

    }

}
