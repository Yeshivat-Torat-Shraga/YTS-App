//
//  RootView.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 11/9/21.
//

import SwiftUI

struct RootView: View {
    @StateObject var root = RootModel()
    
    var body: some View {
        TabView {
            HomeView()
                .foregroundColor(Color("ShragaBlue"))
                .tabItem{
                    Label("Home", systemImage: "house")
                }
                .overlay(VStack {
                    Spacer()
                    PlayBar(audioCurrentlyPlaying: RootModel.audioPlayerBinding.audio)
                })
//                .overlay {
//                    PlayBar(audioCurrentlyPlaying: RootModel.audioPlayerBinding.audio)
//                }
                
        }.accentColor(Color("ShragaBlue"))
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
