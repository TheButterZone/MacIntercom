import Foundation
import CoreAudio
import AudioToolbox

final class AudioCapture {

    let device: AudioDevice

    init(device: AudioDevice) {
        self.device = device
    }

    func start() {

        print("Starting capture:")
        print("  Device: \(device.name)")
        print("  ID: \(device.id)")

    }

}
