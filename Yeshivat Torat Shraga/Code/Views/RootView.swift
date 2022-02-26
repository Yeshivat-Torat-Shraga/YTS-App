//
//  RootView.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 11/9/21.
//

import SwiftUI
import SwiftyGif

struct RootView: View {
    @StateObject var model = RootModel()
    @State private var imageData: Data? = nil
    @State var selectedView = 0
    
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
                }
                .onChange(of: selectedView) { _ in
                    Haptics.shared.impact()
                }
            }
        }
        .alert(isPresented: Binding(get: {
            model.showError
        }, set: {
            model.showError = $0
        }), content: {
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
    static var previews: some View {
        RootView()
    }
}
