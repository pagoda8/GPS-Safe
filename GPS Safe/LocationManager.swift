//
//  LocationManager.swift
//  GPS Safe
//
//  Singleton class to manage all location operations
//

import UIKit
import CoreLocation

public class LocationManager: NSObject, CLLocationManagerDelegate {
	
	//Reference for other classes
	public static let shared = LocationManager()
	
	//The location manager object
	private var manager: CLLocationManager = CLLocationManager()
	
	//Latest location of user
	private var latestLocation: CLLocation = CLLocation()
	//Specifies if it is safe to get the latestLocation
	private var readyToGet: Bool = false
	
	//Called once, when the shared variable is accessed
	private override init() {
		super.init()
		self.manager.delegate = self
		self.manager.desiredAccuracy = kCLLocationAccuracyBest
		self.manager.requestWhenInUseAuthorization()
	}
	
	//Request permission to use location
	public func requestLocationUsage() {
		manager.requestWhenInUseAuthorization()
	}
	
	//Get the location of the user
	public func updateLocation() {
		readyToGet = false
		manager.requestLocation()
	}
	
	//Returns true if permission to use location was given, false otherwise.
	public func locationUsageAllowed() -> Bool {
		if (manager.authorizationStatus == .authorizedWhenInUse) {
			return true
		} else {
			return false
		}
	}
	
	//Returns true if app is allowed to use precise location, false otherwise.
	public func locationUsingBestAccuracy() -> Bool {
		if (manager.accuracyAuthorization == .fullAccuracy) {
			return true
		} else {
			return false
		}
	}
	
	//Returns true if device has location services enabled, false otherwise.
	public func locationServicesEnabled() -> Bool {
		return CLLocationManager.locationServicesEnabled()
	}
	
	//Returns the coordinates of the latest location as a string
	//Uses a completion handler to return the result
	//Returns "error" if location was not recieved
	public func getStringCoordinates(completion: @escaping (String) -> Void) {
		var i = 0
		var string = String()
		
		//Check if location was fetched every second for 10 seconds
		Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
			i += 1
			if (self.readyToGet) {
				self.readyToGet = false
				string = String(self.latestLocation.coordinate.latitude) + "|" + String(self.latestLocation.coordinate.longitude)
				completion(string)
				timer.invalidate()
			}
			else if (i == 10) {
				completion("error")
				timer.invalidate()
			}
		}
	}
	
	//Called when .requestLocation() successfully gets location
	public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		latestLocation = locations.last! //Array always has at least one item
		readyToGet = true
	}
	
	//Called when .requestLocation() could not get location
	public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		readyToGet = false
	}
	
	//Enum for throwing errors
	public enum LocationError: Error {
		case locationNotRecieved
	}
}
