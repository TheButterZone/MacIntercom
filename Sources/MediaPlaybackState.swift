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

final class MediaPlaybackState {

    static let shared = MediaPlaybackState()

    private init() {}

    private(set) var isPlaying = false {

        didSet {

            guard isPlaying != oldValue else {
                return
            }

            DebugTelemetry.capture.log("Playback is now \(isPlaying ? "PLAYING" : "PAUSED")")

            onPlaybackChanged?(isPlaying)

        }

    }

    private(set) var title: String?

    private(set) var artist: String?

    var onPlaybackChanged: ((Bool) -> Void)?

    func update(
        playing: Bool,
        title: String?,
        artist: String?
    ) {

        self.title = title

        self.artist = artist

        self.isPlaying = playing

    }

}
