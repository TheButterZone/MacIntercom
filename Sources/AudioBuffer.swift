import Foundation

final class AudioBuffer {

private var totalWritten = 0
private var totalRead = 0
private var writtenThisSecond = 0
private var readThisSecond = 0
private var statsStarted = false

    private var samples: [Float] = []
    private let lock = NSLock()

    let name: String

    init(name: String = "buffer") {
        self.name = name
if !statsStarted {

    statsStarted = true

    Timer.scheduledTimer(
        withTimeInterval: 1.0,
        repeats: true
    ) { _ in

        self.lock.lock()

        print(
            self.name,
            "writes/sec:",
            self.writtenThisSecond,
            "reads/sec:",
            self.readThisSecond,
            "queued:",
            self.samples.count
        )

        self.writtenThisSecond = 0
        self.readThisSecond = 0

        self.lock.unlock()
    }
}
    }

func write(_ newSamples: [Float]) {

    lock.lock()

    samples.append(contentsOf: newSamples)

totalWritten += newSamples.count

writtenThisSecond += newSamples.count

    lock.unlock()
}

func read(count: Int) -> [Float] {

    lock.lock()
    defer { lock.unlock() }

    let actual = min(count, samples.count)

    let output = Array(samples.prefix(actual))

readThisSecond += output.count

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