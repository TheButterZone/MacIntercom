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

class MenuController: NSObject {
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    let statusMenuItem = NSMenuItem(title: "MacIntercom: VAD & Scanner Active", action: nil, keyEquivalent: "")
    let lockMenuItem = NSMenuItem(title: "⏎ Lock Tone", action: #selector(lockClicked), keyEquivalent: "")
    let unlockMenuItem = NSMenuItem(title: "⎋ Unlock Squelch", action: #selector(unlockClicked), keyEquivalent: "")
    
    var onLockRequested: (() -> Void)?
    var onUnlockRequested: (() -> Void)?
    
    init(isSDRMode: Bool) {
        super.init()
        
        statusItem.button?.title = "⩛"
        let menu = NSMenu()
        
        if isSDRMode {
            statusMenuItem.isEnabled = false 
            menu.addItem(statusMenuItem)
            menu.addItem(NSMenuItem.separator())
            
            lockMenuItem.target = self
            menu.addItem(lockMenuItem)
            
            unlockMenuItem.target = self
            menu.addItem(unlockMenuItem)
            
            menu.addItem(NSMenuItem.separator())
        }
        
        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "")
        menu.addItem(quitItem)
        
        statusItem.menu = menu
    }
    
    @objc func lockClicked() {
        onLockRequested?()
    }
    
    @objc func unlockClicked() {
        onUnlockRequested?()
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
}