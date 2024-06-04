//
//  Item.swift
//  MyNotes
//
//  Created by Terence  Ndabereye  on 05/06/2024.
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
