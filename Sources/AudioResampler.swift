import Foundation

final class AudioResampler {

    private var previousLastSample: Float?

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
            return []
        }

        var input = samples

        if let last = previousLastSample {
            input.insert(last, at: 0)
        }

        previousLastSample = samples.last

        var output: [Float] = []

        while sourcePosition < Double(input.count - 1) {

            let index = Int(sourcePosition)

            let fraction =
                Float(sourcePosition - Double(index))

            let a = input[index]
            let b = input[index + 1]

            output.append(
                a + (b - a) * fraction
            )

            sourcePosition += 1.0 / ratio
        }

        sourcePosition -= Double(input.count - 1)

        return output
    }
}