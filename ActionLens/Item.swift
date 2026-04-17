//
//  Item.swift
//  ActionLens
//
//  Created by Nikita Marshchonok on 17/04/2026.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
