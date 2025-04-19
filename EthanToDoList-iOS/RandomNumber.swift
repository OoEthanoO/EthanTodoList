//
//  RandomNumber.swift
//  EthanTodoList
//
//  Created by Ethan Xu on 2025-04-19.
//

import Foundation

struct RandomNumber: Identifiable, Codable {
    var id = UUID()
    var value: Int
    var isCrossedOut: Bool = false
}
