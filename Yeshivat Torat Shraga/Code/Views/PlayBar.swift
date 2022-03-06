//
//  PlayBar.swift
//  Yeshivat Torat Shraga
//
//  Created by David Reese on 11/27/21.
//

import SwiftUI

struct PlayBar: View {
    @StateObject var model: PlayBarModel = PlayBarModel()
    var audioCurrentlyPlaying: Binding<Audio?>
    let lightColor = Color(hex: 0xDEDEDE)
    let darkColor = Color(hex: 0x121212)
    @State private var presenting = false
    @Environment(\.colorScheme) var colorScheme
    
    init(audioCurrentlyPlaying: Binding<Audio?>) {
        self.audioCurrentlyPlaying = audioCurrentlyPlaying
    }
    
    var body: some View {
        if let audioCurrentlyPlaying = audioCurrentlyPlaying.wrappedValue {
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
                    if RootModel.audioPlayer.player.timeControlStatus == .playing {
                        Button(action: {
                            RootModel.audioPlayer.pause()
                            self.model.objectWillChange.send()
                        }, label: {
                            Image(systemName: "pause.fill")
                            //                                .resizable()
                            //                                .frame(width: 20, height: 25)
                        })
                    } else if RootModel.audioPlayer.player.timeControlStatus == .paused {
                        Button(action: {
                            RootModel.audioPlayer.play()
                            self.model.objectWillChange.send()
                        }, label: {
                            Image(systemName: "play.fill")
                                .padding()
                            //                                .resizable()
                            //                                .frame(width: 25, height: 25)
                        })
                    } else {
                        ProgressView().progressViewStyle(YTSProgressViewStyle())
                        //                            .frame(width: 25, height: 25)
                    }
                    Button(action: {}, label: {
                        Image(systemName: "forward.fill")
                            .padding()
                        //                            .resizable()
                        //                            .frame(width: 45, height: 25)
                    })
                }
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
                RootModel.audioPlayer
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
    static var previews: some View {
        TabView {
            HomeView()
                .overlay(VStack {
                    Spacer()
                    PlayBar(audioCurrentlyPlaying: .constant(.sample))
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
                .preferredColorScheme(.dark)
        //            .previewLayout(.fixed(width: 390, height: 80))
    }
}
