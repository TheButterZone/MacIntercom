import Foundation
import IOKit.hid

final class HIDMediaKeyMonitor {

    private var manager: IOHIDManager?

    func start() {
        // Respect the app's debug flags
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

        guard let deviceSet = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice> else {
            Logger.media("No HID devices found")
            return
        }

        var bluetoothCount = 0

        for device in deviceSet {
            let transport = IOHIDDeviceGetProperty(
                device,
                kIOHIDTransportKey as CFString
            ) as? String ?? "Unknown"
            
            // Filter out internal Apple trackpads, keyboards, etc.
            let isBluetooth = transport.lowercased().contains("bluetooth") || transport.lowercased().contains("bt")
            guard isBluetooth else { continue }
            
            bluetoothCount += 1

            let manufacturer = IOHIDDeviceGetProperty(
                device,
                kIOHIDManufacturerKey as CFString
            ) as? String ?? "?"

            let product = IOHIDDeviceGetProperty(
                device,
                kIOHIDProductKey as CFString
            ) as? String ?? "?"
            
            let usagePage = IOHIDDeviceGetProperty(
                device,
                kIOHIDPrimaryUsagePageKey as CFString
            ) as? Int ?? 0

            let usageDescription = describeUsagePage(usagePage)

            Logger.media(
                "BT HID: \(manufacturer) / \(product) | Transport: \(transport) | Page: 0x\(String(usagePage, radix: 16, uppercase: true)) (\(usageDescription))"
            )
        }
        
        Logger.media("Total Bluetooth HID devices found: \(bluetoothCount)")
    }
    
    private func describeUsagePage(_ page: Int) -> String {
        switch page {
        case 0x01: return "Generic Desktop"
        case 0x0B: return "Telephony Controls"
        case 0x0C: return "Consumer Controls (Media/Audio)"
        case 0x0D: return "Digitizer"
        case 0xFF00...0xFFFF: return "Vendor-Defined"
        default: return "Other"
        }
    }
}