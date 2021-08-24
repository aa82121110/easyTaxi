//
//  Service.swift
//  easyTaxi
//
//  Created by 黃梓峻 on 2021/8/14.
//

import Firebase
import CoreLocation
import GeoFire


let DB_REF = Database.database().reference()
let REF_USERS = DB_REF.child("users")
let REF_DRIVER_LOCATIONS = DB_REF.child("driver-locations")
struct Service {
    
    static let shared = Service()
    let currentUid = Auth.auth().currentUser?.uid
    
    func fetchUserData(uid: String,completion: @escaping(User) -> Void) {
        REF_USERS.child(uid).observeSingleEvent(of: .value) { snapshot in
            print("DEBUG: \(snapshot.value)")
            guard let dictionary = snapshot.value as? [String:Any] else {return}
            let uid = snapshot.key
            let user = User(uid: uid, dictionary: dictionary)
            completion(user)
        }
    }
    //
    func fetchDrivers(location:CLLocation,completion: @escaping(User) -> Void) {
        let geofire = GeoFire(firebaseRef: REF_DRIVER_LOCATIONS)
        //監聽如數值有變動的話
        REF_DRIVER_LOCATIONS.observe(.value) { snapshot in
            //地圖半徑50以內
            geofire.query(at: location, withRadius: 50).observe(.keyEntered, with: { uid,location in
                //取得駕駛人資料
                self.fetchUserData(uid: uid) { user in
                    var driver = user
                    driver.location = location
                    completion(driver)
                }
            })
        }
    }
}
