//
//  EncryptTextViewController.swift
//  GPS Safe
//
//  Controls text encryption screen
//

import UIKit
import FirebaseDatabase

class EncryptTextViewController: UIViewController {
	
	//Reference to PublicKeys collection in database
	private let publicKeysCollection = Database.database().reference(withPath: "PublicKeys")
	
	//Reference to the LocationManager
	private let locationManager = LocationManager.shared
	
	//Used to show that data is being encrypted
	private let activityIndicator = UIActivityIndicatorView(style: .large)
	
	//Indicates if adding data to safe should be aborted
	private var abort: Bool = false

	//Text fields for text, name and optional password
	@IBOutlet weak var text: UITextField!
	@IBOutlet weak var name: UITextField!
	@IBOutlet weak var password: UITextField!
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		//Tap anywhere to hide keyboard
		let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
		view.addGestureRecognizer(tap)
		
		//Set up activity indicator
		view.addSubview(activityIndicator)
		activityIndicator.translatesAutoresizingMaskIntoConstraints = false
		activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
		activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
		activityIndicator.backgroundColor = UIColor(white: 0.3, alpha: 0.7)
		activityIndicator.color = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
		activityIndicator.layer.cornerRadius = 5
		activityIndicator.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
    }
    
	//When cancel button is tapped
	@IBAction func cancelTapped(_ sender: Any) {
		abort = true
		activityIndicator.stopAnimating()
		//Go to My Safe screen (first tab)
		showStoryboard(identifier: "tabController")
	}
	
	//When encrypt button is tapped
	@IBAction func encryptTapped(_ sender: Any) {
		abort = false
		if (validFields()) {
			let usernameHash = Crypto.hash(input: AppDelegate.get().getCurrentUser())
			let name = name.text!
			
			var boolPassword = false
			var optionalPassword = ""
			if (password.text?.isEmpty == false) {
				boolPassword = true
				optionalPassword = Crypto.hash(input: password.text!)
			}
			
			//Check location settings
			if (!locationManager.locationServicesEnabled() || !locationManager.locationUsageAllowed() || !locationManager.locationUsingBestAccuracy()) {
				showLocationAlert()
			}
			else {
				activityIndicator.startAnimating()
				//Get location
				locationManager.updateLocation()
				locationManager.getStringCoordinate() { location in
					do {
						if (location == "error") {
							throw LocationManager.LocationError.locationNotRecieved
						}
						
						//Encrypt and save data
						self.publicKeysCollection.observeSingleEvent(of: .value, with: { snapshot in
							if (snapshot.hasChild(usernameHash)) {
								let publicKeyString = snapshot.childSnapshot(forPath: usernameHash).childSnapshot(forPath: "key").value as! String
								
								do {
									let symmetricKey = Crypto.generateAESKey()
									let encryptedText = try Crypto.encryptTextAES(plaintext: self.text.text!, key: symmetricKey)
									let symmetricKeyString = try Crypto.getStringFromAESKey(key: symmetricKey)
									let publicKey = try Crypto.getPublicKeyFromString(keyString: publicKeyString)
									let encryptedSymmetricKey = try Crypto.encryptRSA(string: symmetricKeyString, publicKey: publicKey)
									
									let dataHolder = DataHolder(user: usernameHash, location: location, data: encryptedText, boolOwner: true, boolText: true, name: name, password: optionalPassword, boolPassword: boolPassword, key: encryptedSymmetricKey)
									//If cancel button was not tapped during encryption
									if (!self.abort) {
										dataHolder.pushToDB()
										self.activityIndicator.stopAnimating()
										self.showAlertAndStoryboard(title: "Success", message: "The data has been added to your safe", storyboardID: "tabController")
									}
								} //Error during encryption process
								catch {
									self.activityIndicator.stopAnimating()
									self.showAlert(title: "Encryption failed", message: "An error has occured while trying to encrypt the data")
								}
							} //No public key for user
							else {
								self.activityIndicator.stopAnimating()
								self.showAlert(title: "Account error", message: "Cannot encrypt using this account")
							}
						})
					} //Error during getting location
					catch {
						self.activityIndicator.stopAnimating()
						self.showAlert(title: "Location error", message: "Could not get your current location")
					}
				}
			}
		}
	}
	
	//Returns true if text and name fields are not empty, otherwise false and shows alert.
	private func validFields() -> Bool {
		if (text.text?.isEmpty == true) {
			showAlert(title: "Text field cannot be empty", message: "Please input text to encrypt")
			return false
		}
		
		if (name.text?.isEmpty == true) {
			showAlert(title: "Name field cannot be empty", message: "Please input a name for the data")
			return false
		}
		
		return true
	}
	
	//Shows alert with given title and message
	private func showAlert(title: String, message: String) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: .default))
		self.present(alert, animated: true)
	}
	
	//Shows alert with given title and message
	//Shows storyboard with given identifier after "OK" button is tapped
	private func showAlertAndStoryboard(title: String, message: String, storyboardID: String) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		let action = UIAlertAction(title: "OK", style: .default) { _ in self.showStoryboard(identifier: storyboardID) }
		alert.addAction(action)
		self.present(alert, animated: true)
	}
	
	//Shows alert giving information about using location and option to go to Settings or cancel
	private func showLocationAlert() {
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
	
	//Shows storyboard with given identifier
	private func showStoryboard(identifier: String) {
		let vc = self.storyboard?.instantiateViewController(withIdentifier: identifier)
		vc?.modalPresentationStyle = .overFullScreen
		self.present(vc!, animated: true)
	}
}
