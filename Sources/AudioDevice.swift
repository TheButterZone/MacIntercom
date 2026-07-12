import Foundation
import CoreAudio

struct AudioDevice {

    let id: AudioDeviceID
    let name: String
    let inputChannels: Int
    let outputChannels: Int

}
