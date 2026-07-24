//
// MacIntercom
// Copyright (C) 2026 TheButterZone
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
// See the GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see:
// https://www.gnu.org/licenses/
//

import Foundation

final class DebugTelemetry {

    static let shared = DebugTelemetry()

    static let capture = Capture()
    static let output = Output()
    static let buffer = Buffer()

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

        try? FileManager.default.removeItem(
            at: outputURL
        )

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

    func record(
        _ text: String
    ) {

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
                )
            {

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

extension DebugTelemetry {

    final class Capture {

        func log(_ text: String) {

            DebugTelemetry.shared.record(
                text
            )
        }
    }

    final class Output {

        func log(_ text: String) {

            DebugTelemetry.shared.record(
                text
            )
        }
    }

    final class Buffer {

        func log(_ text: String) {

            DebugTelemetry.shared.record(
                text
            )
        }
    }
}
