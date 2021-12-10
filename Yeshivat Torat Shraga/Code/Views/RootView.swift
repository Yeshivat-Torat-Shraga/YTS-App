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
                .tabItem {
                    Image(systemName: "house")
                }
                .overlay(VStack {
                    Spacer()
                    PlayBar(audioCurrentlyPlaying: RootModel.audioPlayerBinding.audio)
                })
            FavoritesView()
                .tabItem {
                    Image(systemName: "heart.fill")
                }
            NewsView()
                .tabItem {
                    Image(systemName: "newspaper")
                }
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape")
                }
                
        }
        .foregroundColor(Color("ShragaBlue"))
        .accentColor(Color("ShragaBlue"))
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
