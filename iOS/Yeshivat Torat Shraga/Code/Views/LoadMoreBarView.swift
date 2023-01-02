/*
//
//  LoadMoreBarView.swift
//  Yeshivat Torat Shraga
//
//  Created by David Reese in 2021.
//

import SwiftUI

struct LoadMoreBar: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    var action: () -> Void = {}
    
    var body: some View {
        Button(action: {
            action()
        }) {
            VStack {
                Spacer()
                Spacer()
                HStack {
                    Spacer()
                    Image(systemName: "ellipsis")
                        .foregroundColor(colorScheme == .light
                                         ? .shragaBlue
                                         : .shragaGold)
                    Spacer()
                }
                Spacer()
                Spacer()
            }
        }
        .buttonStyle(BackZStackButtonStyle(backgroundColor: .cardViewBG))
        .cornerRadius(UI.cornerRadius)
        .shadow(radius: UI.shadowRadius)
    }
}

struct LoadMoreBar_Previews: PreviewProvider {
    static var previews: some View {
        LoadMoreBar()
    }
}
*/
