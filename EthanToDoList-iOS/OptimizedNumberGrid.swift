//
//  OptimizedNumberGrid.swift
//  EthanTodoList
//
//  Created by Ethan Xu on 2025-04-19.
//

// New optimized grid component
import SwiftUI

struct OptimizedNumberGrid: View {
    @Binding var numbers: [RandomNumber]
    var onBatchUpdate: () -> Void
    
    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 60))],
            spacing: 10
        ) {
            ForEach(numbers.indices, id: \.self) { index in
                OptimizedNumberBubble(
                    number: numbers[index].value,
                    isCrossedOut: numbers[index].isCrossedOut
                ) {
                    numbers[index].isCrossedOut.toggle()
                    onBatchUpdate()
                }
                .id(numbers[index].id) // Stable identity
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}
