import Foundation
import UIKit
import ReactiveCocoa

class UserTableCell: UITableViewCell, UITableViewDataSource, UITableViewDelegate {
    let users:MutableProperty<[User]> = MutableProperty([User]())
    let reuseId = "cellResuseid"
    @IBOutlet weak var userTable: UITableView!
    func configureRac(signal: Signal<[User], NoError>) {
        userTable.dataSource = self
        userTable.delegate = self
        users <~ signal
        users.signal
            .observeNext{ _ in
                self.userTable.reloadData()
                print("reloading data")
        }
        userTable.registerNib(UINib(nibName: "UserCell", bundle: nil), forCellReuseIdentifier: reuseId)
    }
    // MARK: Data Source
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(reuseId, forIndexPath: indexPath) as? UserCell ?? UserCell()
        cell.idLabel.text = users.value[indexPath.row].id
        cell.typeLabel.text = users.value[indexPath.row].mode.rawValue
        return cell
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("USER COUNT RETURNED: \(users.value.count)")
        return users.value.count
    }
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 100.0
    }

}