//
//  PhysicsCategory.swift
//  Flappy President
//
//  Created by Derek Dawson on 8/1/16.
//  Copyright © 2016 Derek Dawson. All rights reserved.
//

import Foundation

struct PhysicsCategory {
    static let Bird: UInt32 = 0x1 << 1
    static let Ground: UInt32 = 0x1 << 2
    static let Wall: UInt32 = 0x1 << 3
    static let Score: UInt32 = 0x1 << 4
    static let SocialButton: UInt32 = 0x1 << 5
}