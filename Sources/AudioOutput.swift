import Foundation
import CoreAudio

final class AudioOutput {

    let device: AudioDevice
    let audioBuffer: AudioBuffer

    private var ioProcID: AudioDeviceIOProcID?
    private var callbackCount = 0

    let testTone = TestTone()

    init(device: AudioDevice, audioBuffer: AudioBuffer) {
        self.device = device
        self.audioBuffer = audioBuffer
    }
    
    private func printStreamFormat() {

    var address = AudioObjectPropertyAddress(
        mSelector: kAudioDevicePropertyStreamFormat,
        mScope: kAudioDevicePropertyScopeOutput,
        mElement: kAudioObjectPropertyElementMaster
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

	Logger.audio("Output Sample Rate: \(format.mSampleRate)")
	Logger.audio("Output Format ID: \(format.mFormatID)")
	Logger.audio("Output Bits per channel: \(format.mBitsPerChannel)")
	Logger.audio("Output Channels: \(format.mChannelsPerFrame)")
	Logger.audio("Output Bytes per frame: \(format.mBytesPerFrame)")
    }
}

    func start() {

if ioProcID != nil {

    Logger.audio("Restarting output: \(device.name)")

    stop()
}

        Logger.audio("Starting output:")
        Logger.audio("  Device: \(device.name)")
        Logger.audio("  ID: \(device.id)")
printStreamFormat()

var address = AudioObjectPropertyAddress(
    mSelector: kAudioDevicePropertyBufferFrameSize,
    mScope: kAudioObjectPropertyScopeOutput,
    mElement: kAudioObjectPropertyElementMaster
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

    Logger.audio("Output buffer frames: \(frames)")
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

        output.callbackCount += 1

if output.callbackCount == 1 {

    Logger.info("FIRST OUTPUT CALLBACK: \(output.device.name)")

}

if output.callbackCount % 100 == 0 {

    Logger.callback(
        "\(output.device.name) output callbacks: \(output.callbackCount)"
    )

}

        let buffers = UnsafeMutableAudioBufferListPointer(
            outOutputData
        )
        

for buffer in buffers {

    let samples = buffer.mData!.assumingMemoryBound(
        to: Float.self
    )

    let sampleCount = Int(buffer.mDataByteSize) /
        MemoryLayout<Float>.size

if output.callbackCount == 1 {

    Logger.audio("sampleCount = \(sampleCount)")
    Logger.audio("buffer channels = \(buffer.mNumberChannels)")
}

if output.callbackCount == 1 {

    Logger.audio(
        "OUTPUT DEVICE: \(output.device.name) transport=\(output.device.transport)"
    )

    Logger.audio(
        "\(output.device.name): buffers=\(buffers.count) channels=\(buffer.mNumberChannels) bytes=\(buffer.mDataByteSize)"
    )

}

if DebugFlags.generateTestTone {

    if output.device.transport == "Bluetooth" {

Logger.audio(
    "TestTone frequency=\(output.testTone.frequency) amplitude=\(output.testTone.amplitude)"
)

Logger.audio(
    "Using sample rate: \(output.device.sampleRate)"
)

output.testTone.fill(
    samples,
    count: sampleCount,
    sampleRate: Float(output.device.sampleRate)
)

print("AFTER FILL")

for i in 0..<16 {
    print(samples[i])
}

    } else {

        for i in 0..<sampleCount {
            samples[i] = 0
        }

    }

    continue
}

Logger.info(
    "READ BUFFER: \(Unmanaged.passUnretained(output.audioBuffer).toOpaque())"
)

    let incoming = output.audioBuffer.read(
        count: sampleCount
    )

if output.callbackCount % 500 == 0 {

    Logger.queue(
        "\(output.device.name) callback: \(output.callbackCount) requested: \(sampleCount) received: \(incoming.count) queued: \(output.audioBuffer.sampleCount())"
    )

}

    for i in 0..<sampleCount {

        if i < incoming.count {
            samples[i] = incoming[i]
        } else {
            samples[i] = 0
        }
    }
}        

        return noErr

            },
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            &ioProcID
        )

        if status != noErr {
            print("Failed to create output IOProc: \(status)")
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

print("START STATUS =", startStatus)

if startStatus == noErr {

    print("CALLING printCurrentOutputFormat()")

    device.printCurrentOutputFormat()
}

}

} else {

    Logger.info(
        "DEBUG: Output disabled for \(device.name)"
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

}
