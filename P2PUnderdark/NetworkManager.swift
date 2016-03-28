import Foundation
import Underdark
import ReactiveCocoa



public class NetworkManager: NSObject, UDTransportDelegate {
    // MARK: Public Vars
    public let usersInRange: MutableProperty<[User]> = MutableProperty([User]())
    public var connectedPeers: MutableProperty<[User]> =  MutableProperty([User]())
    public let inbox: MutableProperty<[String]> = MutableProperty([])
    // MARK: Private Vars
    private var links: [UDLink] = []
    private var appId: Int32 = 123456
    private var nodeId: Int64 = 0
    private var transport: UDTransport!
    private let queue = dispatch_get_main_queue()
    private let lastIncommingMessage: MutableProperty<String> = MutableProperty("")
    private let deviceId = UIDevice.currentDevice().identifierForVendor!.UUIDString
    var mode: NetworkMode!
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
        usersInRange.value = []
        usersInRange.signal
            .observeNext{userList in
                var hostList = [User]()
                for user in userList {
                    if user.mode == .Host || user.connected {
                        hostList.append(user)
                    }
                }
                self.connectedPeers.value = hostList
                print("USER COUNT: \(self.usersInRange.value.count)")
            }
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
            addUser(User(_id: id, _link: link, _mode: .Host, isConnected: false))
            
        } else if message.containsString("client_") {
            let id = message.stringByReplacingOccurrencesOfString("client_", withString: "")
            addUser(User(_id: id, _link: link, _mode: .Client, isConnected: false))
        } else if message.containsString("connection_request") {
            let device = message.stringByReplacingOccurrencesOfString("connection_request_", withString: "")
            let user = User(_id: device, _link: link, _mode: NetworkMode.Client, isConnected: false)
            let alertController = UIAlertController()
            alertController.title = "Connection Request"
            alertController.message = "Click 'Yes' to allow user to connect to you and 'Decline' to prevent access from the user."
            let acceptAction = UIAlertAction(title: "Accept", style: UIAlertActionStyle.Default , handler: {_ in
                self.authenticateUser(user)
            })
            let declineAction = UIAlertAction(title: "Decline", style: UIAlertActionStyle.Cancel, handler: nil)
            alertController.addAction(acceptAction)
            alertController.addAction(declineAction)
            UIApplication.sharedApplication().keyWindow?.rootViewController?.presentViewController(alertController, animated: true, completion: nil)
        } else if message.containsString("allow_") {
            let userId = message.stringByReplacingOccurrencesOfString("allow_", withString: "")
            let user = User(_id: userId, _link: link, _mode: NetworkMode.Host, isConnected: true)
            for var i = 0; i < usersInRange.value.count; ++i {
                if user.id == self.usersInRange.value[i].id {
                    self.usersInRange.value.removeAtIndex(i)
                }
            }
            self.usersInRange.value.append(user)
            // notify other use this user has connected to the other
            self.notifyConnected(user)
        } else if message.containsString("connected_") {
            let userId = message.stringByReplacingOccurrencesOfString("connected_", withString: "")
            let user = User(_id: userId, _link: link, _mode: NetworkMode.Client, isConnected: true)
            for var i = 0; i < usersInRange.value.count; ++i {
                if user.id == self.usersInRange.value[i].id {
                    self.usersInRange.value.removeAtIndex(i)
                }
            }
            self.usersInRange.value.append(user)
        }
        else {
            // handle message
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
        broadcastType()
    }
    public func transport(transport: UDTransport!, linkDisconnected link: UDLink!) {
        removeLink(link)
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
    public func broadcastType() {
        let text = mode.rawValue + "_" + UIDevice.currentDevice().identifierForVendor!.UUIDString
        let data = text.dataUsingEncoding(NSUTF8StringEncoding) ?? NSData()
        if !links.isEmpty {
            for link in links {
                link.sendFrame(data)
            }
        }
        print("broadcasting type...")
    }
    private func authenticateUser(user: User) {
        let data = ("allow_\(deviceId)").dataUsingEncoding(NSUTF8StringEncoding) ?? NSData()
        user.link.sendFrame(data)
    }
    private func notifyConnected(user: User) {
        let data = ("connected_\(deviceId)").dataUsingEncoding(NSUTF8StringEncoding) ?? NSData()
        user.link.sendFrame(data)
    }
    // MARK: Public Functions
    public func startScanningAsClient() {
        usersInRange.value = []
        mode = .Client
        broadcastType()
        
    }
    public func startAdvertisingAsHost() {
        usersInRange.value = []
        mode = .Host
        broadcastType()
    }
    func sendMessageToPeers(text: String) {
        let data = text.dataUsingEncoding(NSUTF8StringEncoding) ?? NSData()
        if !connectedPeers.value.isEmpty {
            for peer in connectedPeers.value {
                if peer.connected {
                    peer.link.sendFrame(data)
                }
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
}
