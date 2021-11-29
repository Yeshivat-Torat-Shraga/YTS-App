//
//  AudioPlayer.swift
//  Yeshivat Torat Shraga
//
//  Created by David Reese on 11/22/21.
//

import SwiftUI
import AVKit

struct AudioPlayer: View {
    @ObservedObject var player = Player()
    var audio: Audio?
    
    init() {}
    
    mutating func set(audio: Audio) {
            self.audio = audio
            
            let playerItem = AVPlayerItem(url: audio.sourceURL)
            let player = AVPlayer(playerItem: playerItem)
            //            self.avPlayer.prepareToPlay()
            //            avPlayer.volume = 1.0
            //        player.play()
            //            self.model = AudioPlayerModel(player: player)
        //            self.avPlayer = player
        self.player.set(avPlayer: player)
    }
    
    var body: some View {
        VStack {
            Image("Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .background(Color.white)
                .padding()
                .clipShape(RoundedRectangle(cornerRadius: 60))
                .shadow(radius: 3)
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
                        .shadow(radius: 2)
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
                        self.player.play()
                    }, label: {
                        Image(systemName: "play.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    })
                        .frame(width: 30)
                } else if RootModel.audioPlayer.player.timeControlStatus == .playing {
                    Button(action: {
                        self.player.pause()
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
                if #available(iOS 15.0, *) {
                    Button(action: {
                        
                    }, label: {
                        Image(systemName: "heart").foregroundColor(Color("ShragaGold"))
                            .frame(width: 20, height: 20)
                    }).buttonStyle(BorderedProminentButtonStyle())
                        
                } else {
                    Button(action: {
                        
                    }, label: {
                        Image(systemName: "heart").foregroundColor(Color("ShragaGold"))
                            .frame(width: 20, height: 20)
                    })
                }
                if #available(iOS 15.0, *) {
                    Button(action: {
                        
                    }, label: {
                        Image(systemName: "square.and.arrow.up").foregroundColor(Color("Gray"))
                            .frame(width: 20, height: 20)
                    }).buttonStyle(BorderedProminentButtonStyle())
                } else {
                    Button(action: {
                        
                    }, label: {
                        Image(systemName: "square.and.arrow.up").foregroundColor(Color(UIColor.lightGray))
                            .frame(width: 20, height: 20)
                    })
                }
                if #available(iOS 15.0, *) {
                    Button(action: {
                        
                    }, label: {
                        Image(systemName: "ellipsis").foregroundColor(Color(uiColor: .lightGray))
                            .frame(width: 20, height: 20)
                    }).buttonStyle(BorderedProminentButtonStyle())
                } else {
                    Button(action: {
                        
                    }, label: {
                        Image(systemName: "ellipsis").foregroundColor(Color(UIColor.lightGray))
                            .frame(width: 20, height: 20)
                    })
                }
                Spacer()
            }
            Spacer()
        }.background(LinearGradient(colors: [Color("ShragaBlue"), Color(white: 0.8)], startPoint: .bottomLeading, endPoint: .topTrailing) .ignoresSafeArea())
    }
}

struct AudioPlayer_Previews: PreviewProvider {
    static var ap = AudioPlayer()
    
    init() {
        AudioPlayer_Previews.ap.set(audio: Audio.sample)
    }
    
    static var previews: some View {
        Group {
            ap
        }
    }
}
