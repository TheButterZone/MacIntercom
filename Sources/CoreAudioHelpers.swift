import Foundation
import CoreAudio

enum CoreAudioHelpers {

    static func address(
        selector: AudioObjectPropertySelector,
        scope: AudioObjectPropertyScope,
        element: AudioObjectPropertyElement = kAudioObjectPropertyElementMaster
    ) -> AudioObjectPropertyAddress {

        AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: scope,
            mElement: element
        )
    }
}
