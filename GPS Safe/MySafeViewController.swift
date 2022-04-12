//
//  MySafeViewController.swift
//  GPS Safe
//
//  Created by Wojtek on 25/03/2022.
//

import UIKit
import FirebaseDatabase

class MySafeViewController: UIViewController {
	
	private let users = Database.database().reference(withPath: "Users")
	private let data = Database.database().reference(withPath: "Data")
	private let publicKeys = Database.database().reference(withPath: "Public Keys")
	
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

	@IBAction func addTapped(_ sender: Any) {
		
	}
	
}
