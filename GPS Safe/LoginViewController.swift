//
//  LoginViewController.swift
//  GPS Safe
//
//  Controls Login screen
//

import UIKit
import FirebaseDatabase

class LoginViewController: UIViewController {
	
	//References to collections in database
	private let usersCollection = Database.database().reference(withPath: "Users")
	private let publicKeysCollection = Database.database().reference(withPath: "PublicKeys")
	
	//Text fields to input username and password
	@IBOutlet weak var username: UITextField!
	@IBOutlet weak var password: UITextField!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		//Tap anywhere to hide keyboard
		let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
		view.addGestureRecognizer(tap)
	}
	
	//When sign up button is tapped
	@IBAction func signupTapped(_ sender: Any) {
		if (validFields()) {
			signup()
		}
	}
	
	//When log in button is tapped
	@IBAction func loginTapped(_ sender: Any) {
		if (validFields()) {
			login()
		}
	}
	
	//Returns true if fields are not empty, otherwise false and shows alert.
	private func validFields() -> Bool {
		if (username.text?.isEmpty == true) {
			showAlert(title: "Username missing", message: "Please input a username")
			return false
		}
		
		if (password.text?.isEmpty == true) {
			showAlert(title: "Password missing", message: "Please input a password")
			return false
		}
		
		return true
	}
	
	//Creates account for user
	private func signup() {
		let usernameHashString = Crypto.hash(input: username.text!)
		let passwordHashString = Crypto.hash(input: password.text!)
		
		usersCollection.observeSingleEvent(of: .value, with: { snapshot in
			//User doesn't exist
			if (!snapshot.hasChild(usernameHashString)) {
				do {
					let keys = try Crypto.generateRSAKeys(username: self.username.text!)
					let publicKeyString = try Crypto.getStringFromRSAKey(key: keys["public"]!)
					
					//Push to database
					self.publicKeysCollection.child(usernameHashString).child("key").setValue(publicKeyString)
					self.usersCollection.child(usernameHashString).child("password").setValue(passwordHashString)
					self.showAlert(title: "Success", message: "Account was created")
				} //Error while generating or reading keys
				catch {
					self.showAlert(title: "Error", message: "Could not create account")
				}
			} //User exists
			else {
				self.showAlert(title: "Username taken", message: "Choose a different username")
			}
		})
	}
	
	//Logs in the user
	private func login() {
		let usernameHashString = Crypto.hash(input: username.text!)
		let passwordHashString = Crypto.hash(input: password.text!)
		
		usersCollection.observeSingleEvent(of: .value, with: { snapshot in
			//User exists
			if (snapshot.hasChild(usernameHashString)) {
				let passwordSnap = snapshot.childSnapshot(forPath: usernameHashString).childSnapshot(forPath: "password")
				//Password correct
				if (passwordSnap.value as! String == passwordHashString) {
					//Set current user of app
					AppDelegate.get().setCurrentUser(self.username.text!)
					//Go to My Safe screen (first tab)
					self.showStoryboard(identifier: "tabController")
				} //Password incorrect
				else {
					self.showAlert(title: "Invalid password", message: "Try again")
				}
			} //User doesn't exist
			else {
				self.showAlert(title: "Invalid username", message: "Try again")
			}
		})
	}
	
	//Shows alert with given title and message
	private func showAlert(title: String, message: String) {
		vibrate(style: .light)
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
	
	//Vibrates phone with given style
	private func vibrate(style: UIImpactFeedbackGenerator.FeedbackStyle) {
		let generator = UIImpactFeedbackGenerator(style: style)
		generator.impactOccurred()
	}
}
