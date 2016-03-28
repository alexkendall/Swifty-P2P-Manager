import Foundation
import UIKit

class HostCell: UITableViewCell {

    @IBOutlet weak var hostButton: UIButton!
    @IBOutlet weak var clientButton: UIButton!
    
    func configureActions () {
        hostButton.addTarget(self, action: "selectHost", forControlEvents: .TouchDown)
        clientButton.addTarget(self, action: "selectClient", forControlEvents: .TouchDown)
    }
    func selectClient() {
        clientButton.setTitleColor(UIView().tintColor, forState: .Normal)
        hostButton.setTitleColor(.grayColor(), forState: .Normal)
        networkManager.startScanningAsClient()
    }
    func selectHost() {
        clientButton.setTitleColor(.grayColor(), forState: .Normal)
        hostButton.setTitleColor(UIView().tintColor, forState: .Normal)
        networkManager.startAdvertisingAsHost()
    }
}