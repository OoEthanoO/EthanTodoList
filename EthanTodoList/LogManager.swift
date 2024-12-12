//
//  LogManager.swift
//  EthanTodoList
//
//  Created by Ethan Xu on 2024-12-12.
//

import Foundation

class LogManager: ObservableObject {
    static let shared = LogManager()

    @Published var logs: String = ""

    private init() {}

    func addLog(_ log: String) {
        DispatchQueue.main.async {
            self.logs += "\(log)\n"
        }
    }
}
