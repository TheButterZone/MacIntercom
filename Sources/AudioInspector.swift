import Foundation
import CoreAudio

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

    static func deviceName(_ deviceID: AudioDeviceID) -> String {

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
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

    var address = AudioObjectPropertyAddress(
        mSelector: kAudioDevicePropertyDeviceUID,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMaster
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

    var address = AudioObjectPropertyAddress(
        mSelector: kAudioDevicePropertyTransportType,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMaster
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

    static func channelCount(
    _ deviceID: AudioDeviceID,
    scope: AudioObjectPropertyScope
) -> Int {

    var address = AudioObjectPropertyAddress(
        mSelector: kAudioDevicePropertyStreamConfiguration,
        mScope: scope,
        mElement: kAudioObjectPropertyElementMaster
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
        )
    )

}

    static func findIntercomRoute(
    _ endpoints: [BluetoothEndpoint]
) -> IntercomRoute? {

    for endpoint in endpoints {

        if let input = endpoint.input,
           let output = endpoint.output {

            return IntercomRoute(
                input: input,
                output: output
            )
        }
    }

    return nil
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

    var propertyAddress = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDevices,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMaster
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

        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
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
