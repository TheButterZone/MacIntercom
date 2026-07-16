import Foundation

guard let bluetoothRoute =
    AudioInspector.bluetoothToComputerRoute()
else {
    Logger.error("No Bluetooth → Computer route")
    exit(1)
}

guard let computerRoute =
    AudioInspector.computerToBluetoothRoute()
else {
    Logger.error("No Computer → Bluetooth route")
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

let computerToBluetooth = IntercomEngine(
    name: "Computer→BT",
    route: computerRoute,
    shouldDownsample: true,
    primeBuffer: false
)

let bluetoothToComputer = IntercomEngine(
    name: "BT→Computer",
    route: bluetoothRoute,
    shouldDownsample: false,
    primeBuffer: true
)

computerToBluetooth.capture.onFirstCallback = {

    Logger.info("Computer capture is alive; starting Bluetooth engine")

    bluetoothToComputer.start()

}

bluetoothToComputer.capture.onFirstCallback = {

    Logger.info("Bluetooth capture callback received")

}

computerToBluetooth.start()

//MediaRemoteObserver.shared.start()

//let conversationController =
//    ConversationController()

//DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
//
//    Logger.info("TEST: Begin conversation")
//
//    conversationController.begin(
//        trigger: .app
//    )
//
//}
//
//DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
//
//    Logger.info("TEST: End conversation")
//
//    conversationController.end(
//        trigger: .app
//    )
//
//}

RunLoop.main.run()
