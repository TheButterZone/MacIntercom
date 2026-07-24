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

final class TestTone {

    private var callbackCount = 0
    private var phase: Float = 0

    private let frequency: Float
    private let amplitude: Float

    init(
        frequency: Float,
        amplitude: Float
    ) {
        self.frequency = frequency
        self.amplitude = amplitude
    }

    func logConfiguration(name: String) {

        guard DebugFlags.generateTestTone else {
            return
        }

        Logger.info(
            """
            🎵 TEST TONE INIT
            device=🔊 \(name)
            frequency=\(frequency)
            amplitude=\(amplitude)
            """
        )
    }

    func fill(
        _ samples: UnsafeMutablePointer<Float>,
        count: Int,
        sampleRate: Float,
        channels: Int
    ) {

        callbackCount += 1

        let increment =
            2.0 * Float.pi * frequency / sampleRate

        if channels == 1 {

            for i in 0..<count {

                samples[i] = sin(phase) * amplitude

                phase += increment

                if phase >= 2.0 * Float.pi {
                    phase -= 2.0 * Float.pi
                }
            }

        } else {

            let frameCount = count / channels

            for frame in 0..<frameCount {

                let sample = sin(phase) * amplitude

                for channel in 0..<channels {
                    samples[
                        frame * channels + channel
                    ] = sample
                }

                phase += increment

                if phase >= 2.0 * Float.pi {
                    phase -= 2.0 * Float.pi
                }
            }
        }

        if DebugFlags.showPerformanceStats && callbackCount % 100 == 0 {

            DebugTelemetry.output.log(
                """
                TEST TONE
                frequency=\(frequency)
                amplitude=\(amplitude)
                samples=\(count)
                channels=\(channels)
                """
            )
        }
    }
}
