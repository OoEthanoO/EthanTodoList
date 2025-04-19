//
//  NumberBubbleView.swift
//  EthanTodoList
//
//  Created by Ethan Xu on 2025-04-19.
//

import SwiftUI

struct OptimizedNumberBubble: View {
    let number: Int
    let isCrossedOut: Bool
    let onTap: () -> Void
    
    var body: some View {
        Text("\(number)")
            .fontWeight(.medium)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.blue.opacity(0.1))
            )
            .strikethrough(isCrossedOut, color: .red)
            .foregroundColor(isCrossedOut ? .gray : .primary)
            .onTapGesture {
                onTap()
            }
    }
}
