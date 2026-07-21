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