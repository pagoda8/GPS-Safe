//
//  MySafeViewController.swift
//  GPS Safe
//
//	Controls My Safe screen
//

import UIKit
import FirebaseDatabase

class MySafeViewController: UIViewController {
	
	//References to collections in the database
	private let dataCollection = Database.database().reference(withPath: "Data")
	private let usersCollection = Database.database().reference(withPath: "Users")
	private let publicKeysCollection = Database.database().reference(withPath: "PublicKeys")
	
	//Reference to the LocationManager
	private let locationManager = LocationManager.shared
	
	//Stores a copy of the user's data
	private var dataArray: [DataHolder] = []
	
	//Controls refreshing of table view
	private let refreshControl = UIRefreshControl()
	
	//Used to show that data is being decrypted
	private let activityIndicator = UIActivityIndicatorView(style: .large)
	
	//Shows a list of user's data
	@IBOutlet var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

		//Set up table view
		tableView.delegate = self
		tableView.dataSource = self
		
		//Long press for table view
		let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPress(sender:)))
		tableView.addGestureRecognizer(longPress)
		
		//Set up refresh control
		tableView.refreshControl = refreshControl
		tableView.backgroundView = refreshControl
		refreshControl.addTarget(self, action: #selector(refreshTable(_:)), for: .valueChanged)
		refreshControl.tintColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
		
		//Set up activity indicator
		view.addSubview(activityIndicator)
		activityIndicator.translatesAutoresizingMaskIntoConstraints = false
		activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
		activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
		activityIndicator.backgroundColor = UIColor(white: 0.3, alpha: 0.7)
		activityIndicator.color = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
		activityIndicator.layer.cornerRadius = 5
		activityIndicator.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
		
		fetchData()
    }

	//When (+) button is tapped
	@IBAction func addTapped(_ sender: Any) {
		vibrate(style: .medium)
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
	
	//Decrypts the data stored in the dataArray at given index
	private func decrypt(dataIndex: Int) {
		let item = dataArray[dataIndex]
		
		//Used to make sure decryption happens only after entering the correct password (if set)
		var abort: Bool = false
		let group = DispatchGroup()
		
		//Check password
		if (item.hasPassword()) {
			group.enter()
			showPasswordAlert() { password in
				do {
					if (password == "") {
						throw MySafeError.invalidPassword
					}
					let passwordHash = Crypto.hash(input: password)
					if (passwordHash != item.getPassword()) {
						throw MySafeError.invalidPassword
					}
					group.leave()
				} //Invalid password
				catch {
					abort = true
					group.leave()
					self.showAlert(title: "Invalid password", message: "The password entered is incorrect")
				}
			}
		}
		
		//Executed after password check completes
		group.notify(queue: .main) {
			if (abort) {
				return
			}
			//Check location settings
			if (!self.locationManager.locationServicesEnabled() || !self.locationManager.locationUsageAllowed() || !self.locationManager.locationUsingBestAccuracy()) {
				self.showLocationAlert()
			}
			else {
				self.activityIndicator.startAnimating()
				//Get location
				self.locationManager.updateLocation()
				self.locationManager.getStringCoordinate() { location in
					do {
						if (location == "error") {
							throw LocationManager.LocationError.locationNotRecieved
						}
						//Check if user is in correct location
						if (!self.locationManager.isInsideRegion(currentLocation: location, originalLocation: item.getLocation())) {
							throw LocationManager.LocationError.locationNotInRegion
						}
						
						//Decrypt and show data
						do {
							let currentUser = AppDelegate.get().getCurrentUser()
							let privateKey = try Crypto.getPrivateKey(username: currentUser)
							let symmetricKeyString = try Crypto.decryptRSA(string: item.getKey(), privateKey: privateKey)
							let symmetricKey = try Crypto.getAESKeyFromString(keyString: symmetricKeyString)
							let decryptedData = try Crypto.decryptTextAES(ciphertext: item.getData(), key: symmetricKey)
							
							self.activityIndicator.stopAnimating()
							self.showDecryptedTextAlert(text: decryptedData)
						} //Error during decryption process
						catch {
							self.activityIndicator.stopAnimating()
							self.showAlert(title: "Decryption failed", message: "An error has occured while trying to decrypt the data")
						}
					} //Location error
					catch let error as LocationManager.LocationError {
						self.activityIndicator.stopAnimating()
						if (error == .locationNotRecieved) {
							self.showAlert(title: "Location error", message: "Could not get your current location")
						}
						else if (error == .locationNotInRegion) {
							self.showAlert(title: "Wrong location", message: "You are not in the correct location")
						}
					} //Other error
					catch {
						self.activityIndicator.stopAnimating()
						self.showAlert(title: "Error", message: "Something went wrong")
					}
				}
			}
		}
	}
	
	//Shares the data stored in the dataArray at given index
	private func share(dataIndex: Int) {
		let item = dataArray[dataIndex]
		let currentUser = AppDelegate.get().getCurrentUser()
		
		//Used to make sure sharing happens only after entering the correct password (if set)
		var abort: Bool = false
		let group1 = DispatchGroup()
		
		//Check password
		if (item.hasPassword()) {
			group1.enter()
			showPasswordAlert() { password in
				do {
					if (password == "") {
						throw MySafeError.invalidPassword
					}
					let passwordHash = Crypto.hash(input: password)
					if (passwordHash != item.getPassword()) {
						throw MySafeError.invalidPassword
					}
					group1.leave()
				} //Invalid password
				catch {
					abort = true
					group1.leave()
					self.showAlert(title: "Invalid password", message: "The password entered is incorrect")
				}
			}
		}
		
		//Executed after password check completes
		group1.notify(queue: .main) {
			if (abort) {
				return
			}
			//Get username
			self.showUsernameAlert() { enteredUsername in
				do {
					if (enteredUsername == "") {
						throw MySafeError.invalidUsername
					}
					else if (enteredUsername == currentUser) {
						throw MySafeError.logicError
					}
					//Cancel tapped
					else if (enteredUsername == "\t\n") {
						throw MySafeError.abort
					}
					
					let enteredUsernameHash = Crypto.hash(input: enteredUsername)
					//Used to make sure sharing happens only when entered username exists
					let group2 = DispatchGroup()
					
					//Check username
					group2.enter()
					self.usersCollection.observeSingleEvent(of: .value, with: { snapshot in
						do {
							if (!snapshot.hasChild(enteredUsernameHash)) {
								throw MySafeError.invalidUsername
							}
							group2.leave()
						} //User doesn't exist
						catch {
							abort = true
							group2.leave()
							self.showAlert(title: "Invalid username", message: "The username entered does not exist")
						}
					})
					
					//Executed after username check completes
					group2.notify(queue: .main) {
						if (abort) {
							return
						}
						//Sharing (i.e. decrypting and encrypting)
						do {
							//Decrypt symmetric key
							let privateKey = try Crypto.getPrivateKey(username: currentUser)
							let symmetricKeyString = try Crypto.decryptRSA(string: item.getKey(), privateKey: privateKey)
							
							//Encrypt symmetric key and share data
							self.publicKeysCollection.observeSingleEvent(of: .value, with: { snapshot in
								if (snapshot.hasChild(enteredUsernameHash)) {
									let publicKeyString = snapshot.childSnapshot(forPath: enteredUsernameHash).childSnapshot(forPath: "key").value as! String
									
									do {
										let publicKey = try Crypto.getPublicKeyFromString(keyString: publicKeyString)
										let encryptedSymmetricKey = try Crypto.encryptRSA(string: symmetricKeyString, publicKey: publicKey)
										
										let dataHolder = DataHolder(user: enteredUsernameHash, location: item.getLocation(), data: item.getData(), boolOwner: false, boolText: item.isText(), name: item.getName(), password: item.getPassword(), boolPassword: item.hasPassword(), key: encryptedSymmetricKey)
										dataHolder.pushToDB()
										self.showAlert(title: "Success", message: "Data was shared to user: " + enteredUsername)
									} //Error during encryption process
									catch {
										self.showAlert(title: "Sharing failed", message: "An error has occured while trying to share the data")
									}
								} //No public key for user
								else {
									self.showAlert(title: "Sharing error", message: "Cannot share data to this user")
								}
							})
						} //Error during decryption process
						catch {
							self.showAlert(title: "Sharing failed", message: "An error has occured while trying to share the data")
						}
					}
				} //Username error
				catch let error as MySafeError {
					if (error == .invalidUsername) {
						self.showAlert(title: "Invalid username", message: "The entered username cannot be empty")
					}
					else if (error == .logicError) {
						self.showAlert(title: "Invalid username", message: "You cannot share data to yourself")
					}
					else if (error == .abort) {
						return
					}
				} //Other error
				catch {
					self.showAlert(title: "Error", message: "Something went wrong")
				}
			}
		}
	}
	
	//Deletes the data stored in the dataArray at given index
	private func delete(dataIndex: Int) {
		let item = dataArray[dataIndex]
		
		//Used to make sure deletion happens only after entering the correct password (if set)
		var abort: Bool = false
		let group = DispatchGroup()
		
		//Check password
		if (item.hasPassword()) {
			group.enter()
			showPasswordAlert() { password in
				do {
					if (password == "") {
						throw MySafeError.invalidPassword
					}
					let passwordHash = Crypto.hash(input: password)
					if (passwordHash != item.getPassword()) {
						throw MySafeError.invalidPassword
					}
					group.leave()
				} //Invalid password
				catch {
					abort = true
					group.leave()
					self.showAlert(title: "Invalid password", message: "The password entered is incorrect")
				}
			}
		}
		
		//Executed after password check completes
		group.notify(queue: .main) {
			if (abort) {
				return
			}
			item.deleteFromDB()
			self.fetchData()
		}
	}
	
	//Objective-C function to refresh the table view. Used for refreshControl.
	@objc private func refreshTable(_ sender: Any) {
		fetchData()
	}
	
	//Objective-C function to handle long press on table view cell
	//Shows options to share or delete the data
	@objc private func longPress(sender: UILongPressGestureRecognizer) {
		if (sender.state == UIGestureRecognizer.State.began) {
			let touchPoint = sender.location(in: tableView)
			if let indexPath = tableView.indexPathForRow(at: touchPoint) {
				showShareOrDeleteActions(dataIndex: indexPath.row)
			}
		}
	}
	
	//Shows alert with given title and message
	private func showAlert(title: String, message: String) {
		vibrate(style: .light)
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: .default))
		self.present(alert, animated: true)
	}
	
	//Shows alert before decryption
	private func showDecryptAlert(dataIndex: Int) {
		vibrate(style: .light)
		let name = dataArray[dataIndex].getName()
		
		let alert = UIAlertController(title: "Attempting to decrypt", message: "Are you sure you want to access the data with name: " + name + " ?", preferredStyle: .alert)
		let decrypt = UIAlertAction(title: "Decrypt", style: .default) { _ in self.decrypt(dataIndex: dataIndex) }
		let cancel = UIAlertAction(title: "Cancel", style: .default)
		
		alert.addAction(cancel)
		alert.addAction(decrypt)
		self.present(alert, animated: true)
	}
	
	//Shows alert before deletion
	private func showDeleteAlert(dataIndex: Int) {
		vibrate(style: .light)
		let name = dataArray[dataIndex].getName()
		
		let alert = UIAlertController(title: "Attempting to delete", message: "Are you sure you want to delete the data with name: " + name + " ?", preferredStyle: .alert)
		let delete = UIAlertAction(title: "Delete", style: .default) { _ in self.delete(dataIndex: dataIndex) }
		let cancel = UIAlertAction(title: "Cancel", style: .default)
		
		alert.addAction(cancel)
		alert.addAction(delete)
		self.present(alert, animated: true)
	}
	
	//Shows alert prompting the user to input the password for the data
	//Uses a completion handler to return the entered password
	private func showPasswordAlert(completion: @escaping (String) -> Void) {
		vibrate(style: .light)
		let alert = UIAlertController(title: "Password required", message: "Please input the password for the data", preferredStyle: .alert)
		alert.addTextField() { textField in
			textField.isSecureTextEntry = true
			textField.placeholder = "password"
		}
		let ok = UIAlertAction(title: "OK", style: .default) { _ in
			let textField = alert.textFields![0]
			if (textField.text?.isEmpty == true) {
				completion("")
			} else {
				completion(textField.text!)
			}
		}
		
		alert.addAction(ok)
		self.present(alert, animated: true)
	}
	
	//Shows alert prompting the user to input the username of user to share to
	//Uses a completion handler to return the entered username
	private func showUsernameAlert(completion: @escaping (String) -> Void) {
		vibrate(style: .light)
		let alert = UIAlertController(title: "Enter username", message: "Enter the username of the user which you want to share the data with", preferredStyle: .alert)
		alert.addTextField() { textField in
			textField.placeholder = "username"
		}
		let ok = UIAlertAction(title: "OK", style: .default) { _ in
			let textField = alert.textFields![0]
			if (textField.text?.isEmpty == true) {
				completion("")
			} else {
				completion(textField.text!)
			}
		}
		let cancel = UIAlertAction(title: "Cancel", style: .default) { _ in
			completion("\t\n")
		}
		
		alert.addAction(cancel)
		alert.addAction(ok)
		self.present(alert, animated: true)
	}
	
	//Shows alert giving information about using location and option to go to Settings or cancel
	private func showLocationAlert() {
		vibrate(style: .light)
		let alert = UIAlertController(title: "Precise location required", message: "Without precise location you will not be able to use most features of this app", preferredStyle: .alert)
		
		let goToSettings = UIAlertAction(title: "Go to Settings", style: .default) { _ in
			guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
				self.showAlert(title: "Error", message: "Cannot open Settings app")
				return
			}
			if (UIApplication.shared.canOpenURL(settingsURL)) {
				UIApplication.shared.open(settingsURL)
			} else {
				self.showAlert(title: "Error", message: "Cannot open Settings app")
			}
		}
		
		let cancel = UIAlertAction(title: "Cancel", style: .default)
		
		alert.addAction(cancel)
		alert.addAction(goToSettings)
		self.present(alert, animated: true)
	}
	
	//Shows alert with decrypted text and option to copy it
	private func showDecryptedTextAlert(text: String) {
		vibrate(style: .light)
		let alert = UIAlertController(title: "Decrypted Text", message: text, preferredStyle: .alert)
		let copy = UIAlertAction(title: "Copy", style: .default) { _ in
			let pasteboard = UIPasteboard.general
			pasteboard.string = text
		}
		let close = UIAlertAction(title: "Close", style: .default)
		
		alert.addAction(close)
		alert.addAction(copy)
		self.present(alert, animated: true)
	}
	
	//Shows action sheet with options to share or delete the data
	private func showShareOrDeleteActions(dataIndex: Int) {
		vibrate(style: .medium)
		let name = dataArray[dataIndex].getName()
		
		let actionSheet = UIAlertController(title: "Data with name: " + name, message: "Select the type of action", preferredStyle: .actionSheet)
		actionSheet.addAction(UIAlertAction(title: "Share", style: .default, handler: { _ in self.share(dataIndex: dataIndex) }))
		actionSheet.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in self.showDeleteAlert(dataIndex: dataIndex) }))
		actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
		self.present(actionSheet, animated: true)
	}
	
	//Shows storyboard with given identifier
	private func showStoryboard(identifier: String) {
		let vc = self.storyboard?.instantiateViewController(withIdentifier: identifier)
		vc?.modalPresentationStyle = .overFullScreen
		self.present(vc!, animated: true)
	}
	
	//Vibrates phone with given style
	private func vibrate(style: UIImpactFeedbackGenerator.FeedbackStyle) {
		let generator = UIImpactFeedbackGenerator(style: style)
		generator.impactOccurred()
	}
	
	//Enum for throwing errors
	public enum MySafeError: Error {
		case invalidPassword
		case invalidUsername
		case logicError
		case abort
	}
}

//Table view setup

extension MySafeViewController: UITableViewDelegate {
	//When row in table is tapped
	public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		showDecryptAlert(dataIndex: indexPath.row)
		tableView.deselectRow(at: indexPath, animated: true)
	}
}

extension MySafeViewController: UITableViewDataSource {
	//Returns the number of rows for the table
	public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return dataArray.count
	}
	
	//Creates and returns a cell
	public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		//Create cell from reusable cell
		let cell = tableView.dequeueReusableCell(withIdentifier: "tableCell", for: indexPath)
		cell.textLabel?.text = dataArray[indexPath.row].getName()
		cell.textLabel?.textColor = UIColor.white
		
		//Set selection highlight colour
		let bgColourView = UIView()
		bgColourView.backgroundColor = UIColor.darkGray
		cell.selectedBackgroundView = bgColourView
		
		return cell
	}
}
