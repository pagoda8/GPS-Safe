//
//  DataHolder.swift
//  GPS Safe
//
//	Defines a data type to store user's data
//

import UIKit
import FirebaseDatabase

public class DataHolder {
	private var user: String
	private var location: String
	private var data: String
	private var boolOwner: Bool
	private var boolText: Bool
	private var name: String
	private var password: String
	private var boolPassword: Bool
	
	init(user: String, location: String, data: String, boolOwner: Bool, boolText: Bool, name: String, password: String, boolPassword: Bool) {
		self.user = user
		self.location = location
		self.data = data
		self.boolOwner = boolOwner
		self.boolText = boolText
		self.name = name
		self.password = password
		self.boolPassword = boolPassword
	}
	
	//Inserts all the data of the object into the database
	//Performs check to prevent overriding
	public func pushToDB() {
		let dataCollection = Database.database().reference(withPath: "Data")
		var exists = false
		
		//Used to make sure inserting data into database is done after performing check
		let group = DispatchGroup()
		
		//Check if [user, location, data] node already exists
		group.enter()
		dataCollection.observeSingleEvent(of: .value, with: { snapshot in
			if (snapshot.hasChild(self.user)) {
				group.enter()
				dataCollection.child(self.user).observeSingleEvent(of: .value, with: { snapshot in
					if (snapshot.hasChild(self.location)) {
						group.enter()
						dataCollection.child(self.user).child(self.location).observeSingleEvent(of: .value, with: { snapshot in
							if (snapshot.hasChild(self.data)) {
								exists = true
							}
							group.leave()
						})
					}
					group.leave()
				})
			}
			group.leave()
		})
		
		//Executed when check is complete
		group.notify(queue: .main) {
			if (!exists) {
				let dataNode = dataCollection.child(self.user).child(self.location).child(self.data)
				dataNode.child("name").setValue(self.name)
				dataNode.child("isOwner").setValue(self.boolOwner)
				dataNode.child("isText").setValue(self.boolText)
				dataNode.child("hasPassword").setValue(self.boolPassword)
				dataNode.child("password").setValue(self.password)
			}
		}
	}
	
	public func getUser() -> String {
		return user
	}
	
	public func getLocation() -> String {
		return location
	}
	
	public func getData() -> String {
		return data
	}
	
	public func isOwner() -> Bool {
		return boolOwner
	}
	
	public func isText() -> Bool {
		return boolText
	}
	
	public func getName() -> String {
		return name
	}
	
	public func getPassword() -> String {
		return password
	}
	
	public func hasPassword() -> Bool {
		return boolPassword
	}
}
