import Foundation
import CoreAudio

final class AudioCapture {

    let device: AudioDevice
    let outputDevice: AudioDevice
    let audioBuffer: AudioBuffer

    private var ioProcID: AudioDeviceIOProcID?
    private var callbackCount = 0
    private var lastCallbackTime = CFAbsoluteTimeGetCurrent()
    private var highestPeak: Float = 0
    private var highestProcessedPeak: Float = 0
    private var resampler: AudioResampler?
    private var inputChannels: UInt32 = 1

    init(
        device: AudioDevice,
        outputDevice: AudioDevice,
        audioBuffer: AudioBuffer
	) {
        self.device = device
        self.outputDevice = outputDevice
        self.audioBuffer = audioBuffer
    }

private func inputFormat() -> AudioStreamBasicDescription? {

    var address = AudioObjectPropertyAddress(
        mSelector: kAudioDevicePropertyStreamFormat,
        mScope: kAudioDevicePropertyScopeInput,
        mElement: kAudioObjectPropertyElementMaster
    )

    var format = AudioStreamBasicDescription()

    var size = UInt32(
        MemoryLayout<AudioStreamBasicDescription>.size
    )

    let status = AudioObjectGetPropertyData(
        device.id,
        &address,
        0,
        nil,
        &size,
        &format
    )

    guard status == noErr else {
        print("Stream format error: \(status)")
        return nil
    }

    print("Sample Rate: \(format.mSampleRate)")
    print("Format ID: \(format.mFormatID)")
    print("Format Flags: \(format.mFormatFlags)")
    print("Bits per channel: \(format.mBitsPerChannel)")
    print("Channels: \(format.mChannelsPerFrame)")
    print("Bytes per frame: \(format.mBytesPerFrame)")

    return format
}

    func start() {

        print("Starting capture:")
        print("  Device: \(device.name)")
        print("  ID: \(device.id)")
	print(
	    "Capture (\(device.name)) AudioBuffer:",
	    ObjectIdentifier(self.audioBuffer)
	)

	device.printInputStreams()

	guard let input = inputFormat() else {
	    return
	}
	
	print("Capture channels:", input.mChannelsPerFrame)

	inputChannels = input.mChannelsPerFrame

	guard let output = AudioOutput.defaultFormat(
	    for: outputDevice
	) else {
	    return
	}

	resampler = AudioResampler(
	    inputSampleRate: input.mSampleRate,
	    outputSampleRate: output.mSampleRate
	)
        
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

                if let clientData = clientData {

                    let capture = Unmanaged<AudioCapture>
                        .fromOpaque(clientData)
                        .takeUnretainedValue()

                    capture.callbackCount += 1

    let bufferList = UnsafeMutableAudioBufferListPointer(
        UnsafeMutablePointer(mutating: inInputData)
    )

if capture.callbackCount == 1 {

    print(
        capture.device.name,
        "input buffer count:",
        bufferList.count
    )

    for (index, buffer) in bufferList.enumerated() {

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

    if let data = bufferList[0].mData {

        let samples = data.assumingMemoryBound(
            to: Float.self
        )

        let sampleCount = Int(
            bufferList[0].mDataByteSize
        ) / MemoryLayout<Float>.size

        if capture.callbackCount == 1 {
            print("Capture callback size: \(sampleCount) samples")
        }

        var peak: Float = 0

        for i in 0..<sampleCount {

            let magnitude = abs(samples[i])

            if magnitude > peak {
                peak = magnitude
            }
        }

        if peak > capture.highestPeak {
            capture.highestPeak = peak
        }

        if capture.callbackCount % 500 == 0 {
            print("Highest input peak: \(capture.highestPeak)")
            capture.highestPeak = 0
        }   

	if capture.callbackCount % 100 == 0 {

    	    let now = CFAbsoluteTimeGetCurrent()

    	    print(
		capture.device.name,
		"100 capture callbacks in",
		now - capture.lastCallbackTime,
		"seconds"
	    )

    	    capture.lastCallbackTime = now
	}     

var monoSamples: [Float]

if capture.inputChannels == 1 {

    monoSamples = Array(
        UnsafeBufferPointer(
            start: samples,
            count: sampleCount
        )
    )

} else {

    monoSamples = []
    monoSamples.reserveCapacity(sampleCount / 2)

    var i = 0

    while i + 1 < sampleCount {

        let left = samples[i]
        let right = samples[i + 1]

        monoSamples.append(
            (left + right) * 0.5
        )

        i += 2
    }
}

	let processed =
	    capture.resampler?.process(
	        monoSamples
	    ) ?? monoSamples

if capture.callbackCount % 100 == 0 {

    print(
        capture.device.name,
        "mono:",
        monoSamples.count,
        "processed:",
        processed.count
    )
}

if capture.callbackCount % 100 == 0 && !processed.isEmpty {

    print(
        capture.device.name,
        "first processed sample:",
        processed[0]
    )
}

for sample in processed {

    let magnitude = abs(sample)

    if magnitude > capture.highestProcessedPeak {
        capture.highestProcessedPeak = magnitude
    }
}

if capture.callbackCount % 500 == 0 {

    print(
        capture.device.name,
        "highest processed peak:",
        capture.highestProcessedPeak
    )

    capture.highestProcessedPeak = 0
}

var writePeak: Float = 0

for sample in processed {

    let m = abs(sample)

    if m > writePeak {
        writePeak = m
    }
}

print(
    capture.audioBuffer.name,
    "ABOUT TO WRITE peak:",
    writePeak,
    "count:",
    processed.count
)

	capture.audioBuffer.write(processed)

if capture.callbackCount % 1000 == 0 {

    print(
        capture.device.name,
        "TOTAL capture callbacks:",
        capture.callbackCount
    )
}

if capture.callbackCount % 20 == 0 {

    print(
        "\(capture.device.name) captured",
        processed.count,
        "floats"
    )
}

if capture.callbackCount % 20 == 0 {

    print(
        "\(capture.audioBuffer.name) wrote",
        ObjectIdentifier(capture.audioBuffer),
        processed.count,
        "floats, queue:",
        capture.audioBuffer.sampleCount()
    )
}
	}
                }

                return noErr
            },
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            &ioProcID
        )

        if status != noErr {
            print("Failed to create IOProc: \(status)")
            return
        }

        let startStatus = AudioDeviceStart(
            device.id,
            ioProcID!
        )

        if startStatus != noErr {
            print("Failed to start device: \(startStatus)")
        }
    }
}
