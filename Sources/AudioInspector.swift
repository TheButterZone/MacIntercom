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

        var text = ""
        text += "Core Audio reports \(deviceCount) audio device(s).\n\n"

    for id in deviceIDs {

    let device = makeDevice(id)

        text += "Device ID: \(device.id)\n"
        text += "UID: \(device.uid)\n"
        text += "Name: \(device.name)\n"
        text += "Transport: \(device.transport)\n"
        text += "Input Channels: \(device.inputChannels)\n"
        text += "Output Channels: \(device.outputChannels)\n\n"
}

        return text
    }
}
