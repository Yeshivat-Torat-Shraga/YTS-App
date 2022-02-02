//
//  LoadingPage.swift
//  Yeshivat Torat Shraga
//
//  Created by David Reese on 2/2/22.
//

import SwiftUI

struct LoadingPage: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            Spacer()
            if colorScheme == .dark {
                Gif(name: "logoDarkMode.gif")
                    .scaleEffect(1.25)
                    .aspectRatio(1.0, contentMode: .fit)
            } else {
                Gif(name: "logoLightMode.gif")
                    .scaleEffect(1.25)
                    .aspectRatio(1, contentMode: .fit)
            }
            
            ProgressView()
                .progressViewStyle(YTSProgressViewStyle())
            
            Spacer()
            
            Text("Developed by David Reese and Benji Tusk")
                .font(.callout)
                .multilineTextAlignment(.center)
        }
    }
}

struct LoadingPage_Previews: PreviewProvider {
    static var previews: some View {
        LoadingPage()
    }
}
