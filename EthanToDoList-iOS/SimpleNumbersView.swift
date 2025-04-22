//
//  SimpleNumbersView.swift
//  EthanTodoList
//
//  Created by Ethan Xu on 2025-04-19.
//

import SwiftUI

struct SimpleNumbersView: View {
    let title: String
    let numbers: String
    let lastGenerated: Date
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last generated: \(timeFormatter.string(from: lastGenerated))")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.headline)
            
            Text(numbers)
                .font(.system(.title3, design: .rounded))
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.blue.opacity(0.1))
                )
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}
