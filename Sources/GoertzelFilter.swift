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

struct GoertzelFilter {
    let targetFrequency: Float
    let sampleRate: Float

    private let coeffTarget: Float
    
    public static let standardTones: [Float] = [
        67.0, 69.3, 71.9, 74.4, 77.0, 79.7,
        82.5, 85.4, 88.5, 91.5, 94.8, 97.4,
        100.0, 103.5, 107.2, 110.9, 114.8,
        118.8, 123.0, 127.3, 131.8, 136.5,
        141.3, 146.2, 151.4, 156.7, 159.8,
        162.2, 165.5, 167.9, 171.3, 173.8,
        177.3, 179.9, 183.5, 186.2, 189.9,
        192.8, 196.6, 199.5, 203.5, 206.5,
        210.7, 218.1, 225.7, 229.1, 233.6,
        241.8, 250.3, 254.1,
    ]

    static func validate(_ frequency: Float) -> Float? {
        return standardTones.first { abs($0 - frequency) < 0.01 }
    }

    init(targetFrequency: Float, sampleRate: Float = 8000.0) {
        guard let _ = Self.standardTones.firstIndex(where: { abs($0 - targetFrequency) < 0.01 }) else {
            fatalError("Unsupported CTCSS frequency")
        }

        self.targetFrequency = targetFrequency
        self.sampleRate = sampleRate
        self.coeffTarget = 2.0 * cos((2.0 * .pi * targetFrequency) / sampleRate)
    }

    func evaluate(samples: [Float]) -> (targetPower: Float, snr: Float) {
        guard !samples.isEmpty else { return (0.0, 0.0) }

        var mean: Float = 0.0
        for sample in samples { mean += sample }
        mean /= Float(samples.count)

        var normalizedSamples = [Float]()
        normalizedSamples.reserveCapacity(samples.count)
        var totalPowerSum: Float = 0.0

        for sample in samples {
            let norm = sample - mean
            normalizedSamples.append(norm)
            totalPowerSum += norm * norm
        }

        let totalPower = totalPowerSum / Float(samples.count)
        guard totalPower > 0.0000001 else { return (0.0, 0.0) }

        var s1: Float = 0.0
        var s2: Float = 0.0

        for sample in normalizedSamples {
            let s0 = sample + (coeffTarget * s1) - s2
            s2 = s1
            s1 = s0
        }

        let rawPower = (s1 * s1) + (s2 * s2) - (coeffTarget * s1 * s2)
        let normalization = Float(samples.count * samples.count)
        let targetP = max(0.0, rawPower / normalization)

        let snr = targetP / totalPower

        return (targetPower: targetP, snr: snr)
    }
}