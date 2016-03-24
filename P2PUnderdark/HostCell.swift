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
        chatController.networkManager = nil
        chatController.networkManager = NetworkManager(inMode: .Client)
    }
    func selectHost() {
        hostButton.backgroundColor = .redColor()
        clientButton.backgroundColor = .lightGrayColor()
        chatController.networkManager = nil
        chatController.networkManager = NetworkManager(inMode: .Host)
    }
}