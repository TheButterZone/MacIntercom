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
import IOBluetooth

final class BluetoothMonitor: NSObject {

    func start() {

        if !DebugFlags.bluetoothDebug {
            return
        }

        Logger.media("Bluetooth monitor started")

        guard
            let devices =
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

            guard
                let services =
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

                var handle: BluetoothSDPServiceRecordHandle = 0

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
