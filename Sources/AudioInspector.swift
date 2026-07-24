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

import CoreAudio
import Foundation

struct AudioInspector {

    static func transportName(_ transport: UInt32) -> String {

        switch transport {

        case kAudioDeviceTransportTypeBuiltIn:
            return "Built-in"

        case kAudioDeviceTransportTypeBluetooth:
            return "Bluetooth"

        case kAudioDeviceTransportTypeUSB:
            return "USB"

        case kAudioDeviceTransportTypeAggregate:
            return "Aggregate"

        case kAudioDeviceTransportTypeVirtual:
            return "Virtual"

        case kAudioDeviceTransportTypeHDMI:
            return "HDMI"

        default:
            return "Unknown (\(transport))"
        }
    }

    static func printBufferFrameSize(
        _ device: AudioDevice
    ) {

        var address = CoreAudioHelpers.address(
            selector: kAudioDevicePropertyBufferFrameSize,
            scope: kAudioObjectPropertyScopeGlobal
        )

        var frames: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)

        let status = AudioObjectGetPropertyData(
            device.id,
            &address,
            0,
            nil,
            &size,
            &frames
        )

        if status == noErr {

            DebugTelemetry.capture.log(
                """
                BUFFER FORMAT
                device=\(device.name)
                frames=\(frames)
                """
            )

        } else {

            DebugTelemetry.capture.log(
                """
                BUFFER FORMAT ERROR
                device=\(device.name)
                status=\(status)
                """
            )
        }
    }

    static func deviceName(_ deviceID: AudioDeviceID) -> String {

        var address = CoreAudioHelpers.address(
            selector: kAudioObjectPropertyName,
            scope: kAudioObjectPropertyScopeGlobal
        )

        var name: CFString = "" as CFString
        var size = UInt32(MemoryLayout<CFString>.size)

        let status = AudioObjectGetPropertyData(
            deviceID,
            &address,
            0,
            nil,
            &size,
            &name
        )

        if status != noErr {
            return "<error \(status)>"
        }

        return name as String
    }

    static func deviceUID(_ deviceID: AudioDeviceID) -> String {

        var address = CoreAudioHelpers.address(
            selector: kAudioDevicePropertyDeviceUID,
            scope: kAudioObjectPropertyScopeGlobal
        )

        var uid: CFString = "" as CFString
        var size = UInt32(MemoryLayout<CFString>.size)

        let status = AudioObjectGetPropertyData(
            deviceID,
            &address,
            0,
            nil,
            &size,
            &uid
        )

        if status != noErr {
            return "<error \(status)>"
        }

        return uid as String
    }

    static func transportType(_ deviceID: AudioDeviceID) -> UInt32 {

        var address = CoreAudioHelpers.address(
            selector: kAudioDevicePropertyTransportType,
            scope: kAudioObjectPropertyScopeGlobal
        )

        var transport: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)

        let status = AudioObjectGetPropertyData(
            deviceID,
            &address,
            0,
            nil,
            &size,
            &transport
        )

        if status != noErr {
            return 0
        }

        return transport
    }

    static func nominalSampleRate(
        _ deviceID: AudioDeviceID
    ) -> Double {

        var address = CoreAudioHelpers.address(
            selector: kAudioDevicePropertyNominalSampleRate,
            scope: kAudioObjectPropertyScopeGlobal
        )

        var sampleRate: Double = 0
        var size = UInt32(MemoryLayout<Double>.size)

        let status = AudioObjectGetPropertyData(
            deviceID,
            &address,
            0,
            nil,
            &size,
            &sampleRate
        )

        if status != noErr {
            return 0
        }

        return sampleRate
    }

    static func channelCount(
        _ deviceID: AudioDeviceID,
        scope: AudioObjectPropertyScope
    ) -> Int {

        var address = CoreAudioHelpers.address(
            selector: kAudioDevicePropertyStreamConfiguration,
            scope: scope
        )

        var dataSize: UInt32 = 0

        var status = AudioObjectGetPropertyDataSize(
            deviceID,
            &address,
            0,
            nil,
            &dataSize
        )

        if status != noErr {
            return -1
        }

        let bufferList = UnsafeMutablePointer<AudioBufferList>.allocate(
            capacity: Int(dataSize)
        )
        defer {
            bufferList.deallocate()
        }

        status = AudioObjectGetPropertyData(
            deviceID,
            &address,
            0,
            nil,
            &dataSize,
            bufferList
        )

        if status != noErr {
            return -1
        }

        let buffers = UnsafeMutableAudioBufferListPointer(bufferList)

        var total = 0

        for buffer in buffers {
            total += Int(buffer.mNumberChannels)
        }

        return total
    }

    static func makeDevice(_ id: AudioDeviceID) -> AudioDevice {

        return AudioDevice(
            id: id,
            uid: deviceUID(id),
            name: deviceName(id),
            transport: transportName(transportType(id)),
            inputChannels: channelCount(
                id,
                scope: kAudioDevicePropertyScopeInput
            ),
            outputChannels: channelCount(
                id,
                scope: kAudioDevicePropertyScopeOutput
            ),
            sampleRate: nominalSampleRate(id)
        )

    }

    static func defaultOutputDevice() -> AudioDevice? {

        var address = CoreAudioHelpers.address(
            selector: kAudioHardwarePropertyDefaultOutputDevice,
            scope: kAudioObjectPropertyScopeGlobal
        )

        var deviceID = AudioDeviceID()
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)

        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &deviceID
        )

        guard status == noErr else {
            return nil
        }

        return makeDevice(deviceID)
    }

    static func defaultInputDevice() -> AudioDevice? {

        var address = CoreAudioHelpers.address(
            selector: kAudioHardwarePropertyDefaultInputDevice,
            scope: kAudioObjectPropertyScopeGlobal
        )

        var deviceID = AudioDeviceID()
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)

        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &deviceID
        )

        guard status == noErr else {
            return nil
        }

        return makeDevice(deviceID)
    }

    static func findIntercomRoute(
        _ endpoints: [BluetoothEndpoint]
    ) -> IntercomRoute? {

        guard
            let bluetooth = endpoints.first(
                where: { $0.output != nil }
            )
        else {
            return nil
        }

        guard let selectedInput = defaultInputDevice() else {
            return nil
        }

        return IntercomRoute(
            input: selectedInput,
            output: bluetooth.output!
        )
    }

    static func bluetoothToComputerRoute() -> IntercomRoute? {

        let endpoints = groupBluetoothEndpoints(
            enumerateDevices()
        )

        guard
            let bluetooth = endpoints.first(
                where: { $0.input != nil }
            )
        else {
            return nil
        }

        guard let computer = defaultOutputDevice() else {
            return nil
        }

        return IntercomRoute(
            input: bluetooth.input!,
            output: computer
        )
    }

    static func computerToBluetoothRoute() -> IntercomRoute? {

        let endpoints = groupBluetoothEndpoints(
            enumerateDevices()
        )

        guard
            let bluetooth = endpoints.first(
                where: { $0.output != nil }
            )
        else {
            return nil
        }

        guard let input = defaultInputDevice() else {
            return nil
        }

        return IntercomRoute(
            input: input,
            output: bluetooth.output!
        )
    }

    static func groupBluetoothEndpoints(
        _ devices: [AudioDevice]
    ) -> [BluetoothEndpoint] {

        var groups: [String: BluetoothEndpoint] = [:]

        for device in devices {

            guard device.transport == "Bluetooth" else {
                continue
            }

            let parts = device.uid.split(separator: ":")

            guard parts.count > 1 else {
                continue
            }

            let baseUID = String(parts[0])

            if groups[baseUID] == nil {
                groups[baseUID] = BluetoothEndpoint(
                    baseUID: baseUID,
                    name: device.name,
                    input: nil,
                    output: nil
                )
            }

            if device.inputChannels > 0 {
                groups[baseUID]?.input = device
            }

            if device.outputChannels > 0 {
                groups[baseUID]?.output = device
            }
        }

        return Array(groups.values)
    }

    static func enumerateDevices() -> [AudioDevice] {

        var propertyAddress = CoreAudioHelpers.address(
            selector: kAudioHardwarePropertyDevices,
            scope: kAudioObjectPropertyScopeGlobal
        )

        var dataSize: UInt32 = 0

        let systemObject = AudioObjectID(kAudioObjectSystemObject)

        var status = AudioObjectGetPropertyDataSize(
            systemObject,
            &propertyAddress,
            0,
            nil,
            &dataSize
        )

        if status != noErr {
            return []
        }

        let deviceCount = Int(dataSize) / MemoryLayout<AudioDeviceID>.size

        var deviceIDs = Array(
            repeating: AudioDeviceID(),
            count: deviceCount
        )

        status = AudioObjectGetPropertyData(
            systemObject,
            &propertyAddress,
            0,
            nil,
            &dataSize,
            &deviceIDs
        )

        if status != noErr {
            return []
        }

        return deviceIDs.map { id in
            makeDevice(id)
        }
    }

    static func inspect() -> String {

        var propertyAddress = CoreAudioHelpers.address(
            selector: kAudioHardwarePropertyDevices,
            scope: kAudioObjectPropertyScopeGlobal
        )

        var dataSize: UInt32 = 0

        var status = AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &dataSize
        )

        if status != noErr {
            return "AudioObjectGetPropertyDataSize failed: \(status)"
        }

        let deviceCount = Int(dataSize) / MemoryLayout<AudioDeviceID>.size

        var deviceIDs = Array(repeating: AudioDeviceID(), count: deviceCount)

        status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &dataSize,
            &deviceIDs
        )

        if status != noErr {
            return "AudioObjectGetPropertyData failed: \(status)"
        }

        var devices: [AudioDevice] = []
        var text = ""
        text += "Core Audio reports \(deviceCount) audio device(s).\n\n"

        for id in deviceIDs {

            let device = makeDevice(id)
            devices.append(device)

            text += "Device ID: \(device.id)\n"
            text += "UID: \(device.uid)\n"
            text += "Name: \(device.name)\n"
            text += "Transport: \(device.transport)\n"
            text += "Input Channels: \(device.inputChannels)\n"
            text += "Output Channels: \(device.outputChannels)\n\n"
        }

        let endpoints = groupBluetoothEndpoints(devices)

        text += "Bluetooth Endpoints:\n\n"

        for endpoint in endpoints {
            text += "Name: \(endpoint.name)\n"
            text += "UID: \(endpoint.baseUID)\n"

            if let input = endpoint.input {
                text += "Input: \(input.id)\n"
            }

            if let output = endpoint.output {
                text += "Output: \(output.id)\n"
            }

            text += "\n"
        }

        if let route = findIntercomRoute(endpoints) {

            text += "Intercom Route Found:\n\n"

            text += "Input:\n"
            text += "  \(route.input.name)\n"
            text += "  Device ID: \(route.input.id)\n\n"

            text += "Output:\n"
            text += "  \(route.output.name)\n"
            text += "  Device ID: \(route.output.id)\n\n"

        } else {

            text += "No intercom route found.\n\n"
        }

        return text
    }
}
