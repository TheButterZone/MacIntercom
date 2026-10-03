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

import AppKit
import CoreAudio

class MenuController: NSObject {
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    // SDR Menu Items
    let statusMenuItem = NSMenuItem(title: "MacIntercom: VAD & Scanner Active", action: nil, keyEquivalent: "")
    let lockMenuItem = NSMenuItem(title: "⏎ Lock Tone", action: #selector(lockClicked), keyEquivalent: "")
    let unlockMenuItem = NSMenuItem(title: "⎋ Unlock Squelch", action: #selector(unlockClicked), keyEquivalent: "")
    let sdrInputMenuItem = NSMenuItem(title: "SDR Input", action: nil, keyEquivalent: "")

    // Standalone / Media-Aware Menu Items
    let muteMenuItem = NSMenuItem(title: "🔇 Mute Intercom", action: #selector(muteClicked), keyEquivalent: "")
    let unmuteMenuItem = NSMenuItem(title: "🔊 Unmute Intercom", action: #selector(unmuteClicked), keyEquivalent: "")

    // Device Submenu Placeholders
    let broadcastInputMenuItem = NSMenuItem(title: "Broadcast Input", action: nil, keyEquivalent: "")
    let broadcastOutputMenuItem = NSMenuItem(title: "Broadcast Output", action: nil, keyEquivalent: "")
    let returnInputMenuItem = NSMenuItem(title: "Return Input", action: nil, keyEquivalent: "")
    let returnOutputMenuItem = NSMenuItem(title: "Return Output", action: nil, keyEquivalent: "")

    // SDR Closures
    var onLockRequested: (() -> Void)?
    var onUnlockRequested: (() -> Void)?
    var onSDRInputSelected: ((AudioDevice) -> Void)?

    // Standalone / Media-Aware Closures
    var onMuteRequested: (() -> Void)?
    var onUnmuteRequested: (() -> Void)?

    var onBroadcastInputSelected: ((AudioDevice) -> Void)?
    var onBroadcastOutputSelected: ((AudioDevice) -> Void)?
    var onReturnInputSelected: ((AudioDevice) -> Void)?
    var onReturnOutputSelected: ((AudioDevice) -> Void)?

    init(isSDRMode: Bool, fixedTone: Float? = nil, isStandaloneMode: Bool = false) {
        super.init()

        statusItem.button?.title = "⩛"
        let menu = NSMenu()

        if isSDRMode {
            statusMenuItem.isEnabled = false
            menu.addItem(statusMenuItem)
            menu.addItem(NSMenuItem.separator())

            if let tone = fixedTone {
                statusMenuItem.title = "🔒 Tone Squelch: \(tone) Hz"
            } else {
                lockMenuItem.target = self
                menu.addItem(lockMenuItem)

                unlockMenuItem.target = self
                menu.addItem(unlockMenuItem)
                menu.addItem(NSMenuItem.separator())
            }
            
            menu.addItem(sdrInputMenuItem)
            menu.addItem(NSMenuItem.separator())
        } else if isStandaloneMode {
            // Mute / Unmute
            muteMenuItem.target = self
            menu.addItem(muteMenuItem)

            unmuteMenuItem.target = self
            unmuteMenuItem.isHidden = true
            menu.addItem(unmuteMenuItem)

            menu.addItem(NSMenuItem.separator())

            // Broadcast Route Section
            let broadcastHeader = NSMenuItem(title: "— Broadcast (Mac → Remote) —", action: nil, keyEquivalent: "")
            broadcastHeader.isEnabled = false
            menu.addItem(broadcastHeader)
            menu.addItem(broadcastInputMenuItem)
            menu.addItem(broadcastOutputMenuItem)

            menu.addItem(NSMenuItem.separator())

            // Return Route Section
            let returnHeader = NSMenuItem(title: "— Return (Remote → Mac) —", action: nil, keyEquivalent: "")
            returnHeader.isEnabled = false
            menu.addItem(returnHeader)
            menu.addItem(returnInputMenuItem)
            menu.addItem(returnOutputMenuItem)

            menu.addItem(NSMenuItem.separator())
        }

        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "")
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    // MARK: - Populate Device Menus
    
    func rebuildSDRMenu(currentInput: AudioDevice) {
        let inputs = AudioInspector.allInputDevices()
        sdrInputMenuItem.title = "Input: \(currentInput.name)"
        sdrInputMenuItem.submenu = createDeviceSubmenu(
            devices: inputs,
            selectedID: currentInput.id,
            action: #selector(selectSDRInput(_:))
        )
    }
    
    func rebuildDeviceMenus(
        broadcastRoute: IntercomRoute,
        returnRoute: IntercomRoute?
    ) {
        let inputs = AudioInspector.allInputDevices()
        let outputs = AudioInspector.allOutputDevices()

        // 1. Broadcast Input
        broadcastInputMenuItem.title = "Input: \(broadcastRoute.input.name)"
        broadcastInputMenuItem.submenu = createDeviceSubmenu(
            devices: inputs,
            selectedID: broadcastRoute.input.id,
            action: #selector(selectBroadcastInput(_:))
        )

        // 2. Broadcast Output
        broadcastOutputMenuItem.title = "Output: \(broadcastRoute.output.name)"
        broadcastOutputMenuItem.submenu = createDeviceSubmenu(
            devices: outputs,
            selectedID: broadcastRoute.output.id,
            action: #selector(selectBroadcastOutput(_:))
        )

        // 3. Return Input
        if let retInput = returnRoute?.input {
            returnInputMenuItem.title = "Input: \(retInput.name)"
            returnInputMenuItem.submenu = createDeviceSubmenu(
                devices: inputs,
                selectedID: retInput.id,
                action: #selector(selectReturnInput(_:))
            )
        } else {
            returnInputMenuItem.title = "Input: None"
            returnInputMenuItem.submenu = nil
        }

        // 4. Return Output
        if let retOutput = returnRoute?.output {
            returnOutputMenuItem.title = "Output: \(retOutput.name)"
            returnOutputMenuItem.submenu = createDeviceSubmenu(
                devices: outputs,
                selectedID: retOutput.id,
                action: #selector(selectReturnOutput(_:))
            )
        } else {
            returnOutputMenuItem.title = "Output: None"
            returnOutputMenuItem.submenu = nil
        }
    }

    private func createDeviceSubmenu(
        devices: [AudioDevice],
        selectedID: AudioDeviceID,
        action: Selector
    ) -> NSMenu {
        let menu = NSMenu()
        for device in devices {
            let item = NSMenuItem(
                title: "\(device.name) (\(device.transport))",
                action: action,
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = device
            item.state = (device.id == selectedID) ? .on : .off
            menu.addItem(item)
        }
        return menu
    }

    // MARK: - Device Selection Actions
    @objc func selectBroadcastInput(_ sender: NSMenuItem) {
        guard let device = sender.representedObject as? AudioDevice else { return }
        onBroadcastInputSelected?(device)
    }

    @objc func selectBroadcastOutput(_ sender: NSMenuItem) {
        guard let device = sender.representedObject as? AudioDevice else { return }
        onBroadcastOutputSelected?(device)
    }

    @objc func selectReturnInput(_ sender: NSMenuItem) {
        guard let device = sender.representedObject as? AudioDevice else { return }
        onReturnInputSelected?(device)
    }

    @objc func selectReturnOutput(_ sender: NSMenuItem) {
        guard let device = sender.representedObject as? AudioDevice else { return }
        onReturnOutputSelected?(device)
    }

    // MARK: - SDR Actions
    @objc func lockClicked() {
        onLockRequested?()
    }

    @objc func unlockClicked() {
        onUnlockRequested?()
    }
    
    @objc func selectSDRInput(_ sender: NSMenuItem) {
        guard let device = sender.representedObject as? AudioDevice else { return }
        onSDRInputSelected?(device)
    }

    // MARK: - Standalone / Media Actions
    @objc func muteClicked() {
        muteMenuItem.isHidden = true
        unmuteMenuItem.isHidden = false
        onMuteRequested?()
    }

    @objc func unmuteClicked() {
        unmuteMenuItem.isHidden = true
        muteMenuItem.isHidden = false
        onUnmuteRequested?()
    }

    func updateState(isLocked: Bool, lockedTone: Float?, detectedTone: Float?) {
        DispatchQueue.main.async {
            if isLocked, let lockFreq = lockedTone {
                self.statusMenuItem.title = "🔒 Locked: \(lockFreq) Hz"

                if let detected = detectedTone, detected != lockFreq {
                    self.lockMenuItem.title = "🔄 Switch to \(detected) Hz"
                    self.lockMenuItem.isEnabled = true
                } else {
                    self.lockMenuItem.title = "⏎ Lock Tone"
                    self.lockMenuItem.isEnabled = false
                }
            } else {
                if let detected = detectedTone {
                    self.statusMenuItem.title = "㎐ CTCSS: \(detected) Hz"
                    self.lockMenuItem.title = "⏎ Lock to \(detected) Hz"
                    self.lockMenuItem.isEnabled = true
                } else {
                    self.statusMenuItem.title = "MacIntercom: VAD & Scanner Active"
                    self.lockMenuItem.title = "⏎ Lock Tone"
                    self.lockMenuItem.isEnabled = false
                }
            }
        }
    }

    func syncMuteState(isMuted: Bool) {
        DispatchQueue.main.async {
            self.muteMenuItem.isHidden = isMuted
            self.unmuteMenuItem.isHidden = !isMuted
        }
    }
}