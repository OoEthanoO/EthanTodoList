//
//  Item.swift
//  EthanToDoList
//
//  Created by Ethan Xu on 2025-04-11.
//

import Foundation
import SwiftData

@Model
final class Item {
    var name: String
    var dueDate: Date
    var isForSchool: Bool
    var isCompleted: Bool
    var currentMinutes: Int? = 0
    var completedTime: Int? = 0
    var notes: String? = ""
    var isDoneForToday: Bool? = false
    var temporaryOrder: Int = 0  // Add this property for ordering
    
    init(name: String, dueDate: Date, isForSchool: Bool, isCompleted: Bool) {
        self.name = name
        self.dueDate = dueDate
        self.isForSchool = isForSchool
        self.isCompleted = isCompleted
        self.temporaryOrder = 0
        self.completedTime = 0
    }
}
