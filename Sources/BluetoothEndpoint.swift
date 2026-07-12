import Foundation

struct BluetoothEndpoint {

    let baseUID: String
    let name: String

    var input: AudioDevice?
    var output: AudioDevice?

}
