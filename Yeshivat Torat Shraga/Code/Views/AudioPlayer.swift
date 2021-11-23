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
            
            Button {
                self.player.play()
            } label: {
                Image(systemName: "play.fill")
            }
            Spacer()
        }.background(LinearGradient(colors: [Color("ShragaBlue"), Color(white: 0.7)], startPoint: .bottomLeading, endPoint: .topTrailing) .ignoresSafeArea())
    }
}

struct AudioPlayer_Previews: PreviewProvider {
    static var ap = AudioPlayer()
    
    init() {
        AudioPlayer_Previews.ap.set(audio: Audio.sample)
    }
    
    static var previews: some View {
        ap
    }
}
