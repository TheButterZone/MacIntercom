import Foundation
import CoreAudio

final class AudioOutput {

    let device: AudioDevice
    let audioBuffer: AudioBuffer

    private var callbackCount = 0
    private var lastCallbackTime = CFAbsoluteTimeGetCurrent()
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

    static func defaultFormat(
	for device: AudioDevice
    ) -> AudioStreamBasicDescription? {

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

    guard status == noErr else {
        return nil
    }

    return format
}

    func start() {

        print("Starting output:")
        print("  Device: \(device.name)")
        print("  ID: \(device.id)")
	print(
	    "Output (\(device.name)) AudioBuffer:",
	    ObjectIdentifier(audioBuffer)
	)
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
	if output.callbackCount % 100 == 0 {

	    let now = CFAbsoluteTimeGetCurrent()

	    print(
		output.device.name,
		"100 output callbacks in",
		now - output.lastCallbackTime,
		"seconds"
	    )

    	    output.lastCallbackTime = now
	}

        let buffers = UnsafeMutableAudioBufferListPointer(
            outOutputData
        )

if output.callbackCount == 1 {

    print(
        output.device.name,
        "buffer count:",
        buffers.count
    )

    for (index, buffer) in buffers.enumerated() {

        print(
            "buffer",
            index,
            "channels:",
            buffer.mNumberChannels,
            "bytes:",
            buffer.mDataByteSize
        )
    }
}
        

for buffer in buffers {

    let samples = buffer.mData!.assumingMemoryBound(
        to: Float.self
    )

    let sampleCount = Int(buffer.mDataByteSize) /
	MemoryLayout<Float>.size

if sampleCount != 1024 {

    print(
        output.device.name,
        "callback changed to",
        sampleCount,
        "floats"
    )
}

    if output.callbackCount == 1 {

    	print(
	    "Output \(output.device.name) callback size:",
            sampleCount,
            "floats"
	)
    }

let requested = sampleCount / 2

let before = output.audioBuffer.sampleCount()

let mono = output.audioBuffer.read(
    count: requested
)

let after = output.audioBuffer.sampleCount()

if output.callbackCount % 100 == 0 {

    print(
        output.audioBuffer.name,
        "before:",
        before,
        "requested:",
        requested,
        "returned:",
        mono.count,
        "after:",
        after
    )
}

if output.callbackCount % 1000 == 0 {

    print(
        output.device.name,
        "TOTAL output callbacks:",
        output.callbackCount
    )
}

var maxRead: Float = 0

for sample in mono {

    let magnitude = abs(sample)

    if magnitude > maxRead {
        maxRead = magnitude
    }
}

if output.callbackCount % 100 == 0 {

    print(
        output.device.name,
        "read peak:",
        maxRead
    )
}

if output.callbackCount % 20 == 0 {

    print(
        output.device.name,
        "requested:",
        requested,
        "returned:",
        mono.count,
        "queue:",
        output.audioBuffer.sampleCount()
    )
}

if output.callbackCount % 200 == 0 {

//    print(
//        "\(output.audioBuffer.name)",
//        ObjectIdentifier(output.audioBuffer),
//        "read",
//        mono.count,
//        "queue:",
//        output.audioBuffer.sampleCount()
//    )
}

    var out = 0

var peak: Float = 0

for sample in mono {

    let magnitude = abs(sample)

    if magnitude > peak {
        peak = magnitude
    }
}

if output.callbackCount % 100 == 0 {

    print(
        output.device.name,
        "output peak:",
        peak
    )
}

for sample in mono {

    if out + 1 >= sampleCount {
        break
    }

    samples[out] = sample
    samples[out + 1] = sample

    out += 2
}

    while out < sampleCount {

	samples[out] = 0

	if out + 1 < sampleCount {
            samples[out + 1] = 0
	}

	out += 2
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
