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

enum Logger {

    static var verbose = true

    // MARK: - Core logging

    static func info(_ message: String) {

        print(message)

    }

    static func debug(_ message: String) {

        guard verbose else {
            return
        }

        print(message)

    }

    static func warning(_ message: String) {

        print("⚠️ \(message)")

    }

    static func error(_ message: String) {

        print("❌ \(message)")

    }

    // MARK: - Debug categories

    static func performance(_ message: String) {
        debug("📊 \(message)")
    }

    static func device(_ message: String) {
        guard DebugFlags.logDeviceStartup else {
            return
        }

        print("🔧 \(message)")
    }

    static func audio(_ message: String) {

        guard DebugFlags.logDeviceStartup else {
            return
        }

        debug("🎤 \(message)")

    }

    static func callback(_ message: String) {

        guard DebugFlags.logCallbacks else {
            return
        }

        debug("🔁 \(message)")

    }

    static func levels(_ message: String) {

        guard DebugFlags.logLevels else {
            return
        }

        debug("📈 \(message)")

    }

    static func queue(_ message: String) {

        guard DebugFlags.logBufferDepth else {
            return
        }

        debug("📦 \(message)")

    }

    static func route(_ message: String) {

        guard DebugFlags.logDeviceStartup else {
            return
        }

        debug("🔀 \(message)")

    }

    static func conversation(_ message: String) {

        debug("💬 \(message)")

    }

    static func media(_ message: String) {

        guard DebugFlags.logMediaRemote else {
            return
        }

        debug("▶️ \(message)")

    }

}
