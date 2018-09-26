//
//  ViewController.swift
//  getCurrentLocation
//
//  Created by KENNETH BLUE on 6/8/18.
//  Copyright © 2018 Kenneth Blue. All rights reserved.
//
//import Foundation
import UIKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {
	
	@IBOutlet weak var instructionsLabel: UILabel!
	@IBOutlet weak var addressLabel: UILabel!
	@IBOutlet weak var latitudeLabel: UILabel!
	@IBOutlet weak var longitudeLabel: UILabel!
	@IBOutlet weak var firstNameTextField: UITextField!
	@IBOutlet weak var lastNameTextField: UITextField!
	@IBOutlet weak var addressTextField: UITextField!
	@IBOutlet weak var cityTextField: UITextField!
	@IBOutlet weak var submitButton: UIButton!
	@IBOutlet weak var spinnerContainerView: UIView!
	
	@IBAction func submitButtonTouchDown() {
		print("button clicked")
		
		print(you)
		let endFirstName = you.firstName.last
		let endLastName = you.lastName.last
		if endFirstName == " " {
			you.firstName = String(you.firstName.dropLast())
		}
		if endLastName == " " {
			you.lastName = String(you.lastName.dropLast())
		}
		let lname = you.firstName + "%20" + you.lastName
		print("the lname is \(lname)")
		urlString = String("https://rogerthatapps.com/ioslocator/?lname=\(lname)&llatitude=\(you.latitude)&llongitude=\(you.longitude)")
		print(urlString)
		
	}
	
	@IBAction func submitButtonTouchUp() {
		let url = URL(string: urlString)
		print("The url is \(url!)")
		UIApplication.shared.open(url!, options: [:], completionHandler: nil)
		print("go")
	}
	
	@IBAction func nextTextField() {
		you.firstName = firstNameTextField.text!
		
		firstNameTextField.resignFirstResponder()
		lastNameTextField.becomeFirstResponder()
	}
	
	@IBAction func done() {
		you.lastName = lastNameTextField.text!
		if submitButton.titleLabel?.text == "Finding Location" {
			instructionsLabel.text = "Now move you device left to right."
		} else if submitButton.titleLabel?.text == "Send Location"{
			instructionsLabel.text = "Confirm Address. Make any changes."
		}
		lastNameTextField.resignFirstResponder()
		
		
	}
	
	
	let locationManager = CLLocationManager()
	var location: CLLocation?
	var streetAddress = ""
	var cityAddress = ""
	var updatingLocation = false
	var lastLocationError: Error?
	
	let geocoder = CLGeocoder()
	var placemark: CLPlacemark?
	var performingReverseGeocoding = false
	var lastGeocodingError: Error?
	var urlString = "https://rogerthatapps.com/ioslocator/?lname=Missed%20Your%20Name&llatitude=anywhere&llongitude=anywhere"
	
	struct PersonLocation: Codable {
		var firstName: String
		var lastName: String
		var latitude: Double
		var longitude: Double
		var streetAddress: String?
		var cityStateZip: String?
		
		init(firstName: String, lastName: String, latitude: Double, longitude: Double) {
			self.firstName = firstName
			self.lastName = lastName
			self.latitude = latitude
			self.longitude = longitude
		}
	}
	var you = PersonLocation(firstName: "first", lastName: "last", latitude: 0.00, longitude: 0.00)
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		getLocation()
		
		firstNameTextField.becomeFirstResponder()
		
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	func getLocation() {
		let authStatus = CLLocationManager.authorizationStatus()
		
		if authStatus == .notDetermined {
			locationManager.requestWhenInUseAuthorization()
			return
		}
		print("authStatus is \(authStatus.rawValue)")
		if authStatus == .denied || authStatus == .restricted {
			showLocationServicesDeniedAlert()
			return
		}
		
		startLocationManager()
		updateLabels()

	}
	
	func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		print("Failed \(error)")
		
		if (error as NSError).code == CLError.locationUnknown.rawValue {
			return
		}
		
		lastLocationError = error
		
		stopLocationManager()
		updateLabels()
		
	}
	
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		let currentLocation = locations.last!
		print("my location is \(currentLocation)")
		
		if currentLocation.timestamp.timeIntervalSinceNow < -5 {
			return
		}
		
		if currentLocation.horizontalAccuracy < 0 {
			return
		}
		
		if location == nil || location!.horizontalAccuracy > currentLocation.horizontalAccuracy {
			lastLocationError = nil
			location = currentLocation
			
			
			if currentLocation.horizontalAccuracy <= locationManager.desiredAccuracy {
				print("good location reading!")
				you.latitude = currentLocation.coordinate.latitude
				you.longitude = currentLocation.coordinate.longitude
				getAddress(location: currentLocation)
				
				stopLocationManager()
			}
			updateLabels()
		}
	}
	
	func showLocationServicesDeniedAlert() {
		let alert = UIAlertController(title: "Need Access", message: "Please allow location access. Without it the app will not preform. ", preferredStyle: .alert)
		
		let okAction = UIAlertAction(title: "ok", style: .default, handler: nil)
		
		alert.addAction(okAction)
		
		present(alert, animated: true)
	}
	
	func startLocationManager() {
		print("KJO")
		if CLLocationManager.locationServicesEnabled() {
			locationManager.delegate = self
			locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
			locationManager.startUpdatingLocation()
			
			updatingLocation = true
			gatherLocationIndicator()
		}
	}
	
	func stopLocationManager() {
		if updatingLocation {
			print("stopping")
			locationManager.stopUpdatingLocation()
			locationManager.delegate = nil
			updatingLocation = false
		}
	}
	
	func getAddress(location: CLLocation) {
		
		print("the location is \(location)")
		
		if !performingReverseGeocoding {
			print("geocode Starting")
			performingReverseGeocoding = true
			geocoder.reverseGeocodeLocation(location, completionHandler: {
				placemarks, error in
					self.lastGeocodingError = error
				if error == nil, let p = placemarks, !p.isEmpty {
					self.placemark = p.last!
					print("you are here \(String(describing: self.placemark))")
				} else {
					self.placemark = nil
				}
				self.performingReverseGeocoding = false
				self.gatherLocationIndicator()
				self.updateLabels()
			})
		}
	}
	
	func gatherLocationIndicator() {
		print("gather")
		let spinnerTag = 1009
		
		if updatingLocation {
			submitButton.setTitle("Finding Location", for: .normal)
			
			if view.viewWithTag(spinnerTag) == nil {
				let spinner = UIActivityIndicatorView(activityIndicatorStyle: .gray)
				spinner.startAnimating()
				//spinner.center = spinnerContainerView.center
				spinner.center.x += spinnerContainerView.center.x - 10
				//spinner.center.y -= spinner.bounds.size.height/2 + 15
				spinner.tag = spinnerTag
				
				spinnerContainerView.addSubview(spinner)
				print(spinner.isAnimating)
			}
		} else {
			submitButton.setTitle("Send Location", for: .normal)
			if let spinner = view.viewWithTag(spinnerTag) {
				spinner.removeFromSuperview()
				print("spin over")
				instructionsLabel!.text = "Confirm Address. Make any changes."
				addLocationFound()
			}
		}
	}
	func addLocationFound() {
		instructionsLabel!.text = "Confirm Address. Make any changes."
	}
	func updateLabels() {
		if let location = location {
			latitudeLabel.text = "Latitude: " + String(format: "%8f",
										location.coordinate.latitude)
			longitudeLabel.text = "Longitude: " + String(format: "%8f",
										 location.coordinate.longitude)
			
		} else {
			latitudeLabel.text = "no location"
			longitudeLabel.text = "no location"
		}
		
		
		if let streetNumber = placemark?.subThoroughfare {
			streetAddress = streetNumber + " "
		}
		if let street = placemark?.thoroughfare {
			streetAddress += street
			addressTextField.text = streetAddress
		}
		if let city = placemark?.locality {
			cityAddress += city + ", "
		}
		if let state = placemark?.administrativeArea {
			cityAddress += state
		}
		if let zip = placemark?.postalCode {
			cityAddress += " " + zip
			cityTextField.text = cityAddress
		}
		addressLabel.text = streetAddress + "\n" + cityAddress
		you.streetAddress = streetAddress
		you.cityStateZip = cityAddress
		
	}

}



