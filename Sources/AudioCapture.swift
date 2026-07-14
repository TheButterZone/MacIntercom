import Foundation
import CoreAudio

final class AudioCapture {

    let device: AudioDevice
    let audioBuffer: AudioBuffer

    private var ioProcID: AudioDeviceIOProcID?
    private var callbackCount = 0
    private var highestPeak: Float = 0

private let shouldDownsample: Bool

private var downsampleAccumulator: Float = 0
private var downsampleCount = 0

init(
    device: AudioDevice,
    outputDevice: AudioDevice,
    audioBuffer: AudioBuffer,
    shouldDownsample: Bool
) {
    self.device = device
    self.audioBuffer = audioBuffer
    self.shouldDownsample = shouldDownsample
}

    private func printStreamFormat() {

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamFormat,
            mScope: kAudioDevicePropertyScopeInput,
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
            print("Sample Rate: \(format.mSampleRate)")
            print("Format ID: \(format.mFormatID)")
            print("Format Flags: \(format.mFormatFlags)")
            print("Bits per channel: \(format.mBitsPerChannel)")
            print("Channels: \(format.mChannelsPerFrame)")
            print("Bytes per frame: \(format.mBytesPerFrame)")
        } else {
            print("Stream format error: \(status)")
        }
    }

    func start() {

        print("Starting capture:")
        print("  Device: \(device.name)")
        print("  ID: \(device.id)")

printStreamFormat()

var address = AudioObjectPropertyAddress(
    mSelector: kAudioDevicePropertyBufferFrameSize,
    mScope: kAudioObjectPropertyScopeInput,
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

    print("Input buffer frames:", frames)
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
    print(
        "Moo callback:",
        sampleCount,
        "float samples"
    )
}

        var peak: Float = 0

        for i in 0..<sampleCount {

            let normalized = abs(samples[i])

            if normalized > peak {
                peak = normalized
            }

            if peak > capture.highestPeak {
                capture.highestPeak = peak
            }
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

if capture.shouldDownsample {

    capture.audioBuffer.write(
        capture.downsampleTo8kMono(
            capturedSamples
        )
    )

} else {

    capture.audioBuffer.write(
        capture.upsampleTo48kStereo(
            capturedSamples
        )
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

private func downsampleTo8kMono(
    _ samples: [Float]
) -> [Float] {

    let inputRate: Float = 44100
    let outputRate: Float = 8000

    let step = inputRate / outputRate

    var output: [Float] = []

    var position: Float = 0

    let frameCount = samples.count / 2

    while Int(position) + 1 < frameCount {

        let frame = Int(position)

        let fraction = position - Float(frame)

        let left0 = samples[frame * 2]
        let left1 = samples[(frame + 1) * 2]

        let right0 = samples[frame * 2 + 1]
        let right1 = samples[(frame + 1) * 2 + 1]

        let left =
            left0 + (left1 - left0) * fraction

        let right =
            right0 + (right1 - right0) * fraction

        output.append(
    	    left + right
	)

        position += step
    }

    return output
}

private let upsampler = AudioResampler(
    inputSampleRate: 8000,
    outputSampleRate: 48000
)

private func upsampleTo48kStereo(
    _ samples: [Float]
) -> [Float] {

    return upsampler.process(samples)
}

}
