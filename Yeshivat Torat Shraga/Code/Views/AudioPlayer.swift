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
    @ObservedObject var player = Player()
    var audio: Audio?
    
    // MARK: This needs to refresh every time from... somewhere?
//    @State private var isFavorited: Bool = false
    @State private var showFavoritesAlert = false
    @State private var favoriteErr: Error?
    @State private var favoriteIDs = Favorites.shared.favoriteIDs
    var refreshFavorites: (() -> Void)?
    
    init(refreshFavorites: (() -> Void)? = nil) {
        self.refreshFavorites = refreshFavorites
//        self.isFavorited = (audio?.favoritedAt != nil)
    }
    
    mutating func set(audio: Audio) {
        self.audio = audio
        
        if let sourceURL = audio.sourceURL {
            let playerItem = AVPlayerItem(url: sourceURL)
            let player = AVPlayer(playerItem: playerItem)
            //            self.avPlayer.prepareToPlay()
            //            avPlayer.volume = 1.0
            //        player.play()
            //            self.model = AudioPlayerModel(player: player)
            //            self.avPlayer = player
            self.player.set(avPlayer: player)
        } else {
            print("Audio sourceURL is nil, could not set audio.")
        }
    }
    
    mutating func play(audio: Audio) {
        self.set(audio: audio)
        self.play()
    }
    
    func play() {
        self.player.play()
        
        UIApplication.shared.beginReceivingRemoteControlEvents()
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.nextTrackCommand.isEnabled = false
        //        commandCenter.nextTrackCommand.addTarget(self, action:#selector(nextTrackCommandSelector))
        commandCenter.previousTrackCommand.isEnabled = false
        
        commandCenter.togglePlayPauseCommand.isEnabled = true
        
        commandCenter.playCommand.addTarget { event in
            if self.player.timeControlStatus == .paused {
                self.play()
                return .success
            } else {
                return .commandFailed
            }
        }
        
        commandCenter.pauseCommand.addTarget { event in
            if self.player.timeControlStatus == .playing {
                self.pause()
                return .success
            }
            return .commandFailed
        }
        
        var nowPlayingInfo = [String : Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = audio?.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = audio?.author.name
        
        if let image = UIImage(named: "Logo") {
            nowPlayingInfo[MPMediaItemPropertyArtwork] =
            MPMediaItemArtwork(boundsSize: image.size) { size in
                return image
            }
        }
        
        commandCenter.changePlaybackPositionCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.addTarget { event in
            if let event = event as? MPChangePlaybackPositionCommandEvent {
                let time = CMTime(seconds: event.positionTime, preferredTimescale: 1000000)
                self.player.avPlayer?.seek(to: time)
                return .success
            } else {
                return .commandFailed
            }
        }
        
        Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { _ in
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.displayTime
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = player.itemDuration
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player.avPlayer?.rate
            nowPlayingInfo[MPNowPlayingInfoPropertyDefaultPlaybackRate] = 1.0
            
            // Set the metadata
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        }
        
        //        DispatchQueue.global(qos: .background).async {
        //            while player.avPlayer?.currentItem?.duration == nil {}
        //            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.displayTime
        //            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = player.itemDuration
        //            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player.avPlayer?.rate
        //            nowPlayingInfo[MPNowPlayingInfoPropertyDefaultPlaybackRate] = 1.0
        //
        //            // Set the metadata
        //            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        //        }
    }
    
    func pause() {
        self.player.pause()
    }
    
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
                        Text(self.audio?.title ?? "")
                            .font(.title3)
                            .bold()
                        Spacer()
                    }
                    HStack {
                        Text(self.audio?.author.name ?? "")
                            .font(.subheadline)
                            .foregroundColor(Color(UIColor.systemGray5))
                        Spacer()
                    }
                }
                .foregroundColor(.white)
                
                Spacer()
                
                if let author = self.audio?.author as? DetailedRabbi {
                    DownloadableImage(object: author)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                        .shadow(radius: UI.shadowRadius)
                }
            }.padding(.horizontal)
            
            Group {
                if self.player.itemDuration >= 0 {
                    Slider(value: self.$player.displayTime, in: (0...self.player.itemDuration), onEditingChanged: { (scrubStarted) in
                        Haptics.shared.impact()
                        if scrubStarted {
                            self.player.scrubState = .scrubStarted
                        } else {
                            self.player.scrubState = .scrubEnded(self.player.displayTime)
                        }
                    })
                        .accentColor(Color("ShragaGold"))
                } else {
                    ProgressView().progressViewStyle(LinearProgressViewStyle())
                }
                
                HStack {
                    if let displayTime = self.player.displayTime, displayTime.isFinite {
                        Text("\(timeFormattedMini(totalSeconds: displayTime))")
                            .font(.caption2)
                            .foregroundColor(.white)
                    } else {
                        Text("--:--")
                            .font(.caption2)
                            .foregroundColor(.white)
                    }
                    Spacer()
                    if let duration = self.player.itemDuration, duration.isFinite {
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
                        player.scrub(seconds: -10)
                    }, label: {
                        Image(systemName: "gobackward.10")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }).frame(width: 20)
                    
                    Spacer()
                    
                    Button(action: {
                        Haptics.shared.play(.rigid)
                        player.scrub(seconds: -30)
                    }, label: {
                        Image(systemName: "gobackward.30")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    })
                        .frame(width: 25)
                    
//                    Spacer()
                    
//                    Button(action: {
//                        Haptics.shared.play(.soft)
//                    }, label: {
//                        Image(systemName: "backward.fill")
//                            .resizable()
//                            .aspectRatio(contentMode: .fit)
//                    })
//                        .frame(width: 40)
                }
                
                Group {
                    Spacer()
                    
                    if RootModel.audioPlayer.player.timeControlStatus == .paused {
                        Button(action: {
                            Haptics.shared.play(.soft)
                            self.play()
                        }, label: {
                            Image(systemName: "play.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        })
                            .frame(width: 30)
                    } else if RootModel.audioPlayer.player.timeControlStatus == .playing {
                        Button(action: {
                            Haptics.shared.play(.soft)
                            self.pause()
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
//                    Button(action: {
//                        Haptics.shared.play(.light)
//                    }, label: {
//                        Image(systemName: "forward.fill")
//                            .resizable()
//                            .aspectRatio(contentMode: .fit)
//                    })
//                        .frame(width: 40)
                    
//                    Spacer()
                    
                    Button(action: {
                        Haptics.shared.play(.rigid)
                        player.scrub(seconds: 30)
                    }, label: {
                        Image(systemName: "goforward.30")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }).frame(width: 25)
                    
                    Spacer()
                    
                    Button(action: {
                        Haptics.shared.play(.rigid)
                        player.scrub(seconds: 10)
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
                
                if let audio = audio, let favoriteIDs = favoriteIDs {
                Button(action: {
//                    MARK: CLEAN UP
                        if favoriteIDs.contains(audio.firestoreID) {
                            Favorites.shared.delete(audio) { favorites, error in
//                                MARK: USE THESE FAVORITES THAT ARE RETURNED IN THE UPDATE, AS OPPOSED TO CALLING THE FUNCTION AGAIN
                                self.refreshFavorites?()
                            }
                        } else {
                            Favorites.shared.save(audio) { favorites, error in
//                                MARK: USE THESE FAVORITES THAT ARE RETURNED IN THE UPDATE, AS OPPOSED TO CALLING THE FUNCTION AGAIN
                                self.refreshFavorites?()
                            }
                        }
                    self.favoriteIDs = Favorites.shared.getfavoriteIDs()
                }, label: {
                    Image(systemName: favoriteIDs.contains(audio.firestoreID)
                          ? "heart.fill"
                          : "heart")
                        .foregroundColor(Color("ShragaGold"))
                        .frame(width: 20, height: 20)
                }).buttonStyle(iOS14BorderedProminentButtonStyle())
                }
                
                Menu {
                    Button(action: {
                        Haptics.shared.play(.rigid)
                        self.player.setRate(0.5)
                    }) {
                        Label("0.5x", systemImage: (self.player.avPlayer?.rate == 0.5) ? "checkmark" : "tortoise")
                    }
                    Button(action: {
                        Haptics.shared.play(.rigid)
                        self.player.setRate(0.75)
                    }) {
                        Label("0.75x", systemImage: (self.player.avPlayer?.rate == 0.75) ? "checkmark" : "")
                    }
                    Button(action: {
                        Haptics.shared.play(.rigid)
                        self.player.setRate(1)
                    }) {
                        Label("1x", systemImage: (self.player.avPlayer?.rate == 1) ? "checkmark" : "figure.walk")
                    }
                    Button(action: {
                        Haptics.shared.play(.rigid)
                        self.player.setRate(1.5)
                    }) {
                        Label("1.5x", systemImage: (self.player.avPlayer?.rate == 1.5) ? "checkmark" : "")
                    }
                    Button(action: {
                        Haptics.shared.play(.rigid)
                        self.player.setRate(2)
                    }) {
                        Label("2x", systemImage: (self.player.avPlayer?.rate == 2) ? "checkmark" : "hare")
                    }
                } label: {
                    Image(systemName: "speedometer")
                        .resizable()
                        .foregroundColor(.gray)
                        .frame(width: 20, height: 20)
                }
                .menuStyle(iOS14BorderedProminentMenuStyle())
//                .frame(width: 45, height: 45)
//                .offset(y: 1)
                
                Button(action: {
                    
                }, label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.gray)
                        .frame(width: 20, height: 20)
                }).buttonStyle(iOS14BorderedProminentButtonStyle())
                Spacer()
            }
            Spacer()
        }
        .background(LinearGradient(
            colors: [Color("ShragaBlue"), Color(white: 0.8)],
            startPoint: .bottomLeading, endPoint: .topTrailing)
                        .ignoresSafeArea())
        
        .onAppear {
            favoriteIDs = Favorites.shared.favoriteIDs
//            if let audio = audio {
//                isFavorited = favoriteIDs?.contains(audio.firestoreID) ?? false
//            } else {
//                isFavorited = false
//            }
        }
        
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
    }
}

struct AudioPlayer_Previews: PreviewProvider {
    static var audioPlayer = AudioPlayer()
    
    init() {
        AudioPlayer_Previews.audioPlayer.set(audio: Audio.sample)
    }
    
    static var previews: some View {
        Group {
            audioPlayer
        }
    }
}
