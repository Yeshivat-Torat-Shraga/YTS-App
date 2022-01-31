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
    let speeds: [Float] = [0.75, 1.00, 1.25,
                           1.50, 1.75, 2.00]
    @State private var selectedSpeedIndex = 1 // 2nd out of 7 (1.00)
    
    
    init() {}
    
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
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: UI.cornerRadius))
                .padding()
                .shadow(radius: UI.shadowRadius)
                .preferredColorScheme(.light)
            
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
                    }, label: {
                        Image(systemName: "gobackward.30")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    })
                        .frame(width: 20)
                    
                    Spacer()
                    
                    Button(action: {
                    }, label: {
                        Image(systemName: "backward.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    })
                        .frame(width: 40)
                }
                
                Group {
                    Spacer()
                    
                    if RootModel.audioPlayer.player.timeControlStatus == .paused {
                        Button(action: {
                            self.play()
                        }, label: {
                            Image(systemName: "play.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        })
                            .frame(width: 30)
                    } else if RootModel.audioPlayer.player.timeControlStatus == .playing {
                        Button(action: {
                            self.pause()
                        }, label: {
                            Image(systemName: "pause.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        }).frame(width: 25)
                    } else {
                        ProgressView()
                    }
                    
                    Spacer()
                }
                
                Group {
                    Button(action: {
                    }, label: {
                        Image(systemName: "forward.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }).frame(width: 40)
                    
                    Spacer()
                    
                    Button(action: {
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

                    Button(action: {
                        if let audio = audio {
                            Favorites.save(audio) { favorites, error in
                                print(favorites as Any, error as Any)
                            }
                        }
                    }, label: {
                        Image(systemName: "heart")
                            .foregroundColor(Color("ShragaGold"))
                            .frame(width: 20, height: 20)
                    }).buttonStyle(iOS14BorderedProminentButtonStyle())
                
                Button(action: {
                    selectedSpeedIndex = (selectedSpeedIndex + 1) % speeds.count
                    player.avPlayer?.rate = speeds[selectedSpeedIndex]
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
