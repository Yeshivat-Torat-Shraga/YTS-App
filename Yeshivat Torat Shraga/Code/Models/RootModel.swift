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
    internal var retry: (() -> Void)?
    @Published var showError: Bool = false
    internal var errorToShow: Error?
        
    @Published var showLoadingScreen = true
    @Published var homeView: HomeView?
    @Published var favoritesView: FavoritesView
    @Published var newsView: NewsView
    @Published var settingsView: SettingsView

    @Published var alert: Alert?
    
//    @EnvironmentObject var audioPlayerModel: AudioPlayerModel
    
    init(miniPlayerShowing: Binding<Bool>) {
        
        let appearance = UITabBar.appearance()
        appearance.standardAppearance.backgroundEffect = UIBlurEffect(style: .systemChromeMaterial)
        if #available(iOS 15.0, *) {
            let scrollEdgeAppearance = UITabBarAppearance()
            scrollEdgeAppearance.backgroundEffect = UIBlurEffect(style: .systemChromeMaterial)
            appearance.scrollEdgeAppearance = scrollEdgeAppearance
        }
        
        self.favoritesView = FavoritesView(miniPlayerShowing: miniPlayerShowing)
        
        self.newsView = NewsView(miniPlayerShowing: miniPlayerShowing)
        
        self.settingsView = SettingsView(miniPlayerShowing: miniPlayerShowing)
        
        self.homeView = HomeView(hideLoadingScreen: {
            self.showLoadingScreen = false
        }, showErrorOnRoot: { error, retry in
            self.showError(error: error, retry: retry!)
        }, miniPlayerShowing: miniPlayerShowing)
        
        if isFirstLaunch {
            showOnboarding = true
            isFirstLaunch = false
        }
    }
    
}
