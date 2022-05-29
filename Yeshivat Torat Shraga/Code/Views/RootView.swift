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
    @ObservedObject var model: RootModel
    @State private var imageData: Data? = nil
    @State private var selectedView = 0
    
    init(miniPlayerShowing: Binding<Bool>) {
        self.model = RootModel(miniPlayerShowing: miniPlayerShowing)
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
                    model.favoritesView
                        .tabItem {
                            Label("Favorites", systemImage: "heart.fill")
                        }
                        .tag(1)
                    if #available(iOS 15.0, *), model.newsView.model.hasUnreadArticles {
                        model.newsView
                            .tabItem {
                                Label("Articles", systemImage: "newspaper.fill")
                            }
                            .tag(2)
                            .badge("!")
                    } else {
                        model.newsView
                            .tabItem {
                                Label("Articles", systemImage: "newspaper.fill")
                            }
                            .tag(2)
                    }
                    model.settingsView
                        .tabItem {
                            Label("Settings", systemImage: "gearshape")
                        }
                        .tag(3)
                    model.submitContentView
                        .tabItem {
                            Label("Submit", systemImage: "tray.and.arrow.up")
                        }
                        .tag(4)
                }
                .onChange(of: selectedView) { _ in
                    Haptics.shared.impact()
                }
            }
        }
        .fullScreenCover(isPresented: $model.showOnboarding) {
            OnboardingView(dismiss: {model.showOnboarding = false})
                .background(Color.white.ignoresSafeArea())
        }
        .overlay(VStack(spacing: 0) {
            Spacer()
            MiniPlayer()
                .shadow(radius: UI.shadowRadius)
                .padding(3)
            Spacer().frame(height: UI.playerBarHeight)
        })
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
        .foregroundColor(Color("ShragaBlue"))
        .accentColor(Color("ShragaBlue"))
    }
}

struct RootView_Previews: PreviewProvider {
    static var player = Player()
    
    static var previews: some View {
        RootView(miniPlayerShowing: .constant(false))
            .environmentObject(Favorites())
            .environmentObject(player)
            .environmentObject(AudioPlayerModel(player: RootView_Previews.player))
            
    }
}
