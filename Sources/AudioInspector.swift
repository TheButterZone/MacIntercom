import Foundation
import CoreAudio

struct AudioInspector {

    static func inspect() -> String {

        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
	    mElement: kAudioObjectPropertyElementMaster
        )

        var dataSize: UInt32 = 0

        let status = AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &dataSize
        )

        if status != noErr {
            return "AudioObjectGetPropertyDataSize failed: \(status)"
        }

        let count = Int(dataSize) / MemoryLayout<AudioDeviceID>.size

        return "Core Audio reports \(count) audio device(s)."
    }
}
