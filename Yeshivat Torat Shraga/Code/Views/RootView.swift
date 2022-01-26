//
//  RootView.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 11/9/21.
//

import SwiftUI

struct RootView: View {
//    @AppStorage("tapCount") private var tapCount = 0
//    @AppStorage("feedback") private var feedback: UIImpactFeedbackGenerator.FeedbackStyle = .light
    @StateObject var model = RootModel()
    @State var selectedView = 0
    
    var body: some View {
        TabView(selection: $selectedView) {
            model.homeView
                .tabItem {
                    Label("Home", systemImage: "house")
                }.tag(0)
                .overlay(VStack {
                    Spacer()
                    PlayBar(audioCurrentlyPlaying: RootModel.audioPlayerBinding.audio)
                })
            model.favoritesView
                .tabItem {
                    Label("Favorites", systemImage: "heart.fill")
                }.tag(1)
            model.newsView
                .tabItem {
                    Label("News", systemImage: "newspaper.fill")
                }.tag(2)
            model.settingsView
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }.tag(3)
            HapticTestingView()
                .tabItem {
                    Label("Haptics", systemImage: "iphone.radiowaves.left.and.right")
                }.tag(4)
                
        }
        .foregroundColor(Color("ShragaBlue"))
        .accentColor(Color("ShragaBlue"))
        .onChange(of: selectedView) { _ in
            Haptics.shared.impact()
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
