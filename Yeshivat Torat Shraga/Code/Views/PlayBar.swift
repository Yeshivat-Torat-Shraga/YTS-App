//
//  PlayBar.swift
//  Yeshivat Torat Shraga
//
//  Created by David Reese on 11/27/21.
//

import SwiftUI

struct PlayBar: View {
    @EnvironmentObject var audioPlayerModel: AudioPlayerModel
    @EnvironmentObject var favoritesManager: Favorites
    let lightColor = Color(hex: 0xDEDEDE)
    let darkColor = Color(hex: 0x121212)
    @State private var presenting = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        if let audioCurrentlyPlaying = audioPlayerModel.audio {
            HStack {
                //                DownloadableImage(object: audioCurrentlyPlaying)
                Image("Logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .background(Color(UIColor.systemGray5))
                    .frame(width: 35, height: 35)
                    .cornerRadius(UI.cornerRadius)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 8)
                    .shadow(radius: UI.shadowRadius)
                VStack {
                    HStack {
                        Text(audioCurrentlyPlaying.title)
                        Spacer()
                    }
                    HStack {
                        Text(audioCurrentlyPlaying.author.name)
                            .foregroundColor(Color("Gray"))
                        Spacer()
                    }
                }
                .font(.system(size: 14))
                Spacer()
                HStack {
                    Button(action: {
                        audioPlayerModel.player.scrub(seconds: -10)
                    }, label: {
                        Image(systemName: "gobackward.10")
                            .padding(.vertical)
                            .padding(.horizontal, 7)
                        //                            .resizable()
                        //                            .frame(width: 45, height: 25)
                    })
                    if audioPlayerModel.player.timeControlStatus == .playing {
                        Button(action: {
                            audioPlayerModel.pause()
                            self.model.objectWillChange.send()
                        }, label: {
                            Image(systemName: "pause.fill")
                                .padding()
                            //                                .resizable()
                            //                                .frame(width: 20, height: 25)
                        })
                    } else if audioPlayerModel.player.timeControlStatus == .paused {
                        Button(action: {
                            audioPlayerModel.play()
                            self.model.objectWillChange.send()
                        }, label: {
                            Image(systemName: "play.fill")
                                .padding()
                            //                                .resizable()
                            //                                .frame(width: 25, height: 25)
                        })
                    } else {
                        ProgressView().progressViewStyle(YTSProgressViewStyle())
                            .padding()
                        //                            .frame(width: 25, height: 25)
                    }
                }
                .padding(.trailing)
                .foregroundColor(.playerBarFG)
            }
            .frame(height: UI.playerBarHeight)
            .background(
                Button(action: {
                    presenting = true
                }) {
                    Blur(style: .systemChromeMaterial)
                }
                    .buttonStyle(BackZStackButtonStyle(backgroundColor: .clear, percentage: 30))
            )
            .sheet(isPresented: $presenting) {
                AudioPlayer()
                    .environmentObject(audioPlayerModel)
                    .environmentObject(favoritesManager)
            }
            .cornerRadius(UI.cornerRadius, corners: [.topLeft, .topRight])
            .clipped()
            //            .background(Color.clear.shadow(radius: UI.shadowRadius))
//            .padding(.bottom)
        } else {
            EmptyView()
        }
    }
}

struct PlayBar_Previews: PreviewProvider {
    
    static var model: RootModel = RootModel()
    static var audioPlayerModel = AudioPlayerModel(player: Player())
    static var favoritesManager = Favorites()

    
    init() {
        let model = AudioPlayerModel(player: Player())
        model.set(audio: Audio.sample)
    }

    static var previews: some View {
        TabView {
            HomeView()
                .overlay(VStack {
                    Spacer()
                    PlayBar()
                })
                .tabItem {
                    Label("Home", systemImage: "house")
                }.tag(0)
            SettingsView()
                .tabItem {
                    Label("Favorites", systemImage: "heart.fill")
                }.tag(1)
            SettingsView()
                .tabItem {
                    Label("News", systemImage: "newspaper.fill")
                }.tag(2)
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }.tag(3)
        }
        .environmentObject(audioPlayerModel)
        .environmentObject(favoritesManager)
    }
}
