//
//  LoginViewController.swift
//  GPS Safe
//
//  Created by Wojtek on 13/03/2022.
//

import UIKit
import FirebaseDatabase

class LoginViewController: UIViewController {
	
	private let db = Database.database().reference()
	
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
		//Check if username already exists, if so show alert
		//Create account in db
		//Show success alert and ask to log in
		
		db.child("Users").child(username.text!).child("password").setValue(password.text!)
	}
	
	private func login() {
		//Try to log in, if success go to MySafe //Later make global var for username
		//Else show alert
		let vc = self.storyboard?.instantiateViewController(withIdentifier: "mySafe")
		vc?.modalPresentationStyle = .overFullScreen
		self.present(vc!, animated: true)
	}
	
	
	/*
	 // MARK: - Navigation
	 
	 // In a storyboard-based application, you will often want to do a little preparation before navigation
	 override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
	 // Get the new view controller using segue.destination.
	 // Pass the selected object to the new view controller.
	 }
	 */
	
}
