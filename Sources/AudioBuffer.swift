import Foundation

final class AudioBuffer {

    private var samples: [Float] = []
    private let lock = NSLock()

    func write(_ newSamples: [Float]) {
        lock.lock()
        samples.append(contentsOf: newSamples)
        lock.unlock()
    }

    func read(count: Int) -> [Float] {
        lock.lock()
        defer {
            lock.unlock()
        }

        let amount = min(count, samples.count)

        let result = Array(samples.prefix(amount))

        samples.removeFirst(amount)

        return result
    }

    func sampleCount() -> Int {
        lock.lock()
        defer {
            lock.unlock()
        }

        return samples.count
    }
}
