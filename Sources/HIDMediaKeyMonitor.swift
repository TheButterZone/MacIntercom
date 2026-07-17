import Foundation
import IOKit.hid

final class HIDMediaKeyMonitor {

    private var manager: IOHIDManager?

func start() {

    if !DebugFlags.bluetoothDebug {
        return
    }

    manager = IOHIDManagerCreate(
        kCFAllocatorDefault,
        IOOptionBits(kIOHIDOptionsTypeNone)
    )

    guard let manager = manager else {
        return
    }

    IOHIDManagerSetDeviceMatching(
        manager,
        nil
    )

    IOHIDManagerScheduleWithRunLoop(
        manager,
        CFRunLoopGetMain(),
        CFRunLoopMode.defaultMode.rawValue
    )

    IOHIDManagerOpen(
        manager,
        IOOptionBits(kIOHIDOptionsTypeNone)
    )

    Logger.media("IOHID monitor started")

        guard let deviceSet =
            IOHIDManagerCopyDevices(manager)
                as? Set<IOHIDDevice>
        else {
            Logger.media("No HID devices found")
            return
        }

        Logger.media("HID device count: \(deviceSet.count)")

        for device in deviceSet {

            let manufacturer =
                IOHIDDeviceGetProperty(
                    device,
                    kIOHIDManufacturerKey as CFString
                ) as? String ?? "?"

            let product =
                IOHIDDeviceGetProperty(
                    device,
                    kIOHIDProductKey as CFString
                ) as? String ?? "?"

            Logger.media(
                "HID: \(manufacturer) / \(product)"
            )
        }
    }
}