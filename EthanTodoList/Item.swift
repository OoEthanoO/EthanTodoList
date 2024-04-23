//
//  Item.swift
//  EthanTodoList
//
//  Created by Ethan Xu on 2024-04-22.
//

import Foundation
import SwiftData

@Model
final class Item {
    var order: Int
    var name: String
    var dueDate: Date
    var isForSchool: Bool
    
    init(order: Int, name: String, dueDate: Date, isForSchool: Bool) {
        self.order = order
        self.name = name
        self.dueDate = dueDate
        self.isForSchool = isForSchool
    }
}
