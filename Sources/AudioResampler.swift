import Foundation

final class AudioResampler {

    init() {
    }

    func process(
	_ samples: [Float]
    ) -> [Float] {

	var output: [Float] = []

	output.reserveCapacity(
	    samples.count * 12
	)

	for sample in samples {

            for _ in 0..<6 {

		output.append(sample)
		output.append(sample)

	    }
	}

	return output
    }

}