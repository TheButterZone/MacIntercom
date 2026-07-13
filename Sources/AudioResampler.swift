import Foundation

final class AudioResampler {

    private let ratio: Double

    // Remember where we are in the source stream between callbacks.
    private var sourcePosition: Double = 0.0

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
            return samples
        }

        var output: [Float] = []

        while true {

            let index = Int(sourcePosition)

            if index + 1 >= samples.count {
                break
            }

            let fraction =
                Float(sourcePosition - Double(index))

            let a = samples[index]
            let b = samples[index + 1]

            output.append(
                a + (b - a) * fraction
            )

            sourcePosition += 1.0 / ratio
        }

        // Keep only the fractional remainder for the next callback.
        sourcePosition -= Double(samples.count - 1)

        return output
    }
}
