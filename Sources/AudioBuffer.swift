import Foundation

final class AudioBuffer {

    private var totalWritten = 0
    private var totalRead = 0
    private var writtenThisSecond = 0
    private var readThisSecond = 0
    private var statsStarted = false

    private var samples: [Float] = []
    private var readIndex: Int = 0

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

                if DebugFlags.showPerformanceStats {

                    Logger.performance(
                        "\(self.name) writes/sec: \(self.writtenThisSecond) reads/sec: \(self.readThisSecond) queued: \(self.samples.count)"
                    )

                }

                self.writtenThisSecond = 0
                self.readThisSecond = 0

                self.lock.unlock()
            }
        }
    }

func write(_ newSamples: [Float]) {

    lock.lock()

    samples.append(contentsOf: newSamples)

    let maxQueued = 12288

    if samples.count - readIndex > maxQueued {

        readIndex = samples.count - maxQueued
    }

    totalWritten += newSamples.count
    writtenThisSecond += newSamples.count

    lock.unlock()
}

func read(count: Int) -> [Float] {

    lock.lock()
    defer { lock.unlock() }

    let available = samples.count - readIndex

    let actual = min(
        count,
        available
    )

    let start = readIndex
    let end = start + actual

    let output = Array(
        samples[start..<end]
    )

    readIndex += actual

    readThisSecond += output.count
    totalRead += output.count

    if readIndex > 4096 &&
       readIndex > samples.count / 2 {

        samples.removeFirst(readIndex)
        readIndex = 0
    }

    return output
}

func sampleCount() -> Int {

    lock.lock()
    defer { lock.unlock() }

    return samples.count - readIndex
}
}