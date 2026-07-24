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

final class ConversationController {

    enum Trigger {
        case bluetoothButton
        case app
    }

    private(set) var state: ConversationState = .idle {
        didSet {
            guard state != oldValue else {
                return
            }

            DebugTelemetry.capture.log(
                "Conversation state: \(oldValue) → \(state)"
            )

            onStateChanged?(state)
        }
    }

    var onStateChanged: ((ConversationState) -> Void)?
    var onMuteStateChanged: ((Bool) -> Void)?

    init() {
        guard !DebugFlags.generateTestTone else { return }

        MediaPlaybackState.shared.onPlaybackChanged = {
            [weak self] playing in
            self?.playbackChanged(playing)
        }
    }

    func syncInitialState() {
        guard !DebugFlags.generateTestTone else { return }

        let isPlaying = MediaPlaybackState.shared.isPlaying
        
        Logger.info(
            "Initial playback state on run: \(isPlaying ? "PLAYING" : "PAUSED")"
        )

        applyMuteState(isPlaying)
    }

    private func playbackChanged(
        _ playing: Bool
    ) {
        DebugTelemetry.capture.log("Playback changed: \(playing ? "ACTIVE" : "INACTIVE")")

        applyMuteState(playing)
    }

    private func applyMuteState(
        _ isPlaying: Bool
    ) {
        guard !DebugFlags.generateTestTone else { return }

        if isPlaying {
            Logger.info(
                "Media is playing → Muting intercom audio buffers."
            )
            onMuteStateChanged?(true)  // Mute / 0-buffer
            state = .idle
        } else {
            Logger.info(
                "Media is paused → Unmuting intercom audio buffers."
            )
            onMuteStateChanged?(false)  // Unmute
            state = .active
        }
    }

    func begin(
        trigger: Trigger
    ) {
        applyMuteState(false)
    }

    func end(
        trigger: Trigger
    ) {
        applyMuteState(true)
    }

    func toggle(
        trigger: Trigger
    ) {
        let currentPlaying = MediaPlaybackState.shared.isPlaying
        applyMuteState(!currentPlaying)
    }
}
