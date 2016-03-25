import Foundation
import Underdark
import ReactiveCocoa

public enum NetworkMode: String {
    case Host = "host"
    case Client = "client"
    case Peer = "peer"
}
var mode: NetworkMode!

public
class DiscoveryManager: NSObject, UDTransportDelegate {
    // MARK: Public Vars
    public let peers: MutableProperty<[User]> = MutableProperty([User]())
    public let usersInRange: MutableProperty<[User]> = MutableProperty([User]())
    // MARK: Private Vars
    private var links: [UDLink] = []
    var peersCount = 0
    private var appId: Int32 = 123456
    private var nodeId: Int64 = 0
    private var transport: UDTransport!
    private let queue = dispatch_get_main_queue()
    private let lastIncommingMessage: MutableProperty<String> = MutableProperty("")
    public let inbox: MutableProperty<[String]> = MutableProperty([])
    private let deviceId = UIDevice.currentDevice().identifierForVendor!.UUIDString
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
        nodeId = buf
        let transportKinds = [UDTransportKind.Wifi.rawValue, UDTransportKind.Bluetooth.rawValue];
        transport = UDUnderdark.configureTransportWithAppId(appId, nodeId: nodeId, delegate: self, queue: queue, kinds: transportKinds)
        lastIncommingMessage.signal
            .observeNext {self.inbox.value.append($0)}
        transport.start()
    }
    deinit {
        transport?.stop()
    }
    // MARK: Delegate
    public func transport(transport: UDTransport!, link: UDLink!, didReceiveFrame frameData: NSData!) {
        let message = String(data: frameData, encoding: NSUTF8StringEncoding) ?? ""
        lastIncommingMessage.value = message
        if message.containsString("host_") {
            let id = message.stringByReplacingOccurrencesOfString("host_", withString: "")
            addUser(User(_id: id, _link: link, _mode: .Host))
            
        } else if message.containsString("client_") {
            let id = message.stringByReplacingOccurrencesOfString("client_", withString: "")
            addUser(User(_id: id, _link: link, _mode: .Client))
        } else if message.containsString("connection_request") {
            let device = message.stringByReplacingOccurrencesOfString("connection_request_", withString: "")
            let user = User(_id: device, _link: link, _mode: NetworkMode.Peer)
            let alertController = UIAlertController()
            let acceptAction = UIAlertAction(title: "Accept", style: UIAlertActionStyle.Default , handler: {_ in
                for peer in self.peers.value {
                    if peer.id == user.id {
                        return
                    }
                }
                self.peers.value.append(user)
                print("added peer to peer table")
                for peer in self.peers.value {
                    peer.printInfo()
                }
                self.authenticateUser(user)
            })
            let declineAction = UIAlertAction(title: "Decline", style: UIAlertActionStyle.Cancel, handler: nil)
            alertController.addAction(acceptAction)
            alertController.addAction(declineAction)
            UIApplication.sharedApplication().keyWindow?.rootViewController?.presentViewController(alertController, animated: true, completion: nil)
        } else if message.containsString("allow_") {
            let userId = message.stringByReplacingOccurrencesOfString("allow_", withString: "")
            let user = User(_id: userId, _link: link, _mode: NetworkMode.Peer)
            for peer in self.peers.value {
                if peer.id == user.id {
                    return
                }
            }
            self.peers.value.append(user)
            print("added peer to peer table (allow)")
            for peer in self.peers.value {
                peer.printInfo()
            }
        }
        else {
            print("MESSAGE RECIEVED \(message)")
        }
    }
    
    public func transport(transport: UDTransport!, linkConnected link: UDLink!) {
        // check if link belongs to prexisting user, if not then add
        for var i = 0; i < usersInRange.value.count; ++i {
            if link.nodeId == usersInRange.value[i].link.nodeId {
                return
            }
        }
        addLink(link)
        ++peersCount
        broadcastType()
    }
    
    public func transport(transport: UDTransport!, linkDisconnected link: UDLink!) {
        removeLink(link)
        --peersCount
    }
    // MARK: Private functions
    private func removeUser(user: User) {
        for var i = 0; i < usersInRange.value.count; ++i {
            if user.id == usersInRange.value[i].id {
                usersInRange.value.removeAtIndex(i)
            }
        }
    }
    private func addUser(user: User) {
        for var i = 0; i < usersInRange.value.count; ++i {
            if user.id == usersInRange.value[i].id {
                usersInRange.value[i] = user
                return
            }
        }
        usersInRange.value.append(user)
    }
    private func removeLink(link: UDLink) {
        for var i = 0; i < links.count; ++i {
            if link.nodeId == links[i].nodeId {
                links.removeAtIndex(i)
            }
        }
        for var i = 0; i < usersInRange.value.count; ++i {
            if usersInRange.value[i].link.nodeId == link.nodeId {
                removeUser(usersInRange.value[i])
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
    }
    private func broadcastType() {
        let text = mode.rawValue + "_" + UIDevice.currentDevice().identifierForVendor!.UUIDString
        let data = text.dataUsingEncoding(NSUTF8StringEncoding) ?? NSData()
        if !links.isEmpty {
            for link in links {
                link.sendFrame(data)
            }
        }
    }
    // MARK: Public Functions
    public func startScanningAsClient() {
        mode = .Client
        broadcastType()
        
    }
    public func startAdvertisingAsHost() {
        mode = .Host
        broadcastType()
    }
    func sendMessageToPeers(text: String) {
        let data = text.dataUsingEncoding(NSUTF8StringEncoding) ?? NSData()
        if !peers.value.isEmpty {
            for peer in peers.value {
                peer.link.sendFrame(data)
            }
        }
    }
    func clearInbox() {
        inbox.value = []
    }
    func askToConnectToPeer(user: User) {
        let data = ("connection_request_\(deviceId)").dataUsingEncoding(NSUTF8StringEncoding) ?? NSData()
        user.link.sendFrame(data)
    }
    func authenticateUser(user: User) {
        let data = ("allow_\(deviceId)").dataUsingEncoding(NSUTF8StringEncoding) ?? NSData()
        user.link.sendFrame(data)
    }
}

public class User {
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
