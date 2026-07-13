import Foundation
import CoreAudio

final class AudioCapture {

    let device: AudioDevice
    let outputDevice: AudioDevice
    let audioBuffer: AudioBuffer

    private var ioProcID: AudioDeviceIOProcID?
    private var callbackCount = 0
    private var highestPeak: Float = 0
    private var resampler: AudioResampler?

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
	    "Capture AudioBuffer:",
	    ObjectIdentifier(self.audioBuffer)
	)

	device.printInputStreams()

	guard inputFormat() != nil else {
	    return
	}

	resampler = AudioResampler()
        
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

        let capturedSamples = Array(
            UnsafeBufferPointer(
                start: samples,
                count: sampleCount
            )
        )

	let processed =
	    capture.resampler?.process(
		capturedSamples
	    ) ?? capturedSamples

	capture.audioBuffer.write(processed)
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
