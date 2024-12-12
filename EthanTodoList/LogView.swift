//
//  LogView.swift
//  EthanTodoList
//
//  Created by Ethan Xu on 2024-12-12.
//

import SwiftUI

struct LogView: View {
    @ObservedObject var logManager: LogManager

    var body: some View {
        VStack {
            Text("Logs")
                .font(.title)
                .padding()

            ScrollView {
                Text(logManager.logs)
                    .padding()
            }
        }
        .frame(width: 400, height: 300)
        .padding()
    }
}

#Preview {
    LogView(logManager: LogManager.shared)
}
