//
//  MyAccountViewController.swift
//  GPS Safe
//
//  Created by Wojtek on 12/04/2022.
//

import UIKit

class MyAccountViewController: UIViewController {
	
	@IBOutlet weak var currentUser: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
		
		currentUser.text = "Username: " + AppDelegate.get().currentUser

        // Do any additional setup after loading the view.
    }
	
	@IBAction func logout(_ sender: Any) {
		AppDelegate.get().currentUser = ""
		
		let vc = self.storyboard?.instantiateViewController(withIdentifier: "login")
		vc?.modalPresentationStyle = .overFullScreen
		self.present(vc!, animated: true)
	}
	
}
