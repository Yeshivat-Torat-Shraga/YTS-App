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
    @StateObject var model = RootModel()
    @State var player: Player
    @State var audioPlayerModel: AudioPlayerModel
    @State private var imageData: Data? = nil
    @State var selectedView = 0
    
    init() {
        let player = Player()
        self.player = player
        let audioPlayerModel = AudioPlayerModel(player: player)
        self.audioPlayerModel = audioPlayerModel
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
                        }
                        .tag(0)
                        .overlay(VStack {
                            Spacer()
                            PlayBar()
                        })
                    FavoritesView()
                        .tabItem {
                            Label("Favorites", systemImage: "heart.fill")
                        }
                        .tag(1)
                        .overlay(VStack {
                            Spacer()
                            PlayBar()
                        })
                    if #available(iOS 15.0, *), model.newsView.model.hasUnreadArticles {
                        model.newsView
                            .tabItem {
                                Label("Text", systemImage: "newspaper.fill")
                            }
                            .tag(2)
                            .badge("!")
                            .overlay(VStack {
                                Spacer()
                                PlayBar()
                            })
                    } else {
                        model.newsView
                            .tabItem {
                                Label("Text", systemImage: "newspaper.fill")
                            }
                            .tag(2)
                            .overlay(VStack {
                                Spacer()
                                PlayBar()
                            })
                    }
                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: "gearshape")
                        }
                        .tag(3)
                        .overlay(VStack {
                            Spacer()
                            PlayBar()
                        })
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
        .environmentObject(audioPlayerModel)
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
            .environmentObject(Favorites())
    }
}
