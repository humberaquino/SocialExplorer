//
//  Coordenable.swift
//  SocialExplorer
//
//  Created by Humberto Aquino on 5/11/15.
//  Copyright (c) 2015 Humberto Aquino. All rights reserved.
//

import Foundation
import CoreLocation

// Protocol used to draw References and Points 
protocol Coordenable {
    var coordinate:CLLocationCoordinate2D { get }
}