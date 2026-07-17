import AppKit

final class MediaKeyMonitor {

    private var appKitMonitor: Any?
    private var hidMonitor: HIDMediaKeyMonitor?

    func start() {

        startAppKit()

        hidMonitor = HIDMediaKeyMonitor()
        hidMonitor?.start()
    }

    private func startAppKit() {

        appKitMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: .systemDefined
        ) { event in

            Logger.media(
                "AppKit systemDefined subtype=\(event.subtype.rawValue) data1=\(event.data1)"
            )
        }
    }

    deinit {

        if let monitor = appKitMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}