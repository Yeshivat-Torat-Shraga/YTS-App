//
//  Root.swift
//  Yeshivat Torat Shraga
//
//  Created by David Reese on 11/9/21.
//

import Foundation
import SwiftUI

class RootModel: ObservableObject, ErrorShower {
    
    @AppStorage("firstLaunch")
    private var isFirstLaunch = true
    @Published var showOnboarding = false
        
    var retry: (() -> Void)?
    
    @Published var showError: Bool = false
    
    var errorToShow: Error?
        
    static var audioPlayer: AudioPlayer = AudioPlayer()
    static var audioPlayerBinding: Binding<AudioPlayer> = Binding {
        audioPlayer
    } set: { val in
        audioPlayer = val
    }
    
    @Published var showLoadingScreen = true
    @Published var homeView: HomeView?
    @Published var alert: Alert?
    var favoritesView = FavoritesView()
    var newsView = NewsView()
    var settingsView = SettingsView()
    
    
    init() {
        if isFirstLaunch {
            isFirstLaunch = false
            showOnboarding = true
        }
        let appearance = UITabBar.appearance()
        appearance.standardAppearance.backgroundEffect = UIBlurEffect(style: .systemChromeMaterial)
        if #available(iOS 15.0, *) {
            let scrollEdgeAppearance = UITabBarAppearance()
            scrollEdgeAppearance.backgroundEffect = UIBlurEffect(style: .systemChromeMaterial)
            appearance.scrollEdgeAppearance = scrollEdgeAppearance
        }
        homeView = HomeView(hideLoadingScreenClosure: {self.showLoadingScreen = false},
                            showErrorOnRoot: { error, retry in
            self.showError(error: error, retry: retry!)
        })
        RootModel.audioPlayer.refreshFavorites = {
            self.favoritesView.model.load()
        }
    }
    
}
