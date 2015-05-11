//
//  Coordenable.swift
//  SocialExplorer
//
//  Created by Humberto Aquino on 5/10/15.
//  Copyright (c) 2015 Humberto Aquino. All rights reserved.
//

import Foundation
import CoreLocation

protocol Coordenable: AnyObject {
    var coordinate: CLLocationCoordinate2D { get }
}