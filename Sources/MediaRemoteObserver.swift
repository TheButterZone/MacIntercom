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

import Dispatch
import Foundation

final class MediaRemoteObserver {

    static let shared = MediaRemoteObserver()

    private var frameworkHandle: UnsafeMutableRawPointer?

    private typealias IsPlayingBlock =
        @convention(block) (Bool) -> Void

    private typealias GetIsPlaying =
        @convention(c)
    (
        DispatchQueue,
        @escaping IsPlayingBlock
    ) -> Void

    private var getIsPlaying: GetIsPlaying?

    private init() {}

    func start() {
        guard !DebugFlags.generateTestTone else { return }

        frameworkHandle = dlopen(
            "/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote",
            RTLD_NOW
        )

        guard let frameworkHandle = frameworkHandle else {
            Logger.error("Couldn't load MediaRemote.framework")
            return
        }

        guard
            let symbol = dlsym(
                frameworkHandle,
                "MRMediaRemoteGetNowPlayingApplicationIsPlaying"
            )
        else {
            Logger.error("Couldn't locate MRMediaRemoteGetNowPlayingApplicationIsPlaying")
            return
        }

        getIsPlaying = unsafeBitCast(
            symbol,
            to: GetIsPlaying.self
        )

        let semaphore = DispatchSemaphore(value: 0)

        getIsPlaying?(DispatchQueue.global()) { playing in
            MediaPlaybackState.shared.update(
                playing: playing,
                title: nil,
                artist: nil
            )
            semaphore.signal()
        }

        _ = semaphore.wait(timeout: .now() + 1.0)

        Timer.scheduledTimer(
            withTimeInterval: 0.5,
            repeats: true
        ) { [weak self] _ in
            self?.poll()
        }
    }

    private func poll() {

        guard let getIsPlaying = getIsPlaying else {
            return
        }

        getIsPlaying(.main) { playing in

            MediaPlaybackState.shared.update(
                playing: playing,
                title: nil,
                artist: nil
            )

        }
    }
}
