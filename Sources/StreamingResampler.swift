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

final class StreamingResampler {

    private let inputSampleRate: Float
    private let outputSampleRate: Float

    private let ratio: Float

    private var position: Float = 0

    init(
        inputSampleRate: Double,
        outputSampleRate: Double
    ) {

        self.inputSampleRate = Float(inputSampleRate)
        self.outputSampleRate = Float(outputSampleRate)

        // Ratio of input frames per output frame (e.g., 16000 / 48000 = 0.333)
        if self.outputSampleRate > 0 {
            self.ratio = self.inputSampleRate / self.outputSampleRate
        } else {
            self.ratio = 1.0
        }
    }

    func process(
        _ samples: [Float]
    ) -> [Float] {

        guard !samples.isEmpty, ratio > 0 else {
            return samples
        }

        var output: [Float] = []
        
        // Reserve capacity for output buffer (e.g. 16kHz -> 48kHz expands ~3x)
        let estimatedCount = Int(Float(samples.count) / ratio) + 16
        output.reserveCapacity(estimatedCount)

        var pos = position
        let sampleCount = samples.count

        while Int(pos) + 1 < sampleCount {
            let index = Int(pos)
            let fraction = pos - Float(index)

            let s0 = samples[index]
            let s1 = samples[index + 1]

            // Linear interpolation between frames
            let interpolated = s0 + (s1 - s0) * fraction
            output.append(interpolated)

            pos += ratio
        }

        // Carry over fractional position to the next buffer callback
        position = pos - Float(sampleCount)
        if position < 0 {
            position = 0
        }

        return output
    }

    func reset() {
        position = 0
    }
}