import Foundation

guard let bluetoothRoute =
    AudioInspector.bluetoothToComputerRoute()
else {
    print("No Bluetooth → Computer route")
    exit(1)
}

guard let computerRoute =
    AudioInspector.computerToBluetoothRoute()
else {
    print("No Computer → Bluetooth route")
    exit(1)
}

print("Bluetooth route:")
print("  Input : \(bluetoothRoute.input.name)")
print("  Output: \(bluetoothRoute.output.name)")

print("Computer route:")
print("  Input : \(computerRoute.input.name)")
print("  Output: \(computerRoute.output.name)")

AudioInspector.printBufferFrameSize(
    bluetoothRoute.input
)

AudioInspector.printBufferFrameSize(
    bluetoothRoute.output
)

AudioInspector.printBufferFrameSize(
    computerRoute.input
)

AudioInspector.printBufferFrameSize(
    computerRoute.output
)

let computerEngine =
    ComputerToBluetoothEngine(
        route: computerRoute
    )

let bluetoothEngine =
    BluetoothToComputerEngine(
        route: bluetoothRoute
    )

print("STARTING ComputerToBluetoothEngine")
computerEngine.start()

print("STARTING BluetoothToComputerEngine")
bluetoothEngine.start()

RunLoop.main.run()