//
//  LoginViewController.swift
//  GPS Safe
//
//  Created by Wojtek on 13/03/2022.
//

import UIKit
import FirebaseDatabase
import CryptoKit

class LoginViewController: UIViewController {
	
	private let users = Database.database().reference(withPath: "Users")
	
	@IBOutlet weak var username: UITextField!
	@IBOutlet weak var password: UITextField!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Do any additional setup after loading the view.
	}
	
	@IBAction func signupTapped(_ sender: Any) {
		if (validFields()) {
			signup()
		}
	}
	
	@IBAction func loginTapped(_ sender: Any) {
		if (validFields()) {
			login()
		}
	}
	
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
	
	private func signup() {
		let usernameHashString = hash(input: username.text!)
		let passwordHashString = hash(input: password.text!)
		
		users.observeSingleEvent(of: .value, with: { snapshot in
			//User doesn't exist
			if (!snapshot.hasChild(usernameHashString)) {
				self.users.child(usernameHashString).child("password").setValue(passwordHashString)
				self.showAlert(title: "Success", message: "Account was created")
			} //User exists
			else {
				self.showAlert(title: "Username taken", message: "Choose a different username")
			}
		})
	}
	
	private func login() {
		let usernameHashString = hash(input: username.text!)
		let passwordHashString = hash(input: password.text!)
		
		users.observeSingleEvent(of: .value, with: {snapshot in
			//User exists
			if (snapshot.hasChild(usernameHashString)) {
				let password = snapshot.childSnapshot(forPath: usernameHashString).childSnapshot(forPath: "password")
				//Password correct
				if (password.value as! String == passwordHashString) {
					AppDelegate.get().currentUser = self.username.text!
					
					let vc = self.storyboard?.instantiateViewController(withIdentifier: "mySafe")
					vc?.modalPresentationStyle = .overFullScreen
					self.present(vc!, animated: true)
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
