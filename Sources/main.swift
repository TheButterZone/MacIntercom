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

let mediaKeyMonitor = MediaKeyMonitor()
let bluetoothMonitor = BluetoothMonitor()

guard let bluetoothRoute =
    AudioInspector.bluetoothToComputerRoute()
else {
    Logger.error("No Bluetooth → Computer route")
    exit(1)
}

guard let computerRoute =
    AudioInspector.computerToBluetoothRoute()
else {
    Logger.error("No Computer → Bluetooth route")
    exit(1)
}

DebugTelemetry.capture.log(
    """
    AUDIO ROUTES
    Bluetooth input=\(bluetoothRoute.input.name)
    Bluetooth output=\(bluetoothRoute.output.name)
    Computer input=\(computerRoute.input.name)
    Computer output=\(computerRoute.output.name)
    """
)

print("MacIntercom v0.1.1 — Copyright (C) 2026 TheButterZone")
print("This program comes with ABSOLUTELY NO WARRANTY.")
print("This is free software under the GPLv3; see the LICENSE file for details.\n")

Logger.info("MacIntercom running, audio routes initialized:")

AudioInspector.printBufferFrameSize(
    bluetoothRoute.input
)

AudioInspector.printBufferFrameSize(
    bluetoothRoute.output
)

AudioInspector.printBufferFrameSize(
    computerRoute.input
)

AudioInspector.printBufferFrameSize(
    computerRoute.output
)

let computerToBluetooth = IntercomEngine(
    name: "Computer→BT",
    route: computerRoute,
    shouldDownsample: true,
    primeBuffer: true
)

let bluetoothToComputer = IntercomEngine(
    name: "BT→Computer",
    route: bluetoothRoute,
    shouldDownsample: false,
    primeBuffer: true
)

if DebugFlags.generateTestTone {

    Logger.info("🎵 TEST TONE MODE: starting both engines")

    computerToBluetooth.start()
    bluetoothToComputer.start()

} else {

    computerToBluetooth.capture.onFirstCallback = {

DebugTelemetry.capture.log(
    "Computer capture active -> starting Bluetooth engine"
)

        bluetoothToComputer.start()
    }

    computerToBluetooth.start()
}

bluetoothToComputer.capture.onFirstCallback = {

DebugTelemetry.capture.log(
    "Bluetooth capture active"
)

}

computerToBluetooth.start()

DebugTelemetry.shared.start()

mediaKeyMonitor.start()
bluetoothMonitor.start()

//MediaRemoteObserver.shared.start()

//let conversationController =
//    ConversationController()

//DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
//
//    Logger.info("TEST: Begin conversation")
//
//    conversationController.begin(
//        trigger: .app
//    )
//
//}
//
//DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
//
//    Logger.info("TEST: End conversation")
//
//    conversationController.end(
//        trigger: .app
//    )
//
//}

RunLoop.main.run()
