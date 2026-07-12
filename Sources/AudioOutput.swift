import Foundation
import CoreAudio

final class AudioOutput {

    let device: AudioDevice

    private var ioProcID: AudioDeviceIOProcID?
    private var callbackCount = 0

    init(device: AudioDevice) {
        self.device = device
    }

    func start() {

        print("Starting output:")
        print("  Device: \(device.name)")
        print("  ID: \(device.id)")

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

            let output = Unmanaged<AudioOutput>
                .fromOpaque(clientData)
                .takeUnretainedValue()

            output.callbackCount += 1

            if output.callbackCount % 500 == 0 {
                print("Output callbacks received: \(output.callbackCount)")
            }
        }

        let buffers = UnsafeMutableAudioBufferListPointer(
            outOutputData
        )

        for buffer in buffers {
            memset(
                buffer.mData,
                0,
                Int(buffer.mDataByteSize)
            )
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
