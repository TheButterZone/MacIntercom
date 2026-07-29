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

    private var position: Float = 0.0
    private var history: [Float] = [0.0, 0.0]

    init(
        inputSampleRate: Double,
        outputSampleRate: Double
    ) {
        self.inputSampleRate = Float(inputSampleRate)
        self.outputSampleRate = Float(outputSampleRate)

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

        var working = history
        working.append(contentsOf: samples)

        var output: [Float] = []
        let estimatedCount = Int(Float(samples.count) / ratio) + 16
        output.reserveCapacity(estimatedCount)

        var pos = position
        let workingCount = working.count

        while Int(pos) + 2 < workingCount {
            let index = Int(pos)
            let mu = pos - Float(index)

            let y0 = working[max(0, index - 1)]
            let y1 = working[index]
            let y2 = working[index + 1]
            let y3 = working[min(workingCount - 1, index + 2)]

            let c0 = y1
            let c1 = 0.5 * (y2 - y0)
            let c2 = y0 - 2.5 * y1 + 2.0 * y2 - 0.5 * y3
            let c3 = 0.5 * (y3 - y0) + 1.5 * (y1 - y2)

            let sample = ((c3 * mu + c2) * mu + c1) * mu + c0
            output.append(sample)

            pos += ratio
        }

        if samples.count >= 2 {
            history = [samples[samples.count - 2], samples[samples.count - 1]]
        } else if !samples.isEmpty {
            history = [history[1], samples[samples.count - 1]]
        }

        let consumedFrames = Int(pos)
        pos -= Float(consumedFrames)
        position = max(0, pos)

        return output
    }

    func reset() {
        position = 0.0
        history = [0.0, 0.0]
    }
}