//
//  AudioPlayerModel.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 5/11/22.
//

import Foundation
import AVKit
import MediaPlayer
import SwiftUI

class AudioPlayerModel: ObservableObject {
    private var player: Player
    @Published var audio: Audio?
    
    lazy var miniPlayerShowing: Binding<Bool> = Binding {
        self.audio != nil
    } set: { val in
        if val == true {
            
        } else {
            self.audio = nil
        }
    }
    
    init(player: Player) {
        self.player = player
    }
    
    func set(audio: Audio) {
        if self.audio?.firestoreID == audio.firestoreID {
            return
        }
        self.audio = audio
        if let sourceURL = audio.sourceURL {
            let playerItem = AVPlayerItem(url: sourceURL)
            let player = AVPlayer(playerItem: playerItem)
            self.player.set(avPlayer: player, audio: audio)
            // Generate the share link
            self.audio?.shareURL()
            // Increase the view count
            FirebaseConnection.increaseViewCountForContentByID(audio.firestoreID)
        } else {
            print("Audio sourceURL is nil, couldn't set audio.")
        }
    }
    
    func pause() {
        withAnimation {
            self.player.pause()
        }
    }
    
    func play(audio: Audio) {
        withAnimation {
            set(audio: audio)
            play()
        }
    }
    
    func play() {
        withAnimation {
            self.player.play()
            configureControlCenterMedia()
        }
    }
    
    private func configureControlCenterMedia() {
        UIApplication.shared.beginReceivingRemoteControlEvents()
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.nextTrackCommand.isEnabled = false
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
            } else {
                return .commandFailed
            }
        }
        
        var nowPlayingInfo: [String: Any] = [:]
        nowPlayingInfo[MPMediaItemPropertyTitle] = audio?.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = audio?.author.name
        
        let lightTrait = UITraitCollection(userInterfaceStyle: .light)
        if let image = UIImage(named: "Logo", in: nil, compatibleWith: lightTrait) {
            nowPlayingInfo[MPMediaItemPropertyArtwork] =
            MPMediaItemArtwork(boundsSize: image.size) { size in
                return image
            }
        }
        
        commandCenter.changePlaybackPositionCommand.isEnabled = true
        
        commandCenter.changePlaybackPositionCommand.addTarget { event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            let time = CMTime(seconds: event.positionTime, preferredTimescale: 1_000_000)
            self.player.avPlayer?.seek(to: time)
            return .success
        }
        
        Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { _ in
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.player.displayTime
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = self.player.itemDuration
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = self.player.avPlayer?.rate
            nowPlayingInfo[MPNowPlayingInfoPropertyDefaultPlaybackRate] = 1.0
            
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        }
    }
    
}
