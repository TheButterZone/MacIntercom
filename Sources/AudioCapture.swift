import Foundation
import CoreAudio

final class AudioCapture {

    let device: AudioDevice

    private var ioProcID: AudioDeviceIOProcID?
    private var callbackCount = 0

    init(device: AudioDevice) {
        self.device = device
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

if capture.callbackCount % 500 == 0 {

    let bufferList = UnsafeMutableAudioBufferListPointer(
        UnsafeMutablePointer(mutating: inInputData)
    )

    if let data = bufferList[0].mData {

        let samples = data.assumingMemoryBound(
            to: Int32.self
        )

        let sampleCount = Int(
            bufferList[0].mDataByteSize
        ) / MemoryLayout<Float>.size

        var peak: Float = 0

        for i in 0..<sampleCount {

            if i == 0 {
                print("Input first sample: \(samples[i])")
            }

            let normalized = abs(Float(samples[i])) / Float(Int32.max)

            if normalized > peak {
                peak = normalized
            }
        }

        print("Input peak level: \(peak)")
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
