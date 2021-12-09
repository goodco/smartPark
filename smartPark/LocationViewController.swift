//
//  MapViewController.swift
//  smartPark
//
//  Created by Connor Goodman on 12/2/21.
//

import UIKit
import MapKit
import CoreLocation

class LocationViewController: UIViewController, MKMapViewDelegate  {
    @IBOutlet weak var mapView: MKMapView!
    
    let speedVC = SpeedViewController()
    
    var locationManager: CLLocationManager!
    var isDriving = false
    var startedDriving = false
    var countdown = 20
    var parkedLocation = CLLocationCoordinate2D()
    var timer:Timer?
    var directionsArray: [MKDirections] = []
    var doNotSkip = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getLocation()
        locationManager.requestAlwaysAuthorization()
    }
    
    
    func enterDriveMode() {
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let speedViewController = storyBoard.instantiateViewController(withIdentifier: "SpeedViewController") as! SpeedViewController
        self.present(speedViewController, animated:true, completion:nil)
    }
    
    func mpsToMPH(speed: Double) -> Double {
        let output = round(speed * 2.237)
        return output
    }
    
    @objc func updateTimer() {
        if countdown > 0 {
            countdown -= 1
            print(countdown)
        }
        else if countdown <= 0 {
            timer?.invalidate()
            let parkedLocationPin = ParkedLocationPin(pinTitle: "Parked Car", coordinate: parkedLocation)
            self.mapView.addAnnotation(parkedLocationPin)
            locationManager.stopUpdatingLocation()
            countdown = 20
            doNotSkip = true
        }
    }
    
    func startTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: false)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            let span = MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
            let myLocation = CLLocationCoordinate2DMake(latitude, longitude)
            let region = MKCoordinateRegion(center: myLocation, span: span)
            let speed = mpsToMPH(speed: location.speed)
            
            mapView.setRegion(region, animated: true)
            
            self.mapView.showsUserLocation = true
            
            // Started driving
            if speed > 20.0 {
                startedDriving = true
                isDriving = true
                print("🚗 DRIVING")
                timer?.invalidate()
                countdown = 20
                enterDriveMode()
            }
            // start countdown once vehicle has slowed to below 1mph
            if (speed < 1 && startedDriving == true && doNotSkip == true) {
                print("STOPPED DRIVING 🛑")
                doNotSkip = false // TESTING
                isDriving = false
                parkedLocation = myLocation
                startTimer()
//                if isDriving == true {
//                    locationManager.startUpdatingLocation()
//                }
            }
            
            if speed < 15 && isDriving == false && startedDriving == true {
                startTimer()
            }
            
            if mapView.annotations.count > 1 {
                removeLastAnnotation()
            }
        
        }
    }
    
    
    func showAlertToPrivacySettings(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else{
            print("Something went wrong getting the UIApplication.openSettingsURLString")
            return
        }
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) in
            UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(settingsAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func getDirections() {
        guard let location = locationManager.location?.coordinate else {
            //TODO: Inform user we don't have their current location
            return
        }
        
        let request = createDirectionsRequest(from: location)
        let directions = MKDirections(request: request)
        resetMapView(withNew: directions)
        
        directions.calculate { [unowned self] (response, error) in
            //TODO: Handle error if needed
            guard let response = response else { return } //TODO: Show response not available in an alert
            
            for route in response.routes {
                self.mapView.addOverlay(route.polyline)
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
            }
        }
    }
    
    func createDirectionsRequest(from coordinate: CLLocationCoordinate2D) -> MKDirections.Request {
        let destinationCoordinate       = parkedLocation
        let startingLocation            = MKPlacemark(coordinate: locationManager.location!.coordinate)
        let destination                 = MKPlacemark(coordinate: destinationCoordinate)
        
        let request                     = MKDirections.Request()
        request.source                  = MKMapItem(placemark: startingLocation)
        request.destination             = MKMapItem(placemark: destination)
        request.transportType           = .walking
        request.requestsAlternateRoutes = true
        
        return request
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        renderer.strokeColor = .blue
        
        return renderer
    }
    
    func removeLastAnnotation() {
        self.mapView.removeAnnotation(mapView.annotations.last!)
    }
    
    func resetMapView(withNew directions: MKDirections) {
        mapView.removeOverlays(mapView.overlays)
        directionsArray.append(directions)
        let _ = directionsArray.map { $0.cancel() }
    }

    @IBAction func directionsButtonPressed(_ sender: UIButton) {
        getDirections()
    }
    
    @IBAction func clearButtonPressed(_ sender: UIButton) {
        isDriving = false
        startedDriving = false
        self.mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        locationManager.startUpdatingLocation()
    }
    
    
}

extension LocationViewController: CLLocationManagerDelegate {
    func getLocation(){
    // Creating a CLLocationManager will automatically check authorization
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        self.mapView.showsUserLocation = true
        
        mapView.delegate = self
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("Checking authentication status")
        handleAuthenticationStatus(status: status)
    }
    
    func handleAuthenticationStatus(status: CLAuthorizationStatus){
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            locationManager.requestAlwaysAuthorization()
        case .restricted:
            self.oneButtonAlert(title: "Location Services Denied", message: "It may be that parental controls are restricting location use in this app")
        case .denied:
            showAlertToPrivacySettings(title: "User has not authorized location services", message: "Select 'Settings' below and enable location services for this app")
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.requestLocation()
            locationManager.allowsBackgroundLocationUpdates = true
        @unknown default:
            print("DEVELOPER ALERT: Unknown case of status in handleAuthentication\(status)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("ERROR: \(error.localizedDescription). Failed to get device location")
    }

}

