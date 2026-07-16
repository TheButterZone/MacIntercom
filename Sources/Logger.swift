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

}
