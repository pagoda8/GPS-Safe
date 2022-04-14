//
//  MySafeViewController.swift
//  GPS Safe
//
//  Created by Wojtek on 25/03/2022.
//

import UIKit
import FirebaseDatabase
import CryptoKit

class MySafeViewController: UIViewController {
	
	private let usersCollection = Database.database().reference(withPath: "Users")
	private let dataCollection = Database.database().reference(withPath: "Data")
	private let publicKeysCollection = Database.database().reference(withPath: "Public Keys")
	
	@IBOutlet var tableView: UITableView!
	
	private var dataArray: [DataHolder] = []
	
    override func viewDidLoad() {
        super.viewDidLoad()

		tableView.delegate = self
		tableView.dataSource = self
		
		fetchData()

        // Do any additional setup after loading the view.
    }

	@IBAction func addTapped(_ sender: Any) {
		
	}
	
	private func fetchData() {
		let usernameHash = hash(input: AppDelegate.get().currentUser)
		var fetchedDataArray: [DataHolder] = []
		
		dataCollection.observeSingleEvent(of: .value, with: {snapshot in
			if (snapshot.hasChild(usernameHash)) {
				let userSnap = snapshot.childSnapshot(forPath: usernameHash)
				//Loop over locations
				for case let location as DataSnapshot in userSnap.children {
					//Loop over data
					for case let data as DataSnapshot in location.children {
						let name = data.childSnapshot(forPath: "name").value as! String
						let isOwner = data.childSnapshot(forPath: "isOwner").value as! Bool
						let isText = data.childSnapshot(forPath: "isText").value as! Bool
						let hasPassword = data.childSnapshot(forPath: "hasPassword").value as! Bool
						let password = data.childSnapshot(forPath: "password").value as! String
						
						if (isOwner) {
							let dataHolder = DataHolder(user: usernameHash, location: location.key, data: data.key, boolOwner: isOwner, boolText: isText, name: name, password: password, boolPassword: hasPassword)
							fetchedDataArray.append(dataHolder)
						}
					}
				}
			}
			self.dataArray = fetchedDataArray
			self.tableView.reloadData()
		})
	}
	
	public func getDataArray() -> [DataHolder] {
		return dataArray
	}
	
	private func hash(input: String) -> String {
		let data = Data(input.utf8)
		let hash = SHA256.hash(data: data)
		let string = hash.compactMap { String(format: "%02x", $0) }.joined()
		return string;
	}
	
	private func showAlert(title: String, message: String) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
		alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
		self.present(alert, animated: true, completion: nil)
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
		if let vc = self as? MySafeViewController {
			return vc.getDataArray().count
		} else {
			return 0
		}
	}
	
	//Creates and returns a cell
	public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		var localDataArray: [DataHolder] = []
		if let vc = self as? MySafeViewController {
			localDataArray = vc.getDataArray()
		}
		
		let cell = tableView.dequeueReusableCell(withIdentifier: "tableCell", for: indexPath)
		cell.textLabel?.text = localDataArray[indexPath.row].getName()
		cell.textLabel?.textColor = UIColor.white
		
		//Set selection highlight colour
		let bgColourView = UIView()
		bgColourView.backgroundColor = UIColor.darkGray
		cell.selectedBackgroundView = bgColourView
		
		return cell
	}
}
