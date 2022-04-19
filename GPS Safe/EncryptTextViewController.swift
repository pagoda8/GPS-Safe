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

	//Text fields for text, name and optional password
	@IBOutlet weak var text: UITextField!
	@IBOutlet weak var name: UITextField!
	@IBOutlet weak var password: UITextField!
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		//Tap anywhere to hide keyboard
		let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
		view.addGestureRecognizer(tap)
    }
    
	//When cancel button is tapped
	@IBAction func cancelTapped(_ sender: Any) {
		//Go to My Safe screen (first tab)
		showStoryboard(identifier: "tabController")
	}
	
	//When encrypt button is tapped
	@IBAction func encryptTapped(_ sender: Any) {
		if (validFields()) {
			let usernameHash = Crypto.hash(input: AppDelegate.get().getCurrentUser())
			let name = name.text!
			
			var boolPassword = false
			var optionalPassword = ""
			if (password.text?.isEmpty == false) {
				boolPassword = true
				optionalPassword = Crypto.hash(input: password.text!)
			}
			
			publicKeysCollection.observeSingleEvent(of: .value, with: { snapshot in
				if (snapshot.hasChild(usernameHash)) {
					let publicKeyString = snapshot.childSnapshot(forPath: usernameHash).childSnapshot(forPath: "key").value as! String
					
					do {
						let symmetricKey = Crypto.generateAESKey()
						let encryptedText = try Crypto.encryptTextAES(plaintext: self.text.text!, key: symmetricKey)
						let symmetricKeyString = try Crypto.getStringFromAESKey(key: symmetricKey)
						let publicKey = try Crypto.getPublicKeyFromString(keyString: publicKeyString)
						let encryptedSymmetricKey = try Crypto.encryptRSA(string: symmetricKeyString, publicKey: publicKey)
						
						let dataHolder = DataHolder(user: usernameHash, location: "swansea", data: encryptedText, boolOwner: true, boolText: true, name: name, password: optionalPassword, boolPassword: boolPassword, key: encryptedSymmetricKey)
						dataHolder.pushToDB()
						self.showAlertAndStoryboard(title: "Success", message: "The data has been added to your safe", storyboardID: "tabController")
					} //Error during encryption process
					catch {
						self.showAlert(title: "Encryption failed", message: "An error has occured while trying to encrypt the data")
					}
				} //No public key for user
				else {
					self.showAlert(title: "Account error", message: "Cannot encrypt using this account")
				}
			})
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
	
	//Shows storyboard with given identifier
	private func showStoryboard(identifier: String) {
		let vc = self.storyboard?.instantiateViewController(withIdentifier: identifier)
		vc?.modalPresentationStyle = .overFullScreen
		self.present(vc!, animated: true)
	}
}
