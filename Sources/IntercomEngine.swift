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

final class IntercomEngine {

    private let buffer: AudioBuffer

    let capture: AudioCapture
    private let output: AudioOutput

    private let primeBuffer: Bool

    private var started = false

    init(
        name: String,
        route: IntercomRoute,
        shouldDownsample: Bool,
        primeBuffer: Bool
    ) {

        self.primeBuffer = primeBuffer

        buffer = AudioBuffer(name: name)

        DebugTelemetry.capture.log(
            """
            ENGINE=\(name)
            INPUT=\(route.input.name)
            INPUT_RATE=\(route.input.sampleRate)
            OUTPUT=\(route.output.name)
            OUTPUT_RATE=\(route.output.sampleRate)
            DOWNSAMPLE=\(shouldDownsample)
            PRIME=\(primeBuffer)
            """
        )

        capture = AudioCapture(
            device: route.input,
            outputDevice: route.output,
            audioBuffer: buffer,
            shouldDownsample: shouldDownsample
        )

        output = AudioOutput(
            device: route.output,
            audioBuffer: buffer
        )
    }


    func start() {

        if started {

DebugTelemetry.capture.log(
    """
    ENGINE ALREADY STARTED
    output=\(output.device.name)
    """
)

            return
        }

        started = true

Logger.info(
    "Intercom  🎤 \(capture.device.name) → 🔊 \(output.device.name)  🎵 tone=\(DebugFlags.generateTestTone)"
)


        if DebugFlags.generateTestTone {

Logger.info(
    "🎵 Tone test  🔊 \(output.device.name)"
)

            output.start()
            return
        }


        capture.start()


        if primeBuffer {

            DispatchQueue.global(qos: .userInitiated).async {

                let targetSamples = 512

                while self.buffer.sampleCount() < targetSamples {
                    usleep(10_000)
                }

DebugTelemetry.capture.log(
    """
    AUDIO FLOW START
    output=\(self.output.device.name)
    queued=\(self.buffer.sampleCount())
    """
)

Logger.info(
    "🔄  Audio flowing  🎤 \(self.capture.device.name) → 🔊 \(self.output.device.name)"
)

                self.output.start()
            }

        } else {

            output.start()

        }
    }
}