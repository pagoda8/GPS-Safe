//
//  MySafeViewController.swift
//  GPS Safe
//
//	Controls My Safe screen
//

import UIKit
import FirebaseDatabase

class MySafeViewController: UIViewController {
	
	//Reference to Data collection in the database
	private let dataCollection = Database.database().reference(withPath: "Data")
	
	//Shows a list of user's data
	@IBOutlet var tableView: UITableView!
	
	//Controls refreshing of table view
	private let refreshControl = UIRefreshControl()
	
	//Stores a copy of the user's data
	private var dataArray: [DataHolder] = []
	
    override func viewDidLoad() {
        super.viewDidLoad()

		//Set up table view
		tableView.delegate = self
		tableView.dataSource = self
		
		//Set up refresh control
		tableView.refreshControl = refreshControl
		tableView.backgroundView = refreshControl
		refreshControl.addTarget(self, action: #selector(refreshTable(_:)), for: .valueChanged)
		refreshControl.tintColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
		
		fetchData()
    }

	//When (+) button is tapped
	@IBAction func addTapped(_ sender: Any) {
		//Show options to select type of data to encrypt
		let actionSheet = UIAlertController(title: "Add data to your safe", message: "Select the type of data you want to encrypt", preferredStyle: .actionSheet)
		actionSheet.addAction(UIAlertAction(title: "Text", style: .default, handler: { _ in self.textSelected() }))
		actionSheet.addAction(UIAlertAction(title: "Image", style: .default, handler: { _ in self.imageSelected() }))
		actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
		self.present(actionSheet, animated: true)
	}
	
	//Go to text encryption screen
	private func textSelected() {
		showStoryboard(identifier: "encryptText")
	}
	
	//Go to image encryption screen
	private func imageSelected() {
		showStoryboard(identifier: "encryptImage")
	}
	
	//Gets user's data from database and adds to dataArray. Reloads table view.
	private func fetchData() {
		let usernameHash = Crypto.hash(input: AppDelegate.get().getCurrentUser())
		var fetchedDataArray: [DataHolder] = []
		
		dataCollection.observeSingleEvent(of: .value, with: {snapshot in
			if (snapshot.hasChild(usernameHash)) {
				let userSnap = snapshot.childSnapshot(forPath: usernameHash)
				//Loop over locations
				for case let locationSnap as DataSnapshot in userSnap.children {
					//Loop over data
					for case let dataSnap as DataSnapshot in locationSnap.children {
						let isOwner = dataSnap.childSnapshot(forPath: "isOwner").value as! Bool
						
						if (isOwner) {
							let name = dataSnap.childSnapshot(forPath: "name").value as! String
							let isText = dataSnap.childSnapshot(forPath: "isText").value as! Bool
							let hasPassword = dataSnap.childSnapshot(forPath: "hasPassword").value as! Bool
							let password = dataSnap.childSnapshot(forPath: "password").value as! String
							let key = dataSnap.childSnapshot(forPath: "key").value as! String
							
							let dataHolder = DataHolder(user: usernameHash, location: locationSnap.key, data: dataSnap.key, boolOwner: isOwner, boolText: isText, name: name, password: password, boolPassword: hasPassword, key: key)
							fetchedDataArray.append(dataHolder)
						}
					}
				}
			}
			self.dataArray = fetchedDataArray
			self.tableView.reloadData()
			self.refreshControl.endRefreshing()
		})
	}
	
	//Objective-C function to refresh the table view. Used for refreshControl.
	@objc private func refreshTable(_ sender: Any) {
		fetchData()
	}
	
	//Returns array with user's data
	public func getDataArray() -> [DataHolder] {
		return dataArray
	}
	
	//Shows alert with given title and message
	private func showAlert(title: String, message: String) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: .default))
		self.present(alert, animated: true)
	}
	
	//Shows storyboard with given identifier
	private func showStoryboard(identifier: String) {
		let vc = self.storyboard?.instantiateViewController(withIdentifier: identifier)
		vc?.modalPresentationStyle = .overFullScreen
		self.present(vc!, animated: true)
	}
}

extension UIViewController: UITableViewDelegate {
	//When row in table is tapped
	public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		print("Row tapped")
		//Call function to decrypt. Pass index
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
		
		//Create cell from reusable cell
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
