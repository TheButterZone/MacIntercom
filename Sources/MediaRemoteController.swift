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

import Foundation
import MediaPlayer

final class MediaRemoteController {

    static let shared = MediaRemoteController()

    private var frameworkHandle: UnsafeMutableRawPointer?

    private typealias SendCommandBlock = @convention(c) (UInt32, Any?) -> Bool
    private var sendCommand: SendCommandBlock?

    private init() {
        frameworkHandle = dlopen(
            "/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote",
            RTLD_NOW
        )

        if let handle = frameworkHandle,
            let symbol = dlsym(handle, "MRMediaRemoteSendCommand")
        {
            sendCommand = unsafeBitCast(symbol, to: SendCommandBlock.self)
        } else {
            Logger.error("Couldn't locate MRMediaRemoteSendCommand")
        }
    }

    func play() {
        // Command 0 is kMRPlay
        let success = sendCommand?(0, nil) ?? false
        if !success {
            Logger.error("Failed to send Play command")
        }
    }

    func pause() {
        // Command 1 is kMRPause
        let success = sendCommand?(1, nil) ?? false
        if !success {
            Logger.error("Failed to send Pause command")
        }
    }

    func acquireNowPlaying() {
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = "Intercom Active"
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 0.0
        nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = true

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    func releaseNowPlaying() {
        // Clearing the dictionary relinquishes Now Playing control
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
}
