import Foundation

final class TestTone {

    private var generatedSamples: Int = 0
    private var callbackCount: Int = 0

    private var phase: Float = 0

    var frequency: Float = 440
    var amplitude: Float = 0.25

    func fill(
        _ samples: UnsafeMutablePointer<Float>,
        count: Int,
        sampleRate: Float
    ) {

        callbackCount += 1

        let increment =
            2.0 * Float.pi * frequency / sampleRate

        let frameCount = count / 2

        generatedSamples += frameCount

        for frame in 0..<frameCount {

            let sample = sin(phase) * amplitude

            let index = frame * 2

            samples[index] = sample
            samples[index + 1] = sample

            phase += increment

            if phase >= 2.0 * Float.pi {
                phase -= 2.0 * Float.pi
            }
        }

        if callbackCount % 100 == 0 {

            print(
                "TEST TONE:",
                "callbacks:",
                callbackCount,
                "samples:",
                generatedSamples,
                "frequency:",
                frequency,
                "amplitude:",
                amplitude
            )

        }
    }

}