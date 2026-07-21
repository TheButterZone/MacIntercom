import Foundation

final class TestTone {

    private var callbackCount: Int = 0
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

    func logConfiguration(
        name: String
    ) {
        print(
            "AUDIO OUTPUT INIT",
            name,
            "tone",
            frequency
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

                samples[i] =
                    sin(phase) * amplitude

                phase += increment

                if phase >= 2.0 * Float.pi {
                    phase -= 2.0 * Float.pi
                }
            }

        } else {

            let frameCount = count / channels

            for frame in 0..<frameCount {

                let sample =
                    sin(phase) * amplitude

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


        if callbackCount % 100 == 0 {

            print(
                "TEST TONE",
                "frequency:",
                frequency,
                "samples:",
                count,
                "channels:",
                channels
            )
        }
    }
}