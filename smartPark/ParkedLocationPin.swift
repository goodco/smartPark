//
//  ParkedLocationPin.swift
//  smartPark
//
//  Created by Connor Goodman on 12/3/21.
//

import Foundation
import MapKit

class ParkedLocationPin: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var pinTitle: String?
    
    init(pinTitle: String?, coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        self.pinTitle = pinTitle
    }
    
   
}
