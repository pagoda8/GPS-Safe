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
	
	@IBOutlet var tableView: UITableView!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		tableView.delegate = self
		tableView.dataSource = self

        // Do any additional setup after loading the view.
    }

	@IBAction func addTapped(_ sender: Any) {
		
	}
	
}

extension UIViewController: UITableViewDelegate {
	//Executed when row is tapped
	public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		print("Row tapped")
		tableView.deselectRow(at: indexPath, animated: true)
	}
}

extension UIViewController: UITableViewDataSource {
	//Returns the number of rows for the table
	public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 3
	}
	
	//Creates and returns a cell
	public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "tableCell", for: indexPath)
		cell.textLabel?.text = "Hello"
		cell.textLabel?.textColor = UIColor.white
		
		//Set selection highlight colour
		let bgColourView = UIView()
		bgColourView.backgroundColor = UIColor.darkGray
		cell.selectedBackgroundView = bgColourView
		
		return cell
	}
}
