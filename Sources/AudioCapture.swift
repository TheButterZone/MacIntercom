import Foundation
import CoreAudio

final class AudioCapture {

    let device: AudioDevice

    private var ioProcID: AudioDeviceIOProcID?
    private var callbackCount = 0

    init(device: AudioDevice) {
        self.device = device
    }

    func start() {

        print("Starting capture:")
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

    let capture = Unmanaged<AudioCapture>
        .fromOpaque(clientData)
        .takeUnretainedValue()

    capture.callbackCount += 1

    if capture.callbackCount % 500 == 0 {
        print("Callbacks received: \(capture.callbackCount)")
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
