//
//  Root.swift
//  Yeshivat Torat Shraga
//
//  Created by David Reese on 11/9/21.
//

import Foundation
import SwiftUI

class RootModel: ObservableObject {
    static var audioPlayer: AudioPlayer = AudioPlayer()
    static var videoPlayer: VideoPlayer = VideoPlayer()
    static var audioPlayerBinding: Binding<AudioPlayer> = Binding {
        audioPlayer
    } set: { val in
        audioPlayer = val
    }
    
    @Published var showLoadingScreen = true
    @Published var homeView: HomeView?
    var favoritesView = FavoritesView()
    var newsView = NewsView()
    var settingsView = SettingsView()
    
    
    init() {
        let appearance = UITabBar.appearance()
        appearance.standardAppearance.backgroundEffect = UIBlurEffect(style: .systemChromeMaterial)
        if #available(iOS 15.0, *) {
            let scrollEdgeAppearance = UITabBarAppearance()
            scrollEdgeAppearance.backgroundEffect = UIBlurEffect(style: .systemChromeMaterial)
            appearance.scrollEdgeAppearance = scrollEdgeAppearance
        }
        homeView = HomeView() {
            self.showLoadingScreen = false
        }
        
        RootModel.audioPlayer.refreshFavorites = {
            self.favoritesView.model.load()
        }
    }
    
}
