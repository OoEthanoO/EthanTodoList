//
//  CheckboxToggleStyle.swift
//  EthanTodoList
//
//  Created by Ethan Xu on 2025-04-11.
//

import SwiftUI

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .resizable()
                .frame(width: 22, height: 22)
                .foregroundColor(configuration.isOn ? .blue : .gray)
                .onTapGesture {
                    configuration.isOn.toggle()
                }
            
            configuration.label
        }
    }
}

extension ToggleStyle where Self == CheckboxToggleStyle {
    static var checkboxstyle: CheckboxToggleStyle { CheckboxToggleStyle() }
}
