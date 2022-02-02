//
//  YTSProgressViewStyle.swift
//  Yeshivat Torat Shraga
//
//  Created by David Reese on 11/21/21.
//

import Foundation
import SwiftUI

struct YTSProgressViewStyle: ProgressViewStyle {
    private let defaultSize: CGFloat = 18
    private let lineWidth: CGFloat = 2
    private let defaultProgress = 0.2 // CHANGE
    
    // tracks the rotation angle for the indefinite progress bar
    @State private var fillRotationAngle = Angle.degrees(-90) // ADD
    
    public func makeBody(configuration: ProgressViewStyleConfiguration) -> some View {
        VStack {
            configuration.label
            progressCircleView(fractionCompleted: configuration.fractionCompleted ?? defaultProgress, isIndefinite: configuration.fractionCompleted == nil)
            configuration.currentValueLabel
        }
    }
    
    private func progressCircleView(fractionCompleted: Double,
                                    isIndefinite: Bool) -> some View {
        // this is the circular "track", which is a full circle at all times
        Circle()
            .strokeBorder(Color.gray.opacity(0.5), lineWidth: lineWidth, antialiased: true)
            .overlay(fillView(fractionCompleted: fractionCompleted, isIndefinite: isIndefinite))
            .frame(width: defaultSize, height: defaultSize)
    }
    
    private func fillView(fractionCompleted: Double,
                          isIndefinite: Bool) -> some View {
        Circle() // the fill view is also a circle
            .trim(from: 0, to: CGFloat(fractionCompleted))
            .stroke(Color("ShragaBlue"), lineWidth: lineWidth)
            .frame(width: defaultSize - lineWidth, height: defaultSize - lineWidth)
            .rotationEffect(fillRotationAngle)
        // triggers the infinite rotation animation for indefinite progress views
            .onAppear {
                if isIndefinite {
                    withAnimation(.easeInOut(duration: 1).repeatForever()) {
                        fillRotationAngle = .degrees(270)
                    }
                }
            }
    }
}
