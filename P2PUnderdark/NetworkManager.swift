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
    var connectedUsers: MutableProperty<[User]> = MutableProperty([User]())
    required public init(inMode: NetworkMode) {
        print("INIT")
        super.init()
        mode = inMode
        var buf : Int64 = 0;
        repeat {
            arc4random_buf(&buf, sizeofValue(buf))
        } while buf == 0;
        if(buf < 0) {
            buf = -buf;
        }
        nodeId = buf
        let transportKinds = [UDTransportKind.Wifi.rawValue, UDTransportKind.Bluetooth.rawValue];
        transport = UDUnderdark.configureTransportWithAppId(appId, nodeId: nodeId, delegate: self, queue: queue, kinds: transportKinds)
        transport?.start()
        lastIncommingMessage.signal
            .observeNext {self.inbox.value.append($0)}
        
        connectedUsers.signal.observeNext({_ in
            print("Users value changed")
        })

    }
    deinit {
        transport?.stop()
    }
    func broadcastFrame(text: String) {
        let data = text.dataUsingEncoding(NSUTF8StringEncoding) ?? NSData()
        if !connectedUsers.value.isEmpty {
            for user in connectedUsers.value {
                user.link.sendFrame(data)
            }
        }
    }
    func broadcastType() {
        let text = mode.rawValue + "_" + UIDevice.currentDevice().identifierForVendor!.UUIDString
        let data = text.dataUsingEncoding(NSUTF8StringEncoding) ?? NSData()
        if !links.isEmpty {
            for link in links {
                link.sendFrame(data)
            }
        }
    }
    func clearInbox() {
        inbox.value = []
    }
    // MARK: Delegate
    public func transport(transport: UDTransport!, link: UDLink!, didReceiveFrame frameData: NSData!) {
        let message = String(data: frameData, encoding: NSUTF8StringEncoding) ?? ""
        lastIncommingMessage.value = message
        print("did recieve frame with value \(message) from link ]\(link.nodeId)")
        if message.containsString("host_") {
            let id = message.stringByReplacingOccurrencesOfString("host_", withString: "")
            addUser(User(_id: id, _link: link, _mode: .Host))
            
        } else if message.containsString("client_") {
            let id = message.stringByReplacingOccurrencesOfString("client_", withString: "")
            addUser(User(_id: id, _link: link, _mode: .Client))
        } else {
            // do something with message
        }
        for var i = 0; i < connectedUsers.value.count; ++i {
            connectedUsers.value[i].printInfo()
            
        }
        print("number of users \(connectedUsers.value.count)")
    }
    
    public func transport(transport: UDTransport!, linkConnected link: UDLink!) {
        // check if link belongs to prexisting user, if not then add
        for var i = 0; i < connectedUsers.value.count; ++i {
            if link.nodeId == connectedUsers.value[i].link.nodeId {
                return
            }
        }
        
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
    private func removeUser(user: User) {
        for var i = 0; i < connectedUsers.value.count; ++i {
            if user.id == connectedUsers.value[i].id {
                connectedUsers.value.removeAtIndex(i)
            }
        }
    }
    private func addUser(user: User) {
        for var i = 0; i < connectedUsers.value.count; ++i {
            if user.id == connectedUsers.value[i].id {
                connectedUsers.value[i] = User(_id: user.id, _link: user.link, _mode: user.mode)
                return
            }
        }
        connectedUsers.value.append(user)
    }
    private func removeLink(link: UDLink) {
        for var i = 0; i < links.count; ++i {
            if link.nodeId == links[i].nodeId {
                links.removeAtIndex(i)
            }
        }
        for var i = 0; i < connectedUsers.value.count; ++i {
            if connectedUsers.value[i].link.nodeId == link.nodeId {
                removeUser(connectedUsers.value[i])
            }
        }
    }
    private func addLink(link: UDLink) {
       // if link already in list, return
        for var i = 0; i < links.count; ++i {
            if link.nodeId == links[i].nodeId {
                return
            }
        }
        links.append(link)
        print("Links: ")
        for var i = 0; i < links.count; ++i {
            print("Link \(links[i].nodeId)")
        }
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
