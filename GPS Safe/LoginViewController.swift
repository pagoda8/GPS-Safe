//
//  LoginViewController.swift
//  GPS Safe
//
//  Created by Wojtek on 13/03/2022.
//

import UIKit
import FirebaseDatabase

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
			let alert = UIAlertController(title: "Username missing", message: "Please input a username", preferredStyle: UIAlertController.Style.alert)
			alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
			self.present(alert, animated: true, completion: nil)
			return false
		}
		
		if (password.text?.isEmpty == true) {
			let alert = UIAlertController(title: "Password missing", message: "Please input a password", preferredStyle: UIAlertController.Style.alert)
			alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
			self.present(alert, animated: true, completion: nil)
			return false
		}
		
		return true
	}
	
	private func signup() {
		users.observeSingleEvent(of: .value, with: { snapshot in
			//User doesn't exist
			if (!snapshot.hasChild(self.username.text!)) {
				self.users.child(self.username.text!).child("password").setValue(self.password.text!)
				
				let alert = UIAlertController(title: "Success", message: "Account was created", preferredStyle: UIAlertController.Style.alert)
				alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
				self.present(alert, animated: true, completion: nil)
			} //User exists
			else {
				let alert = UIAlertController(title: "Username taken", message: "Chose a different username", preferredStyle: UIAlertController.Style.alert)
				alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
				self.present(alert, animated: true, completion: nil)
			}
		})
	}
	
	private func login() {
		users.observeSingleEvent(of: .value, with: {snapshot in
			//User exists
			if (snapshot.hasChild(self.username.text!)) {
				let password = snapshot.childSnapshot(forPath: self.username.text!).childSnapshot(forPath: "password")
				//Password correct
				if (password.value as! String == self.password.text!) {
					AppDelegate.get().currentUser = self.username.text!
					
					let vc = self.storyboard?.instantiateViewController(withIdentifier: "mySafe")
					vc?.modalPresentationStyle = .overFullScreen
					self.present(vc!, animated: true)
				} //Password incorrect
				else {
					let alert = UIAlertController(title: "Invalid password", message: "Try again", preferredStyle: UIAlertController.Style.alert)
					alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
					self.present(alert, animated: true, completion: nil)
				}
			} //User doesn't exist
			else {
				let alert = UIAlertController(title: "Invalid username", message: "Try again", preferredStyle: UIAlertController.Style.alert)
				alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
				self.present(alert, animated: true, completion: nil)
			}
		})
	}
	
}
