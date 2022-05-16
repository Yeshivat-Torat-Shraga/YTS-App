//
//  iOS14BorderedButtonStyle.swift
//  Yeshivat Torat Shraga
//
//  Created by David Reese on 5/16/22.
//

import Foundation
import SwiftUI

struct iOS14BorderedButtonStyle: ButtonStyle {
    var color: Color
    
    init(color: Color = Color(hex: 0x526B98)) {
        self.color = color
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
