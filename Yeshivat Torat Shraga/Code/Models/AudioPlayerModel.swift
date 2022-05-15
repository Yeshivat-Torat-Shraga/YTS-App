//
//  AudioPlayerModel.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 5/11/22.
//

import Foundation
import AVKit
import MediaPlayer
class AudioPlayerModel: ObservableObject {
    @Published var player: Player
    @Published var audio: Audio?
    init(player: Player) {
        self.player = player
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if self.audio != nil {
                self.objectWillChange.send()
            }
        }

    }
    
    func set(audio: Audio) {
        if self.audio?.firestoreID == audio.firestoreID {
            print("The current audio is already playing, not re-setting.")
            return
        }
        self.audio = audio
        if let sourceURL = audio.sourceURL {
            let playerItem = AVPlayerItem(url: sourceURL)
            let player = AVPlayer(playerItem: playerItem)
            self.player.set(avPlayer: player)
            // Generate the share link
            self.audio?.shareURL()
        } else {
            print("Audio sourceURL is nil, couldn't set audio.")
        }
    }
    
    func pause() {
        self.player.pause()
    }
    
    func play(audio: Audio) {
        set(audio: audio)
        play()
    }
    
    func play() {
        self.player.play()
        configureControlCenterMedia()
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
        if let image = UIImage(named: "Logo") {
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
