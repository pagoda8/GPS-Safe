//
//  EncryptTextViewController.swift
//  GPS Safe
//
//  Controls text encryption screen
//

import UIKit

class EncryptTextViewController: UIViewController {

	//Text fields for text, name and optional password
	@IBOutlet weak var text: UITextField!
	@IBOutlet weak var name: UITextField!
	@IBOutlet weak var password: UITextField!
	
	override func viewDidLoad() {
        super.viewDidLoad()
    }
    
	//When cancel button is tapped
	@IBAction func cancelTapped(_ sender: Any) {
		//Go to My Safe screen (first tab)
		let vc = self.storyboard?.instantiateViewController(withIdentifier: "tabController")
		vc?.modalPresentationStyle = .overFullScreen
		self.present(vc!, animated: true)
	}
	
	//When encrypt button is tapped
	@IBAction func encryptTapped(_ sender: Any) {
		
	}
	
}
