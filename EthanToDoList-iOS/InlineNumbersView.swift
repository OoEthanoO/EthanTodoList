//
//  InlineNumbersView.swift
//  EthanTodoList
//
//  Created by Ethan Xu on 2025-04-19.
//

import SwiftUI

struct InlineNumbersView: View {
    var numbers: [RandomNumber]
    var onToggle: (Int) -> Void
    
    var body: some View {
        Text(.init(numbers.enumerated().map { index, number in
            let numberText = "\(number.value)"
            if index < numbers.count - 1 {
                return number.isCrossedOut ? "~~\(numberText)~~, " : "\(numberText), "
            } else {
                return number.isCrossedOut ? "~~\(numberText)~~" : numberText
            }
        }.joined()))
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .overlay(
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    ForEach(numbers.indices, id: \.self) { index in
                        let widthEstimate = estimateWidth(for: numbers[index].value, isLast: index == numbers.count - 1)
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: widthEstimate)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                onToggle(index)
                            }
                    }
                }
            }
        )
    }
    
    private func estimateWidth(for number: Int, isLast: Bool) -> CGFloat {
        // Estimate width for each number + comma
        let digits = "\(number)".count
        let digitWidth: CGFloat = 10
        let commaWidth: CGFloat = isLast ? 0 : 15 // Account for comma and space
        return CGFloat(digits) * digitWidth + commaWidth
    }
}
