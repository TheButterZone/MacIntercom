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

final class ComputerToBluetoothEngine {

    private let buffer =
        AudioBuffer(name: "Computer→BT")

    private let capture: AudioCapture
    private let output: AudioOutput

    init(route: IntercomRoute) {

        capture = AudioCapture(
            device: route.input,
            outputDevice: route.output,
            audioBuffer: buffer,
            shouldDownsample: true
        )

        output = AudioOutput(
            device: route.output,
            audioBuffer: buffer
        )
    }

    func start() {

        capture.start()
        output.start()
    }
}
