import Foundation

final class TestTone {

    private var phase: Float = 0

var frequency: Float = 440
var amplitude: Float = 0.25

func fill(
    _ samples: UnsafeMutablePointer<Float>,
    count: Int,
    sampleRate: Float
) {

    let increment =
        2.0 * Float.pi * frequency / sampleRate

    let frameCount = count / 2

    for frame in 0..<frameCount {

        let sample = sin(phase) * amplitude

if frame < 16 {
    print(sample)
}

        let index = frame * 2

        samples[index] = sample
        samples[index + 1] = sample

        phase += increment

        if phase >= 2.0 * Float.pi {
            phase -= 2.0 * Float.pi
        }
    }
}

}
