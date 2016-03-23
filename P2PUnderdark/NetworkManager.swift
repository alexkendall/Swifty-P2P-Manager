import Foundation
import Underdark
import ReactiveCocoa

class Node: NSObject, UDTransportDelegate {
    var links: [UDLink] = []
    var peersCount = 0
    var framesCount = 0
    var appId: Int32 = 123456
    var nodeId: Int64 = 0
    var transport: UDTransport? = nil
    let queue = dispatch_get_main_queue()
    let lastIncommingMessage: MutableProperty<String> = MutableProperty("")
    override init() {
        super.init()
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
            .observeNext{_ in
                print("Last incomming message changed to \(self.lastIncommingMessage.value)")
            }
    }
    func broadcastFrame(frameData: NSData) {
        print("attempting to broadcast frane")
        if !links.isEmpty {
            ++framesCount
            for link in links {
                link.sendFrame(frameData)
            }
        } else {
            print("link array is empty")
        }
    }
    // MARK: Delegate
    func transport(transport: UDTransport!, link: UDLink!, didReceiveFrame frameData: NSData!) {
        ++framesCount
        let str = String(data: frameData, encoding: NSUTF8StringEncoding) ?? ""
        print(str)
        lastIncommingMessage.value = str
        print("did recieve frame with value \(str)")
    }
    func transport(transport: UDTransport!, linkConnected link: UDLink!) {
        print(link)
        links.append(link)
        ++peersCount
        print("connected to user")
    }
    func transport(transport: UDTransport!, linkDisconnected link: UDLink!) {
        --peersCount
        print("disconnected from user")
    }
}