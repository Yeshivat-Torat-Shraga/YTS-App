//
//  EllipseButton.swift
//  Kol Hatorah Kulah SwiftUI
//
//  Created by David Reese on 4/1/21.
//

import SwiftUI

struct EllipseButton: View {
    var action: () -> Void
    var image: Image
    var foregroundColor: Color
    var backgroundColor: Color
    var width: CGFloat
    var height: CGFloat
    var alignment: Alignment
    
    init(action: @escaping () -> Void, imageSystemName name: String, foregroundColor: Color, backgroundColor: Color, width: CGFloat = 32.5, height: CGFloat = 32.5, alignment: Alignment = .center) {
        self.action = action
        self.image = Image(systemName: name)
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
        self.width = width
        self.height = height
        self.alignment = alignment
    }
    
    init(action: @escaping () -> Void, imageSystemName name: String, foregroundColor: Color, backgroundColor: Color, radius: CGFloat = 32.5, alignment: Alignment = .center) {
        self.action = action
        self.image = Image(systemName: name)
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
        self.width = radius
        self.height = radius
        self.alignment = alignment
    }
    
    var body: some View {
        Button(action: action, label: {
            ZStack {
                Ellipse()
                    .foregroundColor(self.backgroundColor)
                    .frame(width: self.width, height: self.height, alignment: self.alignment)
                
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: width/2, height: height/2, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                    .foregroundColor(self.foregroundColor)
            }
        }).frame(width: self.width, height: self.height, alignment: self.alignment)
    }
}

struct EllipseButton_Previews: PreviewProvider {
    static var previews: some View {
        EllipseButton(action: {}, imageSystemName: "heart.fill", foregroundColor: Color.blue, backgroundColor: Color.yellow)
    }
}
