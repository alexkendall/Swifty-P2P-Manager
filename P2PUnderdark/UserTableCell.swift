import Foundation
import UIKit
import ReactiveCocoa

class UserTableCell: UITableViewCell, UITableViewDataSource, UITableViewDelegate {
    let users:MutableProperty<[User]> = MutableProperty([User]())
    let discoverableUsers: MutableProperty<[User]> = MutableProperty([User]())
    let reuseId = "cellResuseid"
    @IBOutlet weak var userTable: UITableView!
    func configureRac(signal: Signal<[User], NoError>) {
        userTable.dataSource = self
        userTable.delegate = self
        users <~ signal
        users.signal
            .observeNext{
                self.userTable.reloadData()
                var discoverable = [User]()
                for var i = 0; i < $0.count; ++i {
                    if $0[i].mode == .Host {
                        discoverable.append($0[i])
                    }
                }
                self.discoverableUsers.value = discoverable
        }
        discoverableUsers.signal
            .observeNext {_ in
                self.userTable.reloadData()
            }
        userTable.registerNib(UINib(nibName: "UserCell", bundle: nil), forCellReuseIdentifier: reuseId)
    }
    // MARK: Data Source
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(reuseId, forIndexPath: indexPath) as? UserCell ?? UserCell()
        cell.idLabel.text = discoverableUsers.value[indexPath.row].id
        cell.typeLabel.text = discoverableUsers.value[indexPath.row].mode.rawValue
        return cell
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return discoverableUsers.value.count
    }
    // MARK: Delegate
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 100.0
    }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        networkManager.askToConnectToPeer(discoverableUsers.value[indexPath.row])
    }

}