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

final class MediaKeyInterceptor {

    static let shared = MediaKeyInterceptor()

    weak var conversationController: ConversationController?

    private init() {}

    func startIntercepting() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.nextTrackCommand.isEnabled = false
        commandCenter.previousTrackCommand.isEnabled = false

        commandCenter.togglePlayPauseCommand.isEnabled = true

        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in

            Logger.info("Bluetooth AVRCP toggle")

            self?.conversationController?.toggle(
                trigger: .bluetoothButton
            )

            return .success
        }
    }
}
