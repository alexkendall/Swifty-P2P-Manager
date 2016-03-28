import Foundation
import UIKit
import ReactiveCocoa

class MessageTableCell: UITableViewCell, UITableViewDataSource, UITableViewDelegate {
        @IBOutlet weak var table: UITableView!
    let messages = MutableProperty<[String]>([String]())
    let cellReuseId = "cellReuseId"
    // MARK: Initializers
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: nil)
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    func configureRac(signal: Signal<[String], NoError>) {
        messages <~ signal
        messages.signal
            .observeNext {_ in self.table.reloadData()
                print("reloading data")}
        table.registerClass(UITableViewCell.self, forCellReuseIdentifier: cellReuseId)
        table.delegate = self
        table.dataSource = self
        table.separatorStyle = .None
    }
    // MARK: Data Source
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.value.count
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellReuseId, forIndexPath: indexPath) as UITableViewCell ?? UITableViewCell()
        cell.textLabel?.text = messages.value[indexPath.row]
        cell.selectionStyle = .None
        if indexPath.row % 2 == 0 {
            cell.backgroundColor = UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0)
        } else {
            cell.backgroundColor = .whiteColor()
        }
        cell.textLabel?.font = UIFont.systemFontOfSize(13.0)
        return cell
    }
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 50.0
    }
}