import Foundation
import CoreAudio

struct AudioDevice {

    let id: AudioDeviceID
    let uid: String
    let name: String
    let transport: String
    let inputChannels: Int
    let outputChannels: Int
    let sampleRate: Double

}

extension AudioDevice {

    func printInputStreams() {

        var address = CoreAudioHelpers.address(
            selector: kAudioDevicePropertyStreams,
            scope: kAudioDevicePropertyScopeInput
        )

        var size: UInt32 = 0

        var status = AudioObjectGetPropertyDataSize(
            id,
            &address,
            0,
            nil,
            &size
        )

        if status != noErr {
            Logger.device(
                "Couldn't query input streams: \(status)"
            )
            return
        }

        let count = Int(size) /
            MemoryLayout<AudioObjectID>.size

        var streams = [AudioObjectID](
            repeating: 0,
            count: count
        )

        status = AudioObjectGetPropertyData(
            id,
            &address,
            0,
            nil,
            &size,
            &streams
        )

        if status != noErr {
            Logger.device(
                "Couldn't read input streams: \(status)"
            )
            return
        }

        Logger.device("Input streams:")

        for stream in streams {
            Logger.device(
                "  Stream ID: \(stream)"
            )
        }
    }


    func printAvailableFormats(
        for streamID: AudioObjectID
    ) {

        var address = CoreAudioHelpers.address(
            selector: kAudioStreamPropertyAvailablePhysicalFormats,
            scope: kAudioObjectPropertyScopeGlobal
        )

        var size: UInt32 = 0

        var status = AudioObjectGetPropertyDataSize(
            streamID,
            &address,
            0,
            nil,
            &size
        )

        guard status == noErr else {
            Logger.device(
                "Couldn't query available formats: \(status)"
            )
            return
        }

        let count = Int(size) /
            MemoryLayout<AudioStreamRangedDescription>.size

        var formats = Array(
            repeating: AudioStreamRangedDescription(),
            count: count
        )

        status = AudioObjectGetPropertyData(
            streamID,
            &address,
            0,
            nil,
            &size,
            &formats
        )

        guard status == noErr else {
            Logger.device(
                "Couldn't read available formats: \(status)"
            )
            return
        }

        Logger.device("Available formats:")

        for format in formats {

            let f = format.mFormat

            Logger.device(
                "  \(f.mSampleRate) Hz, " +
                "\(f.mChannelsPerFrame) ch, " +
                "\(f.mBitsPerChannel)-bit, " +
                "flags \(f.mFormatFlags)"
            )

            Logger.device(
                "    sample-rate range: " +
                "\(format.mSampleRateRange.mMinimum)..." +
                "\(format.mSampleRateRange.mMaximum)"
            )
        }
    }
}