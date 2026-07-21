import Foundation
import CoreAudio

final class AudioOutput {

    let device: AudioDevice
    let audioBuffer: AudioBuffer

    private var ioProcID: AudioDeviceIOProcID?
    private var callbackCount = 0

    private let testTone: TestTone

init(
    device: AudioDevice,
    audioBuffer: AudioBuffer
) {

    self.device = device
    self.audioBuffer = audioBuffer

    let frequency: Float

    if device.transport == "Bluetooth" {
        frequency = DebugFlags.bluetoothOutputToneFrequency
    } else {
        frequency = DebugFlags.computerOutputToneFrequency
    }

self.testTone = TestTone(
    frequency: frequency,
    amplitude: DebugFlags.testToneAmplitude
)

self.testTone.logConfiguration(
    name: device.name
)
}
    
    private func printStreamFormat() {

var address = CoreAudioHelpers.address(
    selector: kAudioDevicePropertyStreamFormat,
    scope: kAudioDevicePropertyScopeOutput
)

    var format = AudioStreamBasicDescription()
    var size = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)

    let status = AudioObjectGetPropertyData(
        device.id,
        &address,
        0,
        nil,
        &size,
        &format
    )

    if status == noErr {

DebugTelemetry.output.log(
    """
    OUTPUT FORMAT
    device=\(device.name)
    sampleRate=\(format.mSampleRate)
    formatID=\(format.mFormatID)
    bits=\(format.mBitsPerChannel)
    channels=\(format.mChannelsPerFrame)
    bytesPerFrame=\(format.mBytesPerFrame)
    """
)
    }
}

    func start() {

if ioProcID != nil {

    Logger.audio("Restarting output: \(device.name)")

    stop()
}

DebugTelemetry.output.log(
    """
    OUTPUT START
    device=\(device.name)
    id=\(device.id)
    """
)

printStreamFormat()

var address = CoreAudioHelpers.address(
    selector: kAudioDevicePropertyBufferFrameSize,
    scope: kAudioObjectPropertyScopeOutput
)

var frames: UInt32 = 0
var size = UInt32(MemoryLayout<UInt32>.size)

if AudioObjectGetPropertyData(
    device.id,
    &address,
    0,
    nil,
    &size,
    &frames
) == noErr {

    DebugTelemetry.output.log(
    """
    OUTPUT BUFFER
    device=\(device.name)
    frames=\(frames)
    """
)
}

        let status = AudioDeviceCreateIOProcID(
            device.id,
            { (
                inDevice,
                inNow,
                inInputData,
                inInputTime,
                outOutputData,
                inOutputTime,
                clientData
            ) -> OSStatus in

        guard let clientData = clientData else {
            return noErr
        }

        let output = Unmanaged<AudioOutput>
            .fromOpaque(clientData)
            .takeUnretainedValue()

    output.renderOutput(outOutputData)

        return noErr

            },
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            &ioProcID
        )

        if status != noErr {
            Logger.error(
    "Failed to create output IOProc \(device.name): \(status)"
)
            return
        }

let shouldStart: Bool

if device.transport == "Bluetooth" {

    shouldStart = DebugFlags.enableBluetoothOutput

} else {

    shouldStart = DebugFlags.enableComputerOutput

}

if shouldStart {

let startStatus = AudioDeviceStart(
    device.id,
    ioProcID!
)

if startStatus != noErr {

    Logger.error(
        "Failed to start output device: \(startStatus)"
    )

}

} else {

DebugTelemetry.output.log(
    """
    OUTPUT DISABLED
    device=\(device.name)
    """
)

}

}

func stop() {

    guard let ioProcID = ioProcID else {
        return
    }

    AudioDeviceStop(
        device.id,
        ioProcID
    )

    AudioDeviceDestroyIOProcID(
        device.id,
        ioProcID
    )

    self.ioProcID = nil

    Logger.audio(
	"Stopped output: \(device.name)"
    )
}

private func renderOutput(
    _ outOutputData: UnsafeMutablePointer<AudioBufferList>?
) {

    guard let outOutputData = outOutputData else {
        return
    }

    callbackCount += 1

if callbackCount % 1000 == 0 {

    DebugTelemetry.output.log(
        "\(device.name) callbacks=\(callbackCount)"
    )

}

    let buffers = UnsafeMutableAudioBufferListPointer(
        outOutputData
    )

if callbackCount % 100 == 0 {
    DebugTelemetry.output.log(
        """
OUTPUT BUFFER LAYOUT
device=\(device.name)
bufferCount=\(buffers.count)
"""
    )
}

if callbackCount % 100 == 0 {

    for (index, buffer) in buffers.enumerated() {

        DebugTelemetry.output.log(
            """
            buffer=\(index)
            bytes=\(buffer.mDataByteSize)
            channels=\(buffer.mNumberChannels)
            """
        )
    }
}


for buffer in buffers {

    guard let data = buffer.mData else {
        continue
    }

    let samples = data.assumingMemoryBound(
        to: Float.self
    )

    let sampleCount =
        Int(buffer.mDataByteSize) /
        MemoryLayout<Float>.size

    if DebugFlags.generateTestTone {

        testTone.fill(
            samples,
            count: sampleCount,
            sampleRate: Float(device.sampleRate),
            channels: Int(buffer.mNumberChannels)
        )

        continue
    }


    let incoming: [Float]

    if buffer.mNumberChannels == 1 {
        incoming = audioBuffer.read(
            count: sampleCount
        )
    } else {
        incoming = audioBuffer.read(
            count: sampleCount / 2
        )
    }


    if buffer.mNumberChannels == 1 {

        for i in 0..<sampleCount {

            if i < incoming.count {
                samples[i] = incoming[i]
            } else {
                samples[i] = 0
            }
        }

    } else {

        for i in 0..<sampleCount {

            let monoIndex = i / 2

            if monoIndex < incoming.count {
                samples[i] = incoming[monoIndex]
            } else {
                samples[i] = 0
            }
        }
    }


    if callbackCount % 500 == 0 {

        DebugTelemetry.output.log(
            """
            OUTPUT
            device=\(device.name)
            requested=\(sampleCount)
            channels=\(buffer.mNumberChannels)
            read=\(incoming.count)
            queue=\(audioBuffer.sampleCount())
            """
        )
    }
}
}
}