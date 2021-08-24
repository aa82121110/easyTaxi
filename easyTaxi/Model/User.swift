//
//  User.swift
//  easyTaxi
//
//  Created by 黃梓峻 on 2021/8/17.
//

import CoreLocation

struct User {
    let fullname:String
    let email:String
    let accountType:Int
    var location:CLLocation?
    var uid:String
    
    init(uid:String,dictionary: [String : Any]) {
        self.uid = uid
        self.fullname = dictionary["fullname"] as? String ?? ""
        self.email = dictionary["email"] as? String ?? ""
        self.accountType = dictionary["accountType"] as? Int ?? 0
    }
}
