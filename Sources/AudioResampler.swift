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

final class AudioResampler {

    private let ratio: Double

    init(
        inputSampleRate: Double,
        outputSampleRate: Double
    ) {
        ratio = outputSampleRate / inputSampleRate
    }

    func process(
        _ samples: [Float]
    ) -> [Float] {

        guard samples.count >= 2 else {
            return []
        }

        let outputCount = Int(
            Double(samples.count) * ratio
        )

        var output: [Float] = []
        output.reserveCapacity(outputCount)

        for i in 0..<outputCount {

            let position =
                Double(i) / ratio

            let index = Int(position)

            let fraction =
                Float(position - Double(index))

            if index + 1 < samples.count {

                let a = samples[index]
                let b = samples[index + 1]

                output.append(
                    a + (b - a) * fraction
                )

            } else {

                output.append(
                    samples[index]
                )
            }
        }

        return output
    }
}
