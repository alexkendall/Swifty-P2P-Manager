import UIKit
import Foundation
import Underdark

public enum NetworkMode: String {
    case Host = "host"
    case Client = "client"
}

public class User {
    var link:UDLink!
    var mode: NetworkMode!
    var id: String
    var connected: Bool = false
    init(_id: String, _link: UDLink!,_mode: NetworkMode, isConnected: Bool) {
        link = _link
        mode = _mode
        id = _id
        connected = isConnected
        printInfo()
    }
    func printInfo() {
        print("User\nId: \(id)\nNodeId: \(link.nodeId)\nType: \(mode.rawValue)\nConnected: \(connected)")
    }
}