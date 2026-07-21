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
private var upsampler: AudioResampler

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

    if shouldDownsample {

        self.upsampler = AudioResampler(
            inputSampleRate: 8000,
            outputSampleRate: outputDevice.sampleRate
        )

    } else {

        self.upsampler = AudioResampler(
            inputSampleRate: device.sampleRate,
            outputSampleRate: outputDevice.sampleRate
        )

    }
}

private func printStreamFormat() {

var address = CoreAudioHelpers.address(
    selector: kAudioDevicePropertyStreamFormat,
    scope: kAudioDevicePropertyScopeInput
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
DebugTelemetry.capture.log(
    """
STREAM FORMAT
device=\(device.name)
sampleRate=\(format.mSampleRate)
formatID=\(format.mFormatID)
flags=\(format.mFormatFlags)
bits=\(format.mBitsPerChannel)
channels=\(format.mChannelsPerFrame)
bytesPerFrame=\(format.mBytesPerFrame)
"""
)
        } else {
            print("Stream format error: \(status)")
        }
    }

    func start() {

        Logger.audio("Starting capture:")
        Logger.audio("  Device: \(device.name)")
        Logger.audio("  ID: \(device.id)")

printStreamFormat()

var address = CoreAudioHelpers.address(
    selector: kAudioDevicePropertyBufferFrameSize,
    scope: kAudioObjectPropertyScopeInput
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

            capture.captureInput(inInputData)
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

private func captureInput(
    _ inInputData: UnsafePointer<AudioBufferList>?
) {

    guard let inInputData = inInputData else {
        return
    }

    self.callbackCount += 1

let bufferList = UnsafeMutableAudioBufferListPointer(
    UnsafeMutablePointer(mutating: inInputData)
)

if self.callbackCount == 1 {

    DebugTelemetry.capture.log(
        "Audio buffers: \(bufferList.count)"
    )

    for (index, buffer) in bufferList.enumerated() {

        DebugTelemetry.capture.log(
            """
            Buffer
            index=\(index)
            bytes=\(buffer.mDataByteSize)
            channels=\(buffer.mNumberChannels)
            """
        )
    }
}

    if let data = bufferList[0].mData {

        let samples = data.assumingMemoryBound(
            to: Float.self
        )

if !self.hasReportedFirstCallback {

    self.hasReportedFirstCallback = true

    DispatchQueue.main.async {

        self.onFirstCallback?()

    }
}

        let sampleCount = Int(
            bufferList[0].mDataByteSize
        ) / MemoryLayout<Float>.size

if self.callbackCount == 1 {
print(
    "\(device.name) callback:",
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

            if peak > self.highestPeak {
                self.highestPeak = peak
            }
        }

if self.callbackCount % 500 == 0 {
    print("Highest input peak: \(self.highestPeak)")
    self.highestPeak = 0
}     

if self.callbackCount % 100 == 0 {

    DebugTelemetry.capture.log(
        """
RAW CAPTURE
device=\(device.name)
rate=\(device.sampleRate)
samples=\(sampleCount)
channels=\(bufferList[0].mNumberChannels)
"""
    )

}

        let capturedSamples = Array(
            UnsafeBufferPointer(
                start: samples,
                count: sampleCount
            )
        )

if self.callbackCount % 100 == 0 {

    DebugTelemetry.capture.log(
        """
CAPTURE
device=\(device.name)
samples=\(sampleCount)
downsample=\(self.shouldDownsample)
highestInputPeak=\(self.highestPeak)
queue=\(self.audioBuffer.sampleCount())
"""
    )
}

if self.shouldDownsample {

let mono8k = self.downsampleTo8kMono(
    capturedSamples
)

let leveled = applyAutomaticGain(mono8k)

if self.callbackCount % 100 == 0 {
    DebugTelemetry.capture.log(
        """
AGC
device=\(device.name)
gain=\(self.currentGain)
peak=\(self.smoothedPeak)
"""
    )
}

if self.callbackCount % 100 == 0 {

    DebugTelemetry.capture.log(
        "DOWNSAMPLED=\(mono8k.count)"
    )

}

for sample in leveled {

    let peak = abs(sample)

    if peak > self.highestProcessedPeak {
        self.highestProcessedPeak = peak
    }
}

if self.callbackCount % 500 == 0 {
    Logger.levels(
        "Highest processed peak: \(self.highestProcessedPeak)"
    )
    self.highestProcessedPeak = 0
}

if self.callbackCount % 500 == 0 {
    Logger.levels(
        "Gain: \(self.currentGain) Peak: \(self.smoothedPeak)"
    )
}

DebugTelemetry.capture.log(
    """
CTOB
mono8k=\(mono8k.count)
leveled=\(leveled.count)
queue=\(self.audioBuffer.sampleCount())
"""
)

self.audioBuffer.write(
    leveled
)

} else {

let mono44100 = self.resampleToOutputStereo(
    capturedSamples
)

var peak: Float = 0

for sample in mono44100 {
    peak = max(peak, abs(sample))
}

if callbackCount % 100 == 0 {

    DebugTelemetry.output.log(
        """
BTOC
peak=\(peak)
samples=\(mono44100.count)
queue=\(self.audioBuffer.sampleCount())
"""
    )
}

let leveled = applyAutomaticGain(mono44100)

if self.callbackCount % 100 == 0 {
    DebugTelemetry.capture.log(
        """
AGC
device=\(device.name)
gain=\(self.currentGain)
peak=\(self.smoothedPeak)
"""
    )
}

for sample in leveled {
    let peak = abs(sample)

    if peak > self.highestProcessedPeak {
        self.highestProcessedPeak = peak
    }
}

if self.callbackCount % 500 == 0 {
    print("Highest processed peak: \(self.highestProcessedPeak)")
    self.highestProcessedPeak = 0
}

if self.callbackCount % 500 == 0 {
    print(
        "Gain:",
        self.currentGain,
        "Peak:",
        self.smoothedPeak
    )
}

    self.audioBuffer.write(
        leveled
    )

}

if self.callbackCount % 100 == 0 {
    Logger.queue(
        "BT queue: \(self.audioBuffer.sampleCount())"
    )
}

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

let inputRate = Float(device.sampleRate)
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

private func resampleToOutputStereo(
    _ samples: [Float]
) -> [Float] {

    let output = upsampler.process(samples)

    DebugTelemetry.capture.log(
        """
BT RESAMPLE OUTPUT
inputSamples=\(samples.count)
outputSamples=\(output.count)
"""
    )

    return output
}

}