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
		
		//Tap anywhere to hide keyboard
		let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
		view.addGestureRecognizer(tap)
    }
    
	//When cancel button is tapped
	@IBAction func cancelTapped(_ sender: Any) {
		//Go to My Safe screen (first tab)
		showStoryboard(identifier: "tabController")
	}
	
	//When encrypt button is tapped
	@IBAction func encryptTapped(_ sender: Any) {
		
	}
	
	//Shows storyboard with given identifier
	private func showStoryboard(identifier: String) {
		let vc = self.storyboard?.instantiateViewController(withIdentifier: identifier)
		vc?.modalPresentationStyle = .overFullScreen
		self.present(vc!, animated: true)
	}
}
