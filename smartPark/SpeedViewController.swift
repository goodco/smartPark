//
//  SpeedViewController.swift
//  smartPark
//
//  Created by Connor Goodman on 12/5/21.
//

import UIKit
import MapKit
import CoreLocation

class SpeedViewController: UIViewController {
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var driveModeMapView: MKMapView!
    @IBOutlet weak var homeButton: UIButton!
    
    var locationManager: CLLocationManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getLocation()
    }
    
    func mpsToMPH(speed: Double) -> Double {
        let output = round(speed * 2.237)
        return output
    }
    
    func dismissController() {
        dismiss(animated: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            let speed = mpsToMPH(speed: location.speed)
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            let span = MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
            let myLocation = CLLocationCoordinate2DMake(latitude, longitude)
            let region = MKCoordinateRegion(center: myLocation, span: span)
            
            driveModeMapView.setRegion(region, animated: true)
            
            self.driveModeMapView.showsUserLocation = true
            speedLabel.text = String(speed)
            if speedLabel.text == "-2.0" {      // Bug where speed is -2.0 when stationary
                speedLabel.text = "0.0"
            }
            
            if speed > 15 {
                homeButton.alpha = 0.0
            } else {
                homeButton.alpha = 1.0
            }
            
            if speedLabel.text == "0.0" {
                dismissController()
            }
            
        }
        
    }
    
    @IBAction func backButtonPressed(_ sender: UIButton) {
        _ = navigationController?.popToRootViewController(animated: true)
    }
    
}

extension SpeedViewController: CLLocationManagerDelegate {
    func getLocation(){
    // Creating a CLLocationManager will automatically check authorization
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        self.driveModeMapView.showsUserLocation = true
    }


}
