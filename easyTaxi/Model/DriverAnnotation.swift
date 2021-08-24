//
//  DriverAnnotation.swift
//  easyTaxi
//
//  Created by 黃梓峻 on 2021/8/19.
//

import MapKit

class DriverAnnotation: NSObject,MKAnnotation {
   dynamic var coordinate: CLLocationCoordinate2D
    var uid:String
    
    init(uid: String, coordinate:CLLocationCoordinate2D) {
        self.uid = uid
        self.coordinate = coordinate
    }
    
    func updateAnnotationPosition(withCoordinate coordinate:CLLocationCoordinate2D) {
        UIView.animate(withDuration: 0.2) {
            self.coordinate = coordinate
        }
        
    }
}
