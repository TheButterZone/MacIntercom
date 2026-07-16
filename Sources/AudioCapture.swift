import Foundation
import CoreAudio

final class AudioCapture {

    let device: AudioDevice
    let audioBuffer: AudioBuffer

    private var ioProcID: AudioDeviceIOProcID?

    private var currentGain: Float = 1.0
    private var smoothedPeak: Float = 0.05

    private var processCount = 0
    private var callbackCount = 0
    private var highestPeak: Float = 0
    private var highestProcessedPeak: Float = 0

    var onFirstCallback: (() -> Void)?
    private var hasReportedFirstCallback = false

private let shouldDownsample: Bool
private let outputDevice: AudioDevice
private let upsampler = AudioResampler(
    inputSampleRate: 8000,
    outputSampleRate: 48000
)

init(
    device: AudioDevice,
    outputDevice: AudioDevice,
    audioBuffer: AudioBuffer,
    shouldDownsample: Bool
) {

    self.device = device
    self.outputDevice = outputDevice
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

        Logger.audio("Starting capture:")
        Logger.audio("  Device: \(device.name)")
        Logger.audio("  ID: \(device.id)")

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

    Logger.audio(
    "Input buffer frames: \(frames)"
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

                if let clientData = clientData {

                    let capture = Unmanaged<AudioCapture>
                        .fromOpaque(clientData)
                        .takeUnretainedValue()

                    capture.callbackCount += 1

    let bufferList = UnsafeMutableAudioBufferListPointer(
        UnsafeMutablePointer(mutating: inInputData)
    )

if capture.callbackCount == 1 {
    print("Audio buffers:", bufferList.count)

    for (index, buffer) in bufferList.enumerated() {
        print(
            "Buffer",
            index,
            "bytes:",
            buffer.mDataByteSize
        )
    }
}

    if let data = bufferList[0].mData {

        let samples = data.assumingMemoryBound(
            to: Float.self
        )

if !capture.hasReportedFirstCallback {

    capture.hasReportedFirstCallback = true

    DispatchQueue.main.async {

        capture.onFirstCallback?()

    }
}

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
            Logger.levels("Highest input peak: \(capture.highestPeak)")
            capture.highestPeak = 0
        }        

        let capturedSamples = Array(
            UnsafeBufferPointer(
                start: samples,
                count: sampleCount
            )
        )

if capture.shouldDownsample {

    let mono8k = capture.downsampleTo8kMono(
        capturedSamples
    )

    let leveled = capture.applyAutomaticGain(
        mono8k
    )

for sample in leveled {
    let peak = abs(sample)

    if peak > capture.highestProcessedPeak {
        capture.highestProcessedPeak = peak
    }
}

if capture.callbackCount % 500 == 0 {
    Logger.levels("Highest processed peak: \(capture.highestProcessedPeak)")
    capture.highestProcessedPeak = 0
}

if capture.callbackCount % 500 == 0 {
    Logger.levels(
	"Gain: \(capture.currentGain) Peak: \(capture.smoothedPeak)"
    )
}

Logger.info(
    "WRITE BUFFER: \(Unmanaged.passUnretained(capture.audioBuffer).toOpaque())"
)

    capture.audioBuffer.write(
        leveled
    )

} else {

    let stereo48k = capture.upsampleTo48kStereo(
        capturedSamples
    )

    let leveled = capture.applyAutomaticGain(
        stereo48k
    )

for sample in leveled {
    let peak = abs(sample)

    if peak > capture.highestProcessedPeak {
        capture.highestProcessedPeak = peak
    }
}

if capture.callbackCount % 500 == 0 {
    print("Highest processed peak: \(capture.highestProcessedPeak)")
    capture.highestProcessedPeak = 0
}

if capture.callbackCount % 500 == 0 {
    print(
        "Gain:",
        capture.currentGain,
        "Peak:",
        capture.smoothedPeak
    )
}

    capture.audioBuffer.write(
        leveled
    )

if capture.callbackCount % 100 == 0 {

    Logger.queue(
	"BT queue: \(capture.audioBuffer.sampleCount())"
)
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
    print("Failed to create IOProc: \(status)")
    return
}

let shouldStart: Bool

if device.transport == "Bluetooth" {

    shouldStart =
        DebugFlags.enableBluetoothCapture

} else {

    shouldStart =
        DebugFlags.enableComputerCapture

}

if shouldStart {

    let startStatus = AudioDeviceStart(
        device.id,
        ioProcID!
    )

    if startStatus != noErr {

        print(
            "Failed to start device: \(startStatus)"
        )

    }

} else {

    Logger.info(
        "DEBUG: Capture disabled for \(device.name)"
    )

}

}

private func applyAutomaticGain(
    _ samples: [Float]
) -> [Float] {

    var output = samples

    // Find the loudest sample in this buffer.
    var bufferPeak: Float = 0

    for sample in output {
        bufferPeak = max(bufferPeak, abs(sample))
    }

    // Update the envelope once per buffer.
    smoothedPeak =
        smoothedPeak * 0.95 +
        bufferPeak * 0.05

let targetLevel: Float = 0.35
let minimumSignalLevel: Float = 0.02

var targetGain: Float

if smoothedPeak > minimumSignalLevel {

    targetGain =
        targetLevel / smoothedPeak

} else {

    targetGain = max(
        1.0,
        currentGain * 0.999
    )
}

targetGain = min(
    targetGain,
    20.0
)

    currentGain +=
        (targetGain - currentGain) * 0.01

    let maxOutput: Float = 0.8

    for i in 0..<output.count {

        var sample =
            output[i] * currentGain

        sample = max(
            -maxOutput,
            min(
                maxOutput,
                sample
            )
        )

        output[i] = sample
    }

    return output
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

let mono: Float

let leftLevel = abs(left)
let rightLevel = abs(right)

if leftLevel > rightLevel * 2 {
    mono = left
}
else if rightLevel > leftLevel * 2 {
    mono = right
}
else {
    mono = (left + right) * 0.5
}

output.append(
    max(-1.0, min(1.0, mono))
)

        position += step
    }

    return output
}

private func upsampleTo48kStereo(
    _ samples: [Float]
) -> [Float] {

    let mono = upsampler.process(samples)

    var stereo: [Float] = []
    stereo.reserveCapacity(mono.count * 2)

    for sample in mono {
        stereo.append(sample) // Left
        stereo.append(sample) // Right
    }

return stereo
}

}
