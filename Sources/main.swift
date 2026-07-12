import Foundation

let devices = AudioInspector.enumerateDevices()

let endpoints = AudioInspector.groupBluetoothEndpoints(devices)

guard let route = AudioInspector.findIntercomRoute(endpoints) else {
    print("No intercom route found")
    exit(1)
}

let engine = AudioEngine(route: route)

engine.start()

RunLoop.main.run()
