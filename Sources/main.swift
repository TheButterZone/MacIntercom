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
import MediaPlayer

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let commandCenter = MPRemoteCommandCenter.shared()
commandCenter.playCommand.isEnabled = false
commandCenter.pauseCommand.isEnabled = false
commandCenter.togglePlayPauseCommand.isEnabled = false

AVCaptureDevice.requestAccess(for: .audio) { granted in
    if granted {
        Logger.info("Microphone access granted.")
    } else {
        Logger.error(
            "Grant microphone access to Terminal in your Mac's system settings (under Privacy & Security > Microphone)."
        )
    }
}

let arguments = CommandLine.arguments
if arguments.contains("--t") || arguments.contains("--testtone") {
    AppConfiguration.mode = .testTone
} else if arguments.contains("--s") || arguments.contains("--standalone") {
    AppConfiguration.mode = .standalone
} else if arguments.contains("--sdr") {
    AppConfiguration.mode = .sdr
} else {
    AppConfiguration.mode = .mediaAware
}

let computerRoute: IntercomRoute
if AppConfiguration.mode == .sdr {
    guard let route = AudioInspector.systemDefaultRoute() else {
        Logger.error("No system default route found")
        exit(1)
    }
    computerRoute = route
} else {
    guard let route = AudioInspector.computerToBluetoothRoute() else {
        Logger.error("No Computer → Bluetooth route")
        exit(1)
    }
    computerRoute = route
}

let bluetoothRoute: IntercomRoute? = AudioInspector.bluetoothToComputerRoute()

DebugTelemetry.shared.start()

if let btRoute = bluetoothRoute {
    DebugTelemetry.capture.log(
        "AUDIO ROUTES\n" +
        "Bluetooth input=\(btRoute.input.name)\n" +
        "Bluetooth output=\(btRoute.output.name)\n" +
        "Computer input=\(computerRoute.input.name)\n" +
        "Computer output=\(computerRoute.output.name)"
    )
    AudioInspector.printBufferFrameSize(btRoute.input)
    AudioInspector.printBufferFrameSize(btRoute.output)
} else {
    DebugTelemetry.capture.log(
        "AUDIO ROUTES (SDR / No Bluetooth)\n" +
        "Computer input=\(computerRoute.input.name)\n" +
        "Computer output=\(computerRoute.output.name)"
    )
}

AudioInspector.printBufferFrameSize(computerRoute.input)
AudioInspector.printBufferFrameSize(computerRoute.output)

let computerToBluetooth = IntercomEngine(
    name: "Computer→Output",
    route: computerRoute,
    shouldDownsample: true,
    primeBuffer: true
)

let bluetoothToComputer: IntercomEngine
if let btRoute = bluetoothRoute {
    bluetoothToComputer = IntercomEngine(
        name: "BT→Computer",
        route: btRoute,
        shouldDownsample: false,
        primeBuffer: true
    )
} else {
    let dummyRoute = IntercomRoute(input: computerRoute.input, output: computerRoute.output)
    bluetoothToComputer = IntercomEngine(
        name: "BT→Computer (Inactive)",
        route: dummyRoute,
        shouldDownsample: false,
        primeBuffer: false
    )
}

print("MacIntercom v0.1.8-sdr — Copyright (C) 2026 TheButterZone")
print("This program comes with ABSOLUTELY NO WARRANTY.")
print("This is free software under the GPLv3; see the LICENSE file for details.\n")

let bluetoothMonitor = BluetoothMonitor()
bluetoothMonitor.start()

var conversationController: ConversationController?
var mediaKeyMonitor: MediaKeyMonitor?

switch AppConfiguration.mode {
case .mediaAware:
    let mediaRemoteObserver = MediaRemoteObserver.shared
    mediaRemoteObserver.start()

    mediaKeyMonitor = MediaKeyMonitor()
    mediaKeyMonitor?.start()

    conversationController = ConversationController()
    conversationController?.onMuteStateChanged = { isMuted in
        computerToBluetooth.isMuted = isMuted
        bluetoothToComputer.isMuted = isMuted
    }

    conversationController?.syncInitialState()

    MediaKeyInterceptor.shared.conversationController = conversationController
    MediaKeyInterceptor.shared.startIntercepting()

case .standalone:
    
    computerToBluetooth.isMuted = false
    bluetoothToComputer.isMuted = false

case .testTone:
    computerToBluetooth.isMuted = false
    bluetoothToComputer.isMuted = false
    Logger.info("🎵 TEST TONE MODE: starting both engines")

case .sdr:
    computerToBluetooth.isMuted = false
    bluetoothToComputer.isMuted = true
}

let engineStartupGroup = DispatchGroup()

engineStartupGroup.enter()
computerToBluetooth.capture.onFirstCallback = {
    DebugTelemetry.capture.log("Computer capture active")
    engineStartupGroup.leave()
}

computerToBluetooth.start()

if AppConfiguration.mode != .sdr {
    engineStartupGroup.enter()
    bluetoothToComputer.capture.onFirstCallback = {
        DebugTelemetry.capture.log("Bluetooth capture active")
        engineStartupGroup.leave()
    }
    bluetoothToComputer.start()
}

DispatchQueue.global().async {
    _ = engineStartupGroup.wait(timeout: .now() + 3.0)
}

switch AppConfiguration.mode {
case .mediaAware:
    Logger.info("""
    MacIntercom running in MEDIA-AWARE mode.
    
    • Any Play/Pause button toggles the intercom off & on.
    • Media playback will be automatically paused/resumed.
    
    To disable media integration, restart with:
        ./macintercom --s
    """)
    
case .standalone:
    Logger.info("""
    MacIntercom running in STANDALONE mode.
    
    • Intercom audio is always active.
    • Media playback is ignored.
    • Any Play/Pause button behaves normally.
    """)
    
case .testTone:
    break 

case .sdr:
    Logger.info("""
    MacIntercom running in SDR SQUELCH mode.
    
    • WebRTC Voice Activity Detection (Squelch) and AGC are active.
    • Bluetooth microphone disabled.
    • Intended for wired/standard outputs (Built-in Speakers, Line-Out, USB).
    • Avoid using Bluetooth audio output in this mode.
    """)
}

app.run()