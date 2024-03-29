//
//  DataHolder.swift
//  GPS Safe
//
//	Defines a data type to store user's data
//

import UIKit
import FirebaseDatabase

public class DataHolder {
	private var user: String //Hashed username
	private var location: String //Latitude and longitude
	private var data: String //Data encrypted with symmetric key
	private var boolOwner: Bool //Specifies if user is the owner of data
	private var boolText: Bool //True if data is text, false if it's an image
	private var name: String //Name of data set by the user
	private var password: String //Hash of optional password (if set, otherwise empty)
	private var boolPassword: Bool //Specifies if optional password was set
	private var key: String //Symmetric key for data, encrypted with user's public key
	
	init(user: String, location: String, data: String, boolOwner: Bool, boolText: Bool, name: String, password: String, boolPassword: Bool, key: String) {
		self.user = user
		//Convert from Firebase compatible format
		self.location = location.replacingOccurrences(of: ",", with: ".")
		self.data = data.replacingOccurrences(of: "%", with: "/")
		self.boolOwner = boolOwner
		self.boolText = boolText
		self.name = name
		self.password = password
		self.boolPassword = boolPassword
		self.key = key
	}
	
	//Inserts all the data of the object into the database
	//Performs check to prevent overriding
	public func pushToDB() {
		let dataCollection = Database.database().reference(withPath: "Data")
		//Convert to Firebase compatible format
		let convertedLocation = self.location.replacingOccurrences(of: ".", with: ",")
		let convertedData = self.data.replacingOccurrences(of: "/", with: "%")
		var alreadyExists = false
		
		//Used to make sure inserting data into database is done after performing check
		let group = DispatchGroup()
		
		//Check if [user, location, data] node already exists
		group.enter()
		dataCollection.observeSingleEvent(of: .value, with: { snapshot in
			if (snapshot.hasChild(self.user)) {
				group.enter()
				dataCollection.child(self.user).observeSingleEvent(of: .value, with: { snapshot in
					if (snapshot.hasChild(convertedLocation)) {
						group.enter()
						dataCollection.child(self.user).child(convertedLocation).observeSingleEvent(of: .value, with: { snapshot in
							if (snapshot.hasChild(convertedData)) {
								alreadyExists = true
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
			if (!alreadyExists) {
				let dataNode = dataCollection.child(self.user).child(convertedLocation).child(convertedData)
				dataNode.child("name").setValue(self.name)
				dataNode.child("isOwner").setValue(self.boolOwner)
				dataNode.child("isText").setValue(self.boolText)
				dataNode.child("hasPassword").setValue(self.boolPassword)
				dataNode.child("password").setValue(self.password)
				dataNode.child("key").setValue(self.key)
			}
		}
	}
	
	//Deletes all the data of the object from the database
	public func deleteFromDB() {
		let dataCollection = Database.database().reference(withPath: "Data")
		//Convert to Firebase compatible format
		let convertedLocation = location.replacingOccurrences(of: ".", with: ",")
		let convertedData = data.replacingOccurrences(of: "/", with: "%")
		
		dataCollection.child(user).child(convertedLocation).child(convertedData).removeValue()
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
	
	public func getKey() -> String {
		return key
	}
}
