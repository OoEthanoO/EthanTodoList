//
//  CombinedNumbersView.swift
//  EthanTodoList
//
//  Created by Ethan Xu on 2025-04-20.
//

import SwiftUI

struct CombinedNumbersView: View {
    let numbers28: String
    let numbers24: String 
    let numbers90: String
    let lastGenerated: Date
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Last generated: \(timeFormatter.string(from: lastGenerated))")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 12) {
                if !numbers28.isEmpty {
                    numberSection(title: "Numbers (1-28):", numbers: numbers28)
                }
                
                if !numbers24.isEmpty {
                    numberSection(title: "Numbers (1-24):", numbers: numbers24)
                }
                
                if !numbers90.isEmpty {
                    numberSection(title: "Numbers (1-90):", numbers: numbers90)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func numberSection(title: String, numbers: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
            
            Text(numbers)
                .font(.system(.body, design: .rounded))
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
        }
    }
}
