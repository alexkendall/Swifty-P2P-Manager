import Foundation
import Underdark
import ReactiveCocoa

public enum NetworkMode: String {
    case Host = "host"
    case Client = "client"
}
var mode: NetworkMode!

public
class NetworkManager: NSObject, UDTransportDelegate {
    var links: [UDLink] = []
    var peersCount = 0
    var appId: Int32 = 123456
    var nodeId: Int64 = 0
    var transport: UDTransport? = nil
    let queue = dispatch_get_main_queue()
    let lastIncommingMessage: MutableProperty<String> = MutableProperty("")
    let inbox: MutableProperty<[String]> = MutableProperty([])
    var connectedUsers = [User]()
    required public init(inMode: NetworkMode) {
        super.init()
        mode = inMode
        var buf : Int64 = 0;
        repeat {
            arc4random_buf(&buf, sizeofValue(buf))
        } while buf == 0;
        if(buf < 0) {
            buf = -buf;
        }
        nodeId = buf;
        let transportKinds = [UDTransportKind.Wifi.rawValue, UDTransportKind.Bluetooth.rawValue];
        transport = UDUnderdark.configureTransportWithAppId(appId, nodeId: nodeId, delegate: self, queue: queue, kinds: transportKinds)
        transport?.start()
        lastIncommingMessage.signal
            .observeNext {self.inbox.value.append($0)}
        
    }
    deinit {
        transport?.stop()
    }
    func broadcastFrame(text: String) {
        let data = text.dataUsingEncoding(NSUTF8StringEncoding) ?? NSData()
        if !links.isEmpty {
            for link in links {
                link.sendFrame(data)
            }
        }
    }
    func broadcastType() {
        broadcastFrame(mode.rawValue + "_" + UIDevice.currentDevice().identifierForVendor!.UUIDString)
    }
    func clearInbox() {
        inbox.value = []
    }
    // MARK: Delegate
    public func transport(transport: UDTransport!, link: UDLink!, didReceiveFrame frameData: NSData!) {
        let message = String(data: frameData, encoding: NSUTF8StringEncoding) ?? ""
        lastIncommingMessage.value = message
        print("did recieve frame with value \(message)")
        if message.containsString("host_") {
            let id = message.stringByReplacingOccurrencesOfString("host_", withString: "")
            addUser(User(_id: id, _link: link, _mode: .Host))
            
        } else if message.containsString("client_") {
            let id = message.stringByReplacingOccurrencesOfString("client_", withString: "")
            addUser(User(_id: id, _link: link, _mode: .Client))
        } else {
            // do something with message
        }
        for var i = 0; i < connectedUsers.count; ++i {
            connectedUsers[i].printInfo()
            
        }
        print("number of users \(connectedUsers.count)")
    }
    
    public func transport(transport: UDTransport!, linkConnected link: UDLink!) {
        addLink(link)
        ++peersCount
        print("connected to link..\(link.nodeId)")
        broadcastType()
    }
    
    public func transport(transport: UDTransport!, linkDisconnected link: UDLink!) {
        removeLink(link)
        --peersCount
        print("Disconnected from link...\(link.nodeId)")
        
    }

    // MARK: Provate functions
    func removeUser(user: User) {
        for var i = 0; i < connectedUsers.count; ++i {
            if user.id == connectedUsers[i].id {
                connectedUsers.removeAtIndex(i)
            }
        }
    }
    func addUser(user: User) {
        for var i = 0; i < connectedUsers.count; ++i {
            if user.id == connectedUsers[i].id {
                connectedUsers[i].mode = user.mode
                return
            }
        }
        connectedUsers.append(user)
    }
    func removeLink(link: UDLink) {
        for var i = 0; i < links.count; ++i {
            if link.nodeId == links[i].nodeId {
                links.removeAtIndex(i)
            }
        }
    }
    func addLink(link: UDLink) {
        for var i = 0; i < links.count; ++i {
            if link.nodeId == links[i].nodeId {
                return
            }
        }
        links.append(link)
    }
}

class User {
    var link:UDLink!
    var mode: NetworkMode!
    var id: String
    init(_id: String, _link: UDLink!,_mode: NetworkMode) {
        link = _link
        mode = _mode
        id = _id
    }
    func printInfo() {
        print("User\nId: \(id)\nNodeId: \(link.nodeId)\nType: \(mode.rawValue)")
    }
}
