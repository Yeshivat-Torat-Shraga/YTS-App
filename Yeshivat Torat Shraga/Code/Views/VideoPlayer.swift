//
//  VideoPlayer.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 08/02/2022.
//

import SwiftUI
import AVKit
import MediaPlayer

struct VideoPlayer: View {
    @ObservedObject var player = Player()
    var video: Video?
    let speeds: [Float] = [0.75, 1.00, 1.25,
                           1.50, 1.75, 2.00]
    @State private var selectedSpeedIndex = 1 // 2nd out of 7 (1.00)
    // MARK: This needs to refresh every time from... somewhere?
//    @State private var isFavorited: Bool = false
    @State private var showFavoritesAlert = false
    @State private var favoriteErr: Error?
    @State private var favoriteIDs = Favorites.shared.favoriteIDs
    var refreshFavorites: (() -> Void)?
    
    init(refreshFavorites: (() -> Void)? = nil) {
        self.refreshFavorites = refreshFavorites
//        self.isFavorited = (video?.favoritedAt != nil)
    }
    
    mutating func set(video: Video) {
        self.video = video
        
        if let sourceURL = video.sourceURL {
            let playerItem = AVPlayerItem(url: sourceURL)
            let player = AVPlayer(playerItem: playerItem)
            //            self.avPlayer.prepareToPlay()
            //            avPlayer.volume = 1.0
            //        player.play()
            //            self.model = VideoPlayerModel(player: player)
            //            self.avPlayer = player
            self.player.set(avPlayer: player)
        } else {
            print("Video sourceURL is nil, could not set video.")
        }
    }
    
    mutating func play(video: Video) {
        self.set(video: video)
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
        nowPlayingInfo[MPMediaItemPropertyTitle] = video?.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = video?.author.name
        
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
            if let player = player.avPlayer {
                YTSPlayerController(player: player)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: UI.cornerRadius))
                    .padding()
                    .shadow(radius: UI.shadowRadius)
                
            } else {
                Image("Logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: UI.cornerRadius))
                    .padding()
                    .shadow(radius: UI.shadowRadius)
                    .preferredColorScheme(.light)
            }
            
            HStack {
                VStack {
                    HStack {
                        Text(self.video?.title ?? "")
                            .font(.title3)
                            .bold()
                        Spacer()
                    }
                    HStack {
                        Text(self.video?.author.name ?? "")
                            .font(.subheadline)
                            .foregroundColor(Color(UIColor.systemGray5))
                        Spacer()
                    }
                }
                .foregroundColor(.white)
                
                Spacer()
                
                if let author = self.video?.author as? DetailedRabbi {
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
                    Spacer()
                    
                    Button(action: {
                        Haptics.shared.play(.rigid)
                        player.scrub(seconds: -30)
                    }, label: {
                        Image(systemName: "gobackward.30")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    })
                        .frame(width: 20)
                    
                    Spacer()
                    
                    Button(action: {
                        Haptics.shared.play(.soft)
                    }, label: {
                        Image(systemName: "backward.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    })
                        .frame(width: 40)
                }
                
                Group {
                    Spacer()
                    
                    if RootModel.videoPlayer.player.timeControlStatus == .paused {
                        Button(action: {
                            Haptics.shared.play(.soft)
                            self.play()
                        }, label: {
                            Image(systemName: "play.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        })
                            .frame(width: 30)
                    } else if RootModel.videoPlayer.player.timeControlStatus == .playing {
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
                    Button(action: {
                        Haptics.shared.play(.light)
                    }, label: {
                        Image(systemName: "forward.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }).frame(width: 40)
                    
                    Spacer()
                    
                    Button(action: {
                        Haptics.shared.play(.rigid)
                        player.scrub(seconds: 30)
                    }, label: {
                        Image(systemName: "goforward.30")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }).frame(width: 20)
                    
                    Spacer()
                }
                Spacer()
            }.frame(height: 50)
            
            Spacer()
            
            HStack {
                Spacer()
                
                if let video = video, let favoriteIDs = favoriteIDs {
                Button(action: {
//                    MARK: CLEAN UP
                        if favoriteIDs.contains(video.firestoreID) {
                            Favorites.shared.delete(video) { favorites, error in
//                                MARK: USE THESE FAVORITES THAT ARE RETURNED IN THE UPDATE, AS OPPOSED TO CALLING THE FUNCTION AGAIN
                                self.refreshFavorites?()
                            }
                        } else {
                            Favorites.shared.save(video) { favorites, error in
//                                MARK: USE THESE FAVORITES THAT ARE RETURNED IN THE UPDATE, AS OPPOSED TO CALLING THE FUNCTION AGAIN
                                self.refreshFavorites?()
                            }
                        }
                    self.favoriteIDs = Favorites.shared.getfavoriteIDs()
                }, label: {
                    Image(systemName: favoriteIDs.contains(video.firestoreID)
                          ? "heart.fill"
                          : "heart")
                        .foregroundColor(Color("ShragaGold"))
                        .frame(width: 20, height: 20)
                }).buttonStyle(iOS14BorderedProminentButtonStyle())
                }
                
                Button(action: {
                    Haptics.shared.play(.rigid)
                    selectedSpeedIndex = (selectedSpeedIndex + 1) % speeds.count
                    player.setRate(speeds[selectedSpeedIndex])
                }, label: {
                    Text("x\(speeds[selectedSpeedIndex].trim())")
                        .foregroundColor(.gray)
                        .frame(width: 45, height: 20)
                }).buttonStyle(iOS14BorderedProminentButtonStyle())
                
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
//            if let video = video {
//                isFavorited = favoriteIDs?.contains(video.firestoreID) ?? false
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

struct VideoPlayer_Previews: PreviewProvider {
    static var videoPlayer = VideoPlayer()
    
    init() {
        VideoPlayer_Previews.videoPlayer.set(video: Video.sample)
    }
    
    static var previews: some View {
        Group {
            videoPlayer
        }
    }
}
