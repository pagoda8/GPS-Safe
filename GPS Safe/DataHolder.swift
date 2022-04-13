//
//  DataHolder.swift
//  GPS Safe
//
//  Created by Wojtek on 13/04/2022.
//

import UIKit

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
