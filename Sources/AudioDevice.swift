//
// MacIntercom
// Copyright (C) 2026 TheButterZone
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
// See the GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see:
// https://www.gnu.org/licenses/
//

import CoreAudio
import Foundation

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

        let count = Int(size) / MemoryLayout<AudioObjectID>.size

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

        let count = Int(size) / MemoryLayout<AudioStreamRangedDescription>.size

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
                "  \(f.mSampleRate) Hz, " + "\(f.mChannelsPerFrame) ch, "
                    + "\(f.mBitsPerChannel)-bit, " + "flags \(f.mFormatFlags)"
            )

            Logger.device(
                "    sample-rate range: " + "\(format.mSampleRateRange.mMinimum)..."
                    + "\(format.mSampleRateRange.mMaximum)"
            )
        }
    }
}
