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

import AVFoundation
import AppKit
import Foundation

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

AVCaptureDevice.requestAccess(for: .audio) { granted in
    if granted {
        Logger.info("Microphone access granted.")
    } else {
        Logger.error(
            "Grant microphone access to Terminal in your Mac's system settings (under Privacy & Security > Microphone)."
        )
    }
}

guard let bluetoothRoute = AudioInspector.bluetoothToComputerRoute() else {
    Logger.error("No Bluetooth → Computer route")
    exit(1)
}

guard let computerRoute = AudioInspector.computerToBluetoothRoute() else {
    Logger.error("No Computer → Bluetooth route")
    exit(1)
}

DebugTelemetry.shared.start()

DebugTelemetry.capture.log(
    """
    AUDIO ROUTES
    Bluetooth input=\(bluetoothRoute.input.name)
    Bluetooth output=\(bluetoothRoute.output.name)
    Computer input=\(computerRoute.input.name)
    Computer output=\(computerRoute.output.name)
    """
)

print("MacIntercom v0.1.3 — Copyright (C) 2026 TheButterZone")
print("This program comes with ABSOLUTELY NO WARRANTY.")
print("This is free software under the GPLv3; see the LICENSE file for details.\n")

AudioInspector.printBufferFrameSize(bluetoothRoute.input)
AudioInspector.printBufferFrameSize(bluetoothRoute.output)
AudioInspector.printBufferFrameSize(computerRoute.input)
AudioInspector.printBufferFrameSize(computerRoute.output)

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

let mediaRemoteObserver = MediaRemoteObserver.shared
mediaRemoteObserver.start()

let mediaKeyMonitor = MediaKeyMonitor()
mediaKeyMonitor.start()

let bluetoothMonitor = BluetoothMonitor()
bluetoothMonitor.start()

let conversationController = ConversationController()
conversationController.onMuteStateChanged = { isMuted in
    computerToBluetooth.isMuted = isMuted
    bluetoothToComputer.isMuted = isMuted
}

conversationController.syncInitialState()

MediaKeyInterceptor.shared.conversationController = conversationController
MediaKeyInterceptor.shared.startIntercepting()

if DebugFlags.generateTestTone {
    Logger.info("🎵 TEST TONE MODE: starting both engines")
}

let engineStartupGroup = DispatchGroup()

engineStartupGroup.enter()
computerToBluetooth.capture.onFirstCallback = {
    DebugTelemetry.capture.log("Computer capture active")
    engineStartupGroup.leave()
}

engineStartupGroup.enter()
bluetoothToComputer.capture.onFirstCallback = {
    DebugTelemetry.capture.log("Bluetooth capture active")
    engineStartupGroup.leave()
}

computerToBluetooth.start()
bluetoothToComputer.start()

DispatchQueue.global().async {
    _ = engineStartupGroup.wait(timeout: .now() + 3.0)
}

if !DebugFlags.generateTestTone {
    Logger.info("MacIntercom running. Waiting for Bluetooth AVRCP events.")
}

app.run()
