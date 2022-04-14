//
//  MyAccountViewController.swift
//  GPS Safe
//
//	Controls My Account screen
//

import UIKit

class MyAccountViewController: UIViewController {
	
	//Label showing username
	@IBOutlet weak var currentUser: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
		
		currentUser.text = "Username: " + AppDelegate.get().getCurrentUser()
    }
	
	//When log out button is tapped
	@IBAction func logout(_ sender: Any) {
		AppDelegate.get().setCurrentUser("")
		
		//Go to login screen
		let vc = self.storyboard?.instantiateViewController(withIdentifier: "login")
		vc?.modalPresentationStyle = .overFullScreen
		self.present(vc!, animated: true)
	}
	
}
