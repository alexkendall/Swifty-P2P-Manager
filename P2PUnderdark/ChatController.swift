import UIKit
import Underdark
import ReactiveCocoa
import enum Result.NoError
public typealias NoError = Result.NoError

var networkManager: NetworkManager = NetworkManager(inMode: .Client)

class ChatViewController: UITableViewController {
    let chatFieldCellId = "chatFieldCellId"
    let messageTableId = "messageTableId"
    let hostCellId = "hostCellId"
    var text: MutableProperty<String> = MutableProperty("")
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nil, bundle: nil)
        registerCells()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        registerCells()
    }
    override init(style: UITableViewStyle) {
        super.init(style: style)
        registerCells()
    }
    func sendFrames() {
        print("sennding frame")
        networkManager.sendMessageToPeers(text.value)
    }
    func registerCells() {
        tableView.registerNib(UINib(nibName: "ChatFieldCell", bundle: nil), forCellReuseIdentifier: chatFieldCellId)
        tableView.registerNib(UINib(nibName: "MessageTableCell", bundle: nil), forCellReuseIdentifier: messageTableId)
        tableView.registerNib(UINib(nibName: "HostCell", bundle: nil), forCellReuseIdentifier: hostCellId)
        networkManager = NetworkManager(inMode: .Client)
    }
    func clearInbox() {
        print("should clear")
        networkManager.clearInbox()
    }
    // MARK: DATA SOURCE
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 60.0
        } else {
            return self.view.bounds.height - 60.0 - tabBarController!.tabBar.bounds.height
        }
    }
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier(chatFieldCellId, forIndexPath: indexPath) as? ChatFieldCell ?? ChatFieldCell()
            cell.sendButton.addTarget(self, action: Selector(self.sendFrames()), forControlEvents: .TouchUpInside)
            cell.clearButton.addTarget(self, action: Selector(self.clearInbox()), forControlEvents: .TouchUpInside)
            cell.selectionStyle = .None
            self.text <~ cell.chatField.rac_textSignal()
                .toSignalProducer()
                .map{$0 as? String}
                .ignoreNil()
                .flatMapError { _ in SignalProducer<String, NoError>.empty}
            return cell
        }  else {
            let cell = tableView.dequeueReusableCellWithIdentifier(messageTableId, forIndexPath: indexPath) as? MessageTableCell ?? MessageTableCell()
            cell.configureRac(networkManager.inbox.signal)
            cell.selectionStyle = .None
            return cell
        }
    }
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}

