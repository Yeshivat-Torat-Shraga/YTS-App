//
//  MiniPlayer.swift
//  Yeshivat Torat Shraga
//
//  Created by David Reese on 11/27/21.
//

import SwiftUI

struct MiniPlayer: View {
    @EnvironmentObject var audioPlayerModel: AudioPlayerModel
    @EnvironmentObject var favoritesManager: Favorites
    @EnvironmentObject var player: Player
    let lightColor = Color(hex: 0xDEDEDE)
    let darkColor = Color(hex: 0x121212)
    @State private var presenting = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        if let audioCurrentlyPlaying = audioPlayerModel.audio {
            HStack {
                Image("Logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .background(Color(UIColor.systemGray5))
                    .frame(width: 35, height: 35)
                    .cornerRadius(UI.cornerRadius)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 8)
                    .shadow(radius: UI.shadowRadius)
                VStack(spacing: 3.0) {
                    Spacer()
                    HStack {
                        MarqueeText(
                            text: audioCurrentlyPlaying.title,
                            font: UIFont.systemFont(ofSize: 14),
                            leftFade: 16,
                            rightFade: 16,
                            startDelay: 3,
                            alignment: .leading
                        )
                        Spacer()
                    }
                    HStack {
                        Text(audioCurrentlyPlaying.author.name)
                            .font(.caption)
                            .foregroundColor(Color("Gray"))
                        Spacer()
                    }
                    Spacer()
                }
                .font(.system(size: 14))
                Spacer()
                HStack {
                    Button(action: {
                        Haptics.shared.play(.rigid)
                        player.scrub(seconds: -10)
                    }, label: {
                        Image(systemName: "gobackward.10")
                            .padding(.vertical)
                            .padding(.horizontal, 7)
                    })
                    if player.timeControlStatus == .playing {
                        Button(action: {
                            Haptics.shared.play(.soft)
                            audioPlayerModel.pause()
                        }, label: {
                            Image(systemName: "pause.fill")
                                .padding()
                        })
                    } else if player.timeControlStatus == .paused {
                        Button(action: {
                            Haptics.shared.play(.soft)
                            audioPlayerModel.play()
                        }, label: {
                            Image(systemName: "play.fill")
                                .padding()
                        })
                    } else {
                        ProgressView().progressViewStyle(YTSProgressViewStyle())
                            .padding()
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
                    .environmentObject(player)
            }
            .cornerRadius(UI.cornerRadius)
            .clipped()
        } else {
            EmptyView()
        }
    }
}

struct PlayBar_Previews: PreviewProvider {
    
    static var audioPlayerModel = AudioPlayerModel(player: Player())
    static var favoritesManager = Favorites()

    
    init() {
        PlayBar_Previews.audioPlayerModel.set(audio: Audio.sample)
    }

    static var previews: some View {
        MiniPlayer()
            .environmentObject(Favorites())
            .environmentObject(audioPlayerModel)
            .environmentObject(favoritesManager)
    }
}
