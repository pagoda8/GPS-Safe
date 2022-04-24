//
//  EncryptImageViewController.swift
//  GPS Safe
//
//  Controls image encryption screen
//

import UIKit

class EncryptImageViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	//When back button is tapped
	@IBAction func backTapped(_ sender: Any) {
		//Go to My Safe screen (first tab)
		showStoryboard(identifier: "tabController")
	}

	//Shows storyboard with given identifier
	private func showStoryboard(identifier: String) {
		let vc = self.storyboard?.instantiateViewController(withIdentifier: identifier)
		vc?.modalPresentationStyle = .overFullScreen
		self.present(vc!, animated: true)
	}
}
