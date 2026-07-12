import Foundation
import CoreAudio

final class AudioOutput {

    let device: AudioDevice
    let audioBuffer: AudioBuffer

    private var callbackCount = 0
    private var ioProcID: AudioDeviceIOProcID?

    init(device: AudioDevice, audioBuffer: AudioBuffer) {
        self.device = device
        self.audioBuffer = audioBuffer
    }
    
    private func outputFormat() -> AudioStreamBasicDescription? {

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

    if status != noErr {
        print("Output stream format error: \(status)")
        return nil
    }

    print("Output Sample Rate: \(format.mSampleRate)")
    print("Output Format ID: \(format.mFormatID)")
    print("Output Bits per channel: \(format.mBitsPerChannel)")
    print("Output Channels: \(format.mChannelsPerFrame)")
    print("Output Bytes per frame: \(format.mBytesPerFrame)")

    return format
}


    func start() {

        print("Starting output:")
        print("  Device: \(device.name)")
        print("  ID: \(device.id)")
	guard let _ = outputFormat() else {
    	    return
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
        print("Output callback size: \(sampleCount) samples")
    }

    if output.callbackCount % 500 == 0 {
        print("AudioBuffer depth: \(output.audioBuffer.sampleCount()) samples")
    }

    let mono = output.audioBuffer.read(
        count: sampleCount / 2
    )

    var monoIndex = 0

    for i in stride(from: 0, to: sampleCount, by: 2) {

        if monoIndex < mono.count {

            let sample = mono[monoIndex]

            samples[i] = sample

            if i + 1 < sampleCount {
                samples[i + 1] = sample
            }

            monoIndex += 1

        } else {

            samples[i] = 0

            if i + 1 < sampleCount {
                samples[i + 1] = 0
            }
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
}
