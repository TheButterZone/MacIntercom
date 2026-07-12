import Foundation
import CoreAudio

struct AudioDevice {

    let id: AudioDeviceID
    let uid: String
    let name: String
    let transport: String
    let inputChannels: Int
    let outputChannels: Int

}
