//
//  BackZStackButtonStyle.swift
//  Yeshivat Torat Shraga
//
//  Created by David Reese on 11/28/21.
//

import SwiftUI

struct BackZStackButtonStyle: ButtonStyle {
    var backgroundColor: Color
    var percentage: CGFloat
    
    init(backgroundColor: Color = .white, percentage: CGFloat = 10) {
        self.backgroundColor = backgroundColor
        self.percentage = percentage
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? backgroundColor.darker(by: percentage) : backgroundColor)
    }
}
