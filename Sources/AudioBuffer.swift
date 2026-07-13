import Foundation

final class AudioBuffer {

private var totalWritten = 0
private var totalRead = 0

    private var samples: [Float] = []
    private let lock = NSLock()

    let name: String

    init(name: String = "buffer") {
        self.name = name
    }

func write(_ newSamples: [Float]) {

    lock.lock()

    if !newSamples.isEmpty {

var peak: Float = 0

for sample in newSamples {
    let m = abs(sample)
    if m > peak {
        peak = m
    }
}

print(
    name,
    "WRITE peak:",
    peak,
    "count:",
    newSamples.count
)
    }

    samples.append(contentsOf: newSamples)

totalWritten += newSamples.count

if totalWritten % 50000 < newSamples.count {

    print(
        name,
        "TOTAL written:",
        totalWritten,
        "TOTAL read:",
        totalRead,
        "difference:",
        totalWritten - totalRead
    )
}

    lock.unlock()
}

func read(count: Int) -> [Float] {

    lock.lock()
    defer { lock.unlock() }

    let actual = min(count, samples.count)

    let output = Array(samples.prefix(actual))

    if !output.isEmpty {

var peak: Float = 0

for sample in output {
    let m = abs(sample)
    if m > peak {
        peak = m
    }
}

print(
    name,
    "READ peak:",
    peak,
    "count:",
    output.count
)
    }

    samples.removeFirst(actual)

totalRead += output.count
    return output
}

    func sampleCount() -> Int {

        lock.lock()
        defer { lock.unlock() }

        return samples.count
    }
}