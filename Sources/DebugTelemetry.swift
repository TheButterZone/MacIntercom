import Foundation

final class DebugTelemetry {

    static let shared = DebugTelemetry()

    private let queue = DispatchQueue(
        label: "MacIntercom.DebugTelemetry",
        qos: .utility
    )

    private var timer: DispatchSourceTimer?

    private var lines: [String] = []

    private let outputURL: URL

    private init() {

        let executableDirectory =
            URL(fileURLWithPath: CommandLine.arguments[0])
                .deletingLastPathComponent()

        let repositoryRoot =
            executableDirectory.deletingLastPathComponent()

        outputURL =
            repositoryRoot.appendingPathComponent(
                "MacIntercom.telemetry.log"
            )
    }

    func start() {

        guard DebugFlags.audioTelemetry else {
            return
        }

        if timer != nil {
            return
        }

        try? FileManager.default.removeItem(at: outputURL)

        timer = DispatchSource.makeTimerSource(
            queue: queue
        )

        timer?.schedule(
            deadline: .now() + 1,
            repeating: 1
        )

        timer?.setEventHandler { [weak self] in
            self?.flush()
        }

        timer?.resume()
    }

    func stop() {

        timer?.cancel()
        timer = nil

        flush()
    }

    func record(_ text: String) {

        guard DebugFlags.audioTelemetry else {
            return
        }

        queue.async {

            self.lines.append(text)

            self.flush()
        }
    }

    private func flush() {

        guard !lines.isEmpty else {
            return
        }

        let text =
            lines.joined(separator: "\n") + "\n"

        lines.removeAll(
            keepingCapacity: true
        )

        guard
            let data = text.data(using: .utf8)
        else {
            return
        }

        if FileManager.default.fileExists(
            atPath: outputURL.path
        ) {

            if let handle =
                FileHandle(
                    forWritingAtPath: outputURL.path
                ) {

                handle.seekToEndOfFile()
                handle.write(data)
                handle.closeFile()
            }

        } else {

            try? data.write(
                to: outputURL
            )
        }
    }
}