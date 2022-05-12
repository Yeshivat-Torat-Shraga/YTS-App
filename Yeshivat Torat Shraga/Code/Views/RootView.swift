//
//  RootView.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 11/9/21.
//

import SwiftUI
import SwiftyGif

struct RootView: View {
    @EnvironmentObject var FavoritesManager: Favorites
    @State var model: RootModel
    @State var player: Player
    @State var audioPlayerModel = AudioPlayerModel(player: Player())
    @State private var imageData: Data? = nil
    @State var selectedView = 0
    
    init() {
        let player = Player()
        let audioPlayerModel = AudioPlayerModel(player: player)
        self.model = RootModel()
        self.audioPlayerModel = audioPlayerModel
        self.player = player
    }
    
    var body: some View {
        Group {
            if model.showLoadingScreen {
                LoadingPage()
            } else {
                TabView(selection: $selectedView) {
                    model.homeView
                        .tabItem {
                            Label("Home", systemImage: "house")
                        }.tag(0)
                        .overlay(VStack {
                            Spacer()
                            PlayBar()
                        })
                    model.favoritesView
                        .tabItem {
                            Label("Favorites", systemImage: "heart.fill")
                        }.tag(1)
                    if #available(iOS 15.0, *), model.newsView.model.hasUnreadArticles {
                        model.newsView
                            .tabItem {
                                Label("News", systemImage: "newspaper.fill")
                            }.tag(2)
                            .badge("!")
                    } else {
                        model.newsView
                            .tabItem {
                                Label("News", systemImage: "newspaper.fill")
                            }.tag(2)
                    }
                    model.settingsView
                        .tabItem {
                            Label("Settings", systemImage: "gearshape")
                        }.tag(3)
                }
                .onChange(of: selectedView) { _ in
                    Haptics.shared.impact()
                }
            }
        }
        .alert(isPresented: $model.showError, content: {
            Alert(
                title: Text("Oops! Something went wrong."),
                message: Text(model.errorToShow?.getUIDescription() ?? "We're not even sure what it is, but something is definitely not working. Sorry."),
                dismissButton: Alert.Button.default(
                    Text("Retry"), action: {
                        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                            self.model.retry?()
                        }
                    }))
        })
        .fullScreenCover(isPresented: $model.showOnboarding) {
            OnboardingView(dismiss: {model.showOnboarding = false})
                .background(Color.white.ignoresSafeArea())
        }
        .foregroundColor(Color("ShragaBlue"))
        .accentColor(Color("ShragaBlue"))
        .onAppear {
            model.setup(FavoritesManager)
        }
        .environmentObject(audioPlayerModel)
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
            .environmentObject(Favorites())
    }
}
