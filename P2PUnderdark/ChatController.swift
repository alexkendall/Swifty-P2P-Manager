import UIKit
import Underdark
import ReactiveCocoa
import enum Result.NoError
public typealias NoError = Result.NoError

class ChatViewController: UITableViewController {
    let chatFieldCellId = "chatFieldCellId"
    let messageTableId = "messageTableId"
    let hostCellId = "hostCellId"
    let voteCellId = "VoteCellId"
    let networkManager = NetworkManager()
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
        let data = text.value.dataUsingEncoding(NSUTF8StringEncoding) ?? NSData()
        networkManager.broadcastFrame(data)
    }
    func registerCells() {
        tableView.registerNib(UINib(nibName: "ChatFieldCell", bundle: nil), forCellReuseIdentifier: chatFieldCellId)
        tableView.registerNib(UINib(nibName: "MessageTableCell", bundle: nil), forCellReuseIdentifier: messageTableId)
        tableView.registerNib(UINib(nibName: "HostCell", bundle: nil), forCellReuseIdentifier: hostCellId)
         tableView.registerNib(UINib(nibName: "VoteCell", bundle: nil), forCellReuseIdentifier: voteCellId)
    }
    func clearInbox() {
        networkManager.clearInbox()
    }
    // MARK: DATA SOURCE
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 60.0
        } else if indexPath.row == 1 {
            return 120.0
        } else {
            return self.view.bounds.height - 160.0
        }
    }
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier(chatFieldCellId, forIndexPath: indexPath) as? ChatFieldCell ?? ChatFieldCell()
            cell.sendButton.addTarget(self, action: "sendFrames", forControlEvents: .TouchUpInside)
            cell.clearButton.addTarget(self, action: "clearInbox", forControlEvents: .TouchUpInside)
            cell.selectionStyle = .None
            self.text <~ cell.chatField.rac_textSignal()
                .toSignalProducer()
                .map{$0 as? String}
                .ignoreNil()
                .flatMapError { _ in SignalProducer<String, NoError>.empty}
            return cell
        } else if indexPath.row == 1 {
                let cell = tableView.dequeueReusableCellWithIdentifier(voteCellId, forIndexPath: indexPath) as? VoteCell ?? VoteCell()
                cell.configureCell()
                cell.selectionStyle = .None
                return cell
        } else {
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

