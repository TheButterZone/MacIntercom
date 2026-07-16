import Foundation

enum Logger {

    static var verbose = true

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

    // MARK: - Categories

    static func audio(_ message: String) {
        debug("🎤 \(message)")
    }

    static func route(_ message: String) {
        debug("🔀 \(message)")
    }

    static func conversation(_ message: String) {
        debug("💬 \(message)")
    }

    static func media(_ message: String) {
        debug("▶️ \(message)")
    }
}