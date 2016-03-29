import Foundation
import Underdark
import ReactiveCocoa

var loopNodes = [Int64]()
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
    private var timer: NSTimer = NSTimer()
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
        loopNodes.append(buf)
        let transportKinds = [UDTransportKind.Wifi.rawValue, UDTransportKind.Bluetooth.rawValue];
        transport = UDUnderdark.configureTransportWithAppId(appId, nodeId: nodeId, delegate: self, queue: queue, kinds: transportKinds)
        lastIncommingMessage.signal
            .observeNext {self.inbox.value.append($0)}
        transport.start()
        usersInRange.value = []
        usersInRange.signal
            .observeNext{userList in
                dispatch_async(dispatch_get_main_queue(), {
                    print("signal changed @")
                    var hostList = [User]()
                    for user in userList {
                        if user.mode == .Host || user.connected {
                            hostList.append(user)
                            print("added host to list")
                        }
                    }
                    self.connectedPeers.value = hostList
                })
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
            dispatch_async(dispatch_get_main_queue(), {
                    UIApplication.sharedApplication().keyWindow?.rootViewController?.presentViewController(alertController, animated: true, completion: nil)
            })
        } else if message.containsString("allow_") {
            let userId = message.stringByReplacingOccurrencesOfString("allow_", withString: "")
            let user = User(_id: userId, _link: link, _mode: NetworkMode.Host, isConnected: true)
            dispatch_async(dispatch_get_main_queue(), {
                for i in 0..<self.usersInRange.value.count {
                    if user.id == self.usersInRange.value[i].id {
                        self.usersInRange.value.removeAtIndex(i)
                    }
                }
            })
            self.addUser(user)
            // notify other use this user has connected to the other
            self.notifyConnected(user)
        } else if message.containsString("connected_") {
            let userId = message.stringByReplacingOccurrencesOfString("connected_", withString: "")
            let user = User(_id: userId, _link: link, _mode: NetworkMode.Client, isConnected: true)
            dispatch_async(dispatch_get_main_queue(), {
                for i in 0..<self.usersInRange.value.count {
                    if user.id == self.usersInRange.value[i].id {
                        self.usersInRange.value.removeAtIndex(i)
                    }
                }
            })
            self.addUser(user)
        } else if message.containsString("disconnect_") {
            let userId = message.stringByReplacingOccurrencesOfString("disconnect_", withString: "")
            let user = User(_id: userId, _link: link, _mode: NetworkMode.Client, isConnected: true)
            self.disconnectFromUser(user)
        }
        // handle message
        print("recieved \(message)")
    }
    public func transport(transport: UDTransport!, linkConnected link: UDLink!) {
        // check if link belongs to prexisting user, if not then add
        dispatch_async(dispatch_get_main_queue(), {
            for i in 0..<self.usersInRange.value.count {
                if link.nodeId == self.usersInRange.value[i].link.nodeId || link.nodeId == self.nodeId {
                    return
                }
            }
        })
        addLink(link)
        broadcastType()
    }
    public func transport(transport: UDTransport!, linkDisconnected link: UDLink!) {
        removeLink(link)
    }
    // MARK: Private functions
    private func removeUser(user: User) {
        dispatch_async(dispatch_get_main_queue(), {
            for i in 0..<self.usersInRange.value.count {
                if user.id == self.usersInRange.value[i].id {
                    self.usersInRange.value.removeAtIndex(i)
                }
            }
            self.disconnectFromUser(user)
        })
        
    }
    private func disconnectFromUser(user: User) {
        dispatch_async(dispatch_get_main_queue(), {
            for i in 0..<self.connectedPeers.value.count {
                if user.id == self.connectedPeers.value[i].id {
                    self.connectedPeers.value.removeAtIndex(i)
                }
            }
        })
    }
    private func addUser(user: User) {
        dispatch_async(dispatch_get_main_queue(), {
            for i in 0..<self.usersInRange.value.count {
                if user.id == self.usersInRange.value[i].id {
                    if !self.usersInRange.value[i].connected && user.connected {
                        self.usersInRange.value[i] = user
                        //self.cleanMesh()
                        return
                    } else {
                        return
                    }
                }
            }
            self.usersInRange.value.append(user)
            //self.cleanMesh()
        })
    }
    private func removeLink(link: UDLink) {
        dispatch_async(dispatch_get_main_queue(), {
            for i in 0..<self.links.count {
                if link.nodeId == self.links[i].nodeId {
                    self.links.removeAtIndex(i)
                }
            }
            for i in 0..<self.usersInRange.value.count {
                if self.usersInRange.value[i].link.nodeId == link.nodeId {
                    self.removeUser(self.usersInRange.value[i])
                }
            }
        })
    }
    private func addLink(link: UDLink) {
       // if link already in list, return
        dispatch_async(dispatch_get_main_queue(), {
            for i in 0..<self.links.count {
                if link.nodeId == self.links[i].nodeId {
                    return
                }
            }
            self.links.append(link)
        })
    }
    public func broadcastType() {
        dispatch_async(dispatch_get_main_queue(), {
            let text = self.self.mode.rawValue + "_" + UIDevice.currentDevice().identifierForVendor!.UUIDString
            let data = text.dataUsingEncoding(NSUTF8StringEncoding) ?? NSData()
            if !self.links.isEmpty {
                    for link in self.links {
                    link.sendFrame(data)
                }
            }
            print("broadcasting type...")
        })
    }
    private func authenticateUser(user: User) {
        let data = ("allow_\(deviceId)").dataUsingEncoding(NSUTF8StringEncoding) ?? NSData()
        user.link.sendFrame(data)
    }
    private func notifyConnected(user: User) {
        let data = ("connected_\(deviceId)").dataUsingEncoding(NSUTF8StringEncoding) ?? NSData()
        user.link.sendFrame(data)
    }
    private func cleanMesh() {
        dispatch_async(dispatch_get_main_queue(), {
            for i in 0..<self.self.usersInRange.value.count {
                for j in 0..<loopNodes.count {
                    if self.usersInRange.value[i].link.nodeId == loopNodes[j] {
                        print("Attemting to clean mesh network of user with id \(self.usersInRange.value[i].id)")
                        self.usersInRange.value.removeAtIndex(i)
                        print("Count: \(self.usersInRange.value.count)")
                        break
                    }
                }
            }
        })
    }
    // MARK: Public Functions
    public func startScanningAsClient() {
        sendMessageToPeers("disconnect_\(deviceId)")
        connectedPeers.value = []
        usersInRange.value = []
        mode = .Client
        broadcastType()
        timer.invalidate()
        
    }
    public func startAdvertisingAsHost() {
        connectedPeers.value = []
        usersInRange.value = []
        mode = .Host
        broadcastType()
        timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(self.broadcastType), userInfo: nil, repeats: true)  // start advertising
    }
    public func goOffline() {
        usersInRange.value = []
        mode = .Offline
        timer.invalidate()
    }
    func sendMessageToPeers(text: String) {
        dispatch_async(dispatch_get_main_queue(), {
            let data = text.dataUsingEncoding(NSUTF8StringEncoding) ?? NSData()
            if !self.connectedPeers.value.isEmpty {
                for peer in self.connectedPeers.value {
                    if peer.connected {
                        peer.link.sendFrame(data)
                    }
                }
            }
        })
    }
    func clearInbox() {
            self.inbox.value = []
    }
    func askToConnectToPeer(user: User) {
        dispatch_async(dispatch_get_global_queue(qos_class_main(), 0), {
            let data = ("connection_request_\(self.deviceId)").dataUsingEncoding(NSUTF8StringEncoding) ?? NSData()
            user.link.sendFrame(data)
        })
    }
}
