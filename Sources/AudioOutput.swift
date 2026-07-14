import Foundation
import CoreAudio

final class AudioOutput {

    let device: AudioDevice
    let audioBuffer: AudioBuffer

    private var ioProcID: AudioDeviceIOProcID?
    private var callbackCount = 0
    private var phase: Float = 0
    private let toneFrequency: Float = 440
    private let toneAmplitude: Float = 0.01

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

        print("Output Sample Rate: \(format.mSampleRate)")
        print("Output Format ID: \(format.mFormatID)")
        print("Output Bits per channel: \(format.mBitsPerChannel)")
        print("Output Channels: \(format.mChannelsPerFrame)")
        print("Output Bytes per frame: \(format.mBytesPerFrame)")
    }
}

    func start() {

if ioProcID != nil {

    print(
        "Restarting output:",
        device.name
    )

    stop()
}

        print("Starting output:")
        print("  Device: \(device.name)")
        print("  ID: \(device.id)")
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

    print("Output buffer frames:", frames)
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

if output.callbackCount % 100 == 0 {

    print(
        output.device.name,
        "output callbacks:",
        output.callbackCount
    )
}

        let buffers = UnsafeMutableAudioBufferListPointer(
            outOutputData
        )

if output.device.name == "Moo",
   output.callbackCount % 200 == 0 {

    print(
        "Moo callback",
        output.callbackCount,
        "bytes:",
        buffers.first?.mDataByteSize ?? 0
    )
}

        

for buffer in buffers {

    let samples = buffer.mData!.assumingMemoryBound(
        to: Float.self
    )

    let sampleCount = Int(buffer.mDataByteSize) /
        MemoryLayout<Float>.size

    let incoming = output.audioBuffer.read(
        count: sampleCount
    )

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

        let startStatus = AudioDeviceStart(
            device.id,
            ioProcID!
        )

        if startStatus != noErr {
            print("Failed to start output device: \(startStatus)")
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

    print(
        "Stopped output:",
        device.name
    )
}

}
