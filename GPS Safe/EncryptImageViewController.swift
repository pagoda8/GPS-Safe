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
	
	//When cancel button is tapped
	@IBAction func cancelTapped(_ sender: Any) {
		//Go to My Safe screen (first tab)
		let vc = self.storyboard?.instantiateViewController(withIdentifier: "tabController")
		vc?.modalPresentationStyle = .overFullScreen
		self.present(vc!, animated: true)
	}

}
