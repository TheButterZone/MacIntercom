import Foundation

final class AudioResampler {

    init() {
    }

func process(
    _ samples: [Float]
) -> [Float] {

    guard !samples.isEmpty else {
        return []
    }

    var output: [Float] = []

    output.reserveCapacity(
        samples.count * 12
    )

    for i in 0..<(samples.count - 1) {

        let a = samples[i]
        let b = samples[i + 1]

        for step in 0..<6 {

            let t = Float(step) / 6.0

            let sample =
                a + (b - a) * t

            output.append(sample)
            output.append(sample)
        }
    }

    let last = samples.last!

    for _ in 0..<6 {
        output.append(last)
        output.append(last)
    }

    return output
}

}