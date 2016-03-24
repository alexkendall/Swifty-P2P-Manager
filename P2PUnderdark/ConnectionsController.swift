import Foundation
import UIKit

class ConnectionsController: UITableViewController {
    let cellReuseId = "CellReuseId"
    let headerCellId = "ConnectionsCell"
    let clientHostCellId = "clientHostId"
    // MARK: Initialization
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nil, bundle: nil)
        registerCells()
    }
    override init(style: UITableViewStyle) {
        super.init(style: .Plain)
        registerCells()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        registerCells()
    }
    func registerCells() {
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: cellReuseId)
        tableView.registerNib(UINib(nibName: "HeaderCell", bundle: nil), forCellReuseIdentifier: headerCellId)
        tableView.registerNib(UINib(nibName: "HostCell", bundle: nil), forCellReuseIdentifier: clientHostCellId)
    }
    // MARK: Data Source
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 100.0
        }
        return 60.0
    }
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier(clientHostCellId, forIndexPath: indexPath) as? HostCell ?? HostCell()
            cell.configureActions()
            cell.selectionStyle = .None
            return cell
        } else if indexPath.row == 1 {
            let cell = tableView.dequeueReusableCellWithIdentifier(headerCellId, forIndexPath: indexPath) as? HeaderCell ?? HeaderCell()
            cell.selectionStyle = .None
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier(cellReuseId, forIndexPath: indexPath) as UITableViewCell ?? UITableViewCell()
            cell.selectionStyle = .None
            return cell
        }
    }
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}