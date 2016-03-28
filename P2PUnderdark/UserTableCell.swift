import Foundation
import UIKit
import ReactiveCocoa

class UserTableCell: UITableViewCell, UITableViewDataSource, UITableViewDelegate {
    var hosts: MutableProperty<[User]> = MutableProperty([User]())
    // user can only see hosts, clients are invisible
    let reuseId = "cellResuseid"
    @IBOutlet weak var userTable: UITableView!
    func configureRac(hostSignal: Signal<[User], NoError>) {
        userTable.dataSource = self
        userTable.delegate = self
        hosts.signal
            .observeNext{_ in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.userTable.reloadData()
                })
                print("reloading data...")
        }
        userTable.registerNib(UINib(nibName: "UserCell", bundle: nil), forCellReuseIdentifier: reuseId)
        userTable.separatorStyle = .None
    }
    // MARK: Data Source
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(reuseId, forIndexPath: indexPath) as? UserCell ?? UserCell()
        let user = hosts.value[indexPath.row]
        // lookup user in peers
        cell.idLabel.text = user.id
        cell.typeLabel.text = user.mode.rawValue
        cell.wifiIcon.setGMDIcon(GMDType.GMDWifi, size: 40.0, forState: .Normal)
        if user.connected {
            cell.wifiIcon.setTitleColor(UIView().tintColor, forState: .Normal)
        } else {
            cell.wifiIcon.setTitleColor(.grayColor(), forState: .Normal)
        }
        return cell
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("hosts count \(hosts.value.count)")
        return hosts.value.count
    }
    // MARK: Delegate
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 100.0
    }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        networkManager.askToConnectToPeer(hosts.value[indexPath.row])
    }
}
