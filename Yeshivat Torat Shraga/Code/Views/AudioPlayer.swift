//
//  AudioPlayer.swift
//  Yeshivat Torat Shraga
//
//  Created by David Reese on 11/22/21.
//

import SwiftUI
import AVKit
import MediaPlayer

struct AudioPlayer: View {
    @EnvironmentObject var model: AudioPlayerModel
    @EnvironmentObject var favorites: Favorites
    @State private var favoriteErr: Error?
    @State private var isFavoritesBusy = false
    @State private var sharing = false
    @State private var heartFillOverride = true

    var body: some View {
        VStack {
            Image("Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .background(Color.adaptiveBG)
                .clipShape(RoundedRectangle(cornerRadius: UI.cornerRadius))
                .padding()
                .shadow(radius: UI.shadowRadius)
//                .preferredColorScheme(.light)
            
            HStack {
                VStack {
                    HStack {
                        Text(model.audio?.title ?? "")
                            .font(.title3)
                            .bold()
                        Spacer()
                    }
                    
                    Spacer().frame(height: 1)
                    
                    HStack {
                        Text(model.audio?.author.name ?? "")
                            .font(.subheadline)
                            .foregroundColor(Color(UIColor.systemGray5))
                        Spacer()
                    }
                }
                .foregroundColor(.white)
                
                Spacer()
                
                if let author = model.audio?.author as? DetailedRabbi {
                    DownloadableImage(object: author)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                        .shadow(radius: UI.shadowRadius)
                }
            }.padding(.horizontal)
            
            Group {
                if model.player.itemDuration >= 0 {
                    Slider(value: $model.player.displayTime, in: (0...model.player.itemDuration)) { scrubStarted in
                        Haptics.shared.impact()
                        if scrubStarted {
                            model.player.scrubState = .scrubStarted
                        } else {
                            model.player.scrubState = .scrubEnded(model.player.displayTime)
                        }
                    }
                    .accentColor(Color("ShragaGold"))
                } else {
                    ProgressView().progressViewStyle(LinearProgressViewStyle())
                }
                
                HStack {
                    if let displayTime = model.player.displayTime, displayTime.isFinite {
                        Text("\(timeFormattedMini(totalSeconds: displayTime))")
                            .font(.caption2)
                            .foregroundColor(.white)
                    } else {
                        Text("--:--")
                            .font(.caption2)
                            .foregroundColor(.white)
                    }
                    Spacer()
                    if let duration = model.player.itemDuration, duration.isFinite {
                        Text("\(timeFormattedMini(totalSeconds: duration))")
                            .font(.caption2)
                            .foregroundColor(.white)
                    } else {
                        Text("--:--")
                            .font(.caption2)
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            HStack {
                Spacer()
                Group {
                    //                    Spacer()
                    
                    Button(action: {
                        Haptics.shared.play(.rigid)
                        model.player.scrub(seconds: -10)
                    }, label: {
                        Image(systemName: "gobackward.10")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }).frame(width: 20)
                    
                    Spacer()
                    
                    Button(action: {
                        Haptics.shared.play(.rigid)
                        model.player.scrub(seconds: -30)
                    }, label: {
                        Image(systemName: "gobackward.30")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    })
                    .frame(width: 25)
                    
                }
                
                Group {
                    Spacer()
                    
                    if model.player.timeControlStatus == .paused {
                        Button(action: {
                            Haptics.shared.play(.soft)
                            let threshhold = 0.05
                            if model.player.displayTime + threshhold >= model.player.itemDuration {
                                model.player.scrub(to: .zero)
                            }
                            model.play()
                        }, label: {
                            Image(systemName: "play.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        })
                        .frame(width: 30)
                    } else if model.player.timeControlStatus == .playing {
                        Button(action: {
                            Haptics.shared.play(.soft)
                            model.pause()
                        }, label: {
                            Image(systemName: "pause.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        }).frame(width: 25)
                    } else {
                        ProgressView()
                            .progressViewStyle(YTSProgressViewStyle())
                    }
                    
                    Spacer()
                }
                
                Group {
                    
                    Button(action: {
                        Haptics.shared.play(.rigid)
                        model.player.scrub(seconds: 30)
                    }, label: {
                        Image(systemName: "goforward.30")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }).frame(width: 25)
                    
                    Spacer()
                    
                    Button(action: {
                        Haptics.shared.play(.rigid)
                        model.player.scrub(seconds: 10)
                    }, label: {
                        Image(systemName: "goforward.10")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }).frame(width: 20)
                    
                    //                    Spacer()
                }
                Spacer()
            }.frame(height: 50)
            
            Spacer()
            
            HStack {
                Spacer()
                
                if let audio = model.audio, let favoriteIDs = favorites.favoriteIDs {
                    Button(action: {
                        if !isFavoritesBusy {
                            heartFillOverride = false
                            isFavoritesBusy = true
                            if favoriteIDs.contains(audio.firestoreID) {
                                favorites.delete(audio) { favorites, error in
                                    isFavoritesBusy = false
                                }
                            } else {
                                heartFillOverride = true
                                self.favorites.save(audio) { favorites, error in
                                    isFavoritesBusy = false
                                }
                            }
                        }
                    }, label: {
                        Image(systemName: isFavoritesBusy
                              ? heartFillOverride
                              ? "heart.fill"
                              : "heart"
                              
                              : favoriteIDs.contains(audio.firestoreID)
                              ? "heart.fill"
                              : "heart")
                        .foregroundColor(.shragaGold)
                        .frame(width: 20, height: 20)
                    }).buttonStyle(iOS14BorderedProminentButtonStyle())
                }
                
                Menu {
                    Button(action: {
                        Haptics.shared.play(.rigid)
                        model.player.setRate(0.5)
                    }) {
                        Label("0.5x", systemImage: (model.player.avPlayer?.rate == 0.5) ? "checkmark" : "tortoise")
                    }
                    Button(action: {
                        Haptics.shared.play(.rigid)
                        model.player.setRate(0.75)
                    }) {
                        Label("0.75x", systemImage: (model.player.avPlayer?.rate == 0.75) ? "checkmark" : "")
                    }
                    Button(action: {
                        Haptics.shared.play(.rigid)
                        model.player.setRate(1)
                    }) {
                        Label("1x", systemImage: (model.player.avPlayer?.rate == 1) ? "checkmark" : "figure.walk")
                    }
                    Button(action: {
                        Haptics.shared.play(.rigid)
                        model.player.setRate(1.5)
                    }) {
                        Label("1.5x", systemImage: (model.player.avPlayer?.rate == 1.5) ? "checkmark" : "")
                    }
                    Button(action: {
                        Haptics.shared.play(.rigid)
                        model.player.setRate(2)
                    }) {
                        Label("2x", systemImage: (model.player.avPlayer?.rate == 2) ? "checkmark" : "hare")
                    }
                } label: {
                    Image(systemName: "speedometer")
                        .resizable()
                        .foregroundColor(.gray)
                        .frame(width: 20, height: 20)
                }
                .menuStyle(iOS14BorderedProminentMenuStyle())
                
                Button(action: {
                    if model.audio?.storedShareURL != nil {
                        sharing = true
                    }
                }, label: {
                    if model.audio?.storedShareURL == nil {
                        ProgressView()
                            .progressViewStyle(YTSProgressViewStyle())
                    } else {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.gray)
                            .frame(width: 20, height: 20)
                    }
                }).buttonStyle(iOS14BorderedProminentButtonStyle())
                
                Spacer()
            }
//            .preferredColorScheme(.light)
            Spacer()
        }
//        .preferredColorScheme(.light)
        .background(LinearGradient(
            colors: [Color("ShragaBlue"), Color(white: 0.8)],
            startPoint: .bottomLeading, endPoint: .topTrailing)
            .ignoresSafeArea())
        .alert(isPresented: Binding (get: {
            favoriteErr != nil
        }, set: {
            favoriteErr = $0 ? favoriteErr : nil
        })) {
            Alert(
                title: Text("Error"),
                message: Text(
                    favoriteErr?.getUIDescription() ??
                    "An unknown error occured while saving your changes."),
                dismissButton: Alert.Button.default(
                    Text("OK")
                )
            )
        }
        .sheet(isPresented: $sharing) {
            if let audio = model.audio, let shareURL = audio.storedShareURL {
                if let title = audio.title, let authorName = audio.author.name {
                    ShareSheet(activityItems: [MyActivityItemSource(title: title,
                                                                    text:  "Torat Shraga Shiur by \(authorName)"),
                                               shareURL])
                }
            } else {
                Text("Sorry, there was a problem sharing this content.")
                    .padding()
            }
        }
        .preferredColorScheme(.light)
    }
}

struct AudioPlayer_Previews: PreviewProvider {
    
    static var model: RootModel = RootModel()
    static var audioPlayerModel = AudioPlayerModel(player: Player())

    
    init() {
        let model = AudioPlayerModel(player: Player())
        model.set(audio: Audio.sample)
    }
    
    static var previews: some View {
        Group {
            AudioPlayer()
                .environmentObject(AudioPlayer_Previews.model)
                .environmentObject(Favorites())
        }
    }
}
