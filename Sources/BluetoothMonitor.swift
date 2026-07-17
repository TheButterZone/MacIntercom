import Foundation
import IOBluetooth

final class BluetoothMonitor: NSObject {

    func start() {

	if !DebugFlags.bluetoothDebug {
            return
	}

        Logger.media("Bluetooth monitor started")

        guard let devices =
            IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice]
        else {

            Logger.media("No paired Bluetooth devices")
            return
        }

        Logger.media(
            "Paired Bluetooth devices: \(devices.count)"
        )

        for device in devices {

            Logger.media("----------------")

            Logger.media(
                "Name: \(device.name ?? "?")"
            )

            Logger.media(
                "Address: \(device.addressString ?? "?")"
            )

            Logger.media(
                "Connected: \(device.isConnected())"
            )

            Logger.media(
                "Paired: \(device.isPaired())"
            )

            Logger.media(
                "Class: \(device.classOfDevice)"
            )

            guard let services =
                device.services as? [IOBluetoothSDPServiceRecord]
            else {

                Logger.media("No services")
                continue
            }

            Logger.media(
                "Service count: \(services.count)"
            )

            for service in services {

                let name =
                    service.getServiceName() ?? "Unknown"

                var handle:
                    BluetoothSDPServiceRecordHandle = 0

let result =
    service.getHandle(
        &handle
    )

                Logger.media(
                    "Service: \(name)"
                )

                Logger.media(
                    "Handle status: \(result)"
                )

                Logger.media(
                    String(
                        format: "Handle: 0x%08X",
                        handle
                    )
                )
            }
        }
    }
}