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
        clientButton.backgroundColor = .redColor()
        hostButton.backgroundColor = .lightGrayColor()
        //networkManager.startScanningAsClient()
        networkManager = DiscoveryManager(inMode: .Client)
    }
    func selectHost() {
        hostButton.backgroundColor = .redColor()
        clientButton.backgroundColor = .lightGrayColor()
        //networkManager.startAdvertisingAsHost()
        networkManager = DiscoveryManager(inMode: .Host)
    }
}