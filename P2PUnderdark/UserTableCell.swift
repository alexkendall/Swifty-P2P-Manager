import Foundation
import UIKit
import ReactiveCocoa

class UserTableCell: UITableViewCell, UITableViewDataSource, UITableViewDelegate {
    let discoverableUsers: MutableProperty<[User]> = MutableProperty([User]())
    let reuseId = "cellResuseid"
    @IBOutlet weak var userTable: UITableView!
    func configureRac(signal: Signal<[User], NoError>) {
        userTable.dataSource = self
        userTable.delegate = self
        discoverableUsers <~ signal
        discoverableUsers.signal
            .observeNext{_ in
                self.userTable.reloadData()
                print("User Table Changed")
        }
        userTable.registerNib(UINib(nibName: "UserCell", bundle: nil), forCellReuseIdentifier: reuseId)
    }
    // MARK: Data Source
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(reuseId, forIndexPath: indexPath) as? UserCell ?? UserCell()
        let user = discoverableUsers.value[indexPath.row]
        // lookup user in peers
        cell.idLabel.text = user.id
        cell.typeLabel.text = user.mode.rawValue
        if user.connected {
            cell.idLabel.textColor = UIView().tintColor
        } else {
            cell.idLabel.textColor = .blackColor()
        }
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