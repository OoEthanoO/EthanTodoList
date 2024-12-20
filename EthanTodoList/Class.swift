//
//  Item.swift
//  EthanTodoList
//
//  Created by Ethan Xu on 2024-04-22.
//

import Foundation
import SwiftData

@Model
final class Class {
    var name: String? = ""
    var startTime: Date
    var endTime: Date
    
    init(name: String, startTime: Date, endTime: Date) {
        self.name = name;
        self.startTime = startTime
        self.endTime = endTime
    }
}
