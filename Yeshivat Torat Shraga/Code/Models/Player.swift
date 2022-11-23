//
//  Player.swift
//  Yeshivat Torat Shraga
//
//  Created by David Reese on 11/22/21.
//

import Foundation
import AVKit
import Combine
import SwiftUI

let timeScale = CMTimeScale(1000)
let time = CMTime(seconds: 0.5, preferredTimescale: timeScale)

/// <#Description#>
final class Player: NSObject, ObservableObject {
    /// The audio that the spot will be saved for
    private var content: Audio?
    
    /// Display time that will be bound to the scrub slider.
    @Published var displayTime: TimeInterval = 0
    
    /// The observed time, which may not be needed by the UI.
    @Published var observedTime: TimeInterval = 0
    
    @Published var itemDuration: TimeInterval = 0
    fileprivate var itemDurationKVOPublisher: AnyCancellable!
    
    /// Publish timeControlStatus
    @Published var timeControlStatus: AVPlayer.TimeControlStatus = .paused
    fileprivate var timeControlStatusKVOPublisher: AnyCancellable!
    
    /// The AVPlayer
    @Published var avPlayer: AVPlayer?
    
    /// Time observer.
    fileprivate var periodicTimeObserver: Any?
    
    var scrubState: PlayerScrubState = .reset {
        didSet {
            switch scrubState {
            case .reset:
                return
            case .scrubStarted:
                return
            case .scrubEnded(let seekTime):
                avPlayer?.seek(to: CMTime(seconds: seekTime, preferredTimescale: 1000))
            }
        }
    }
    
    override init() {
        super.init()
    }
    
    init(avPlayer: AVPlayer) {
        self.avPlayer = avPlayer
        super.init()
        
        self.addPeriodicTimeObserver()
        self.addTimeControlStatusObserver()
        self.addItemDurationPublisher()
    }
    
    deinit {
        removePeriodicTimeObserver()
        timeControlStatusKVOPublisher?.cancel()
        itemDurationKVOPublisher?.cancel()
    }
    
    func set(avPlayer: AVPlayer, audio: Audio) {
        self.content = audio
        
        removePeriodicTimeObserver()
        timeControlStatusKVOPublisher?.cancel()
        itemDurationKVOPublisher?.cancel()
        
        self.avPlayer = avPlayer
        self.addPeriodicTimeObserver()
        self.addTimeControlStatusObserver()
        self.addItemDurationPublisher()
        
        
//        DispatchQueue.global(qos: .background).async {
            if let spot = ContentSpots.getSpot(content: audio) {
                print("Setting spot to \(spot) for content \(audio.title) (ID=\(audio.firestoreID)")
                self.scrub(to: CMTimeMakeWithSeconds(spot, preferredTimescale: timeScale))
            }
            
//        }
        
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(playerDidFinishPlaying),
                         name: .AVPlayerItemDidPlayToEndTime,
                         object: avPlayer.currentItem
            )
    }
    
    func play() {
        self.avPlayer?.play()
    }
    
    func pause() {
        self.avPlayer?.pause()
    }
    
    func scrub(to time: CMTime) {
        if let _ = self.avPlayer {
            self.avPlayer!.seek(to: time)
        }
    }
    
    func scrub(seconds: TimeInterval) {
        if let _ = self.avPlayer {
            self.avPlayer!.seek(to: self.avPlayer!.currentTime().timeWithOffset(offset: seconds))
        }
    }
    
    func setRate(_ rate: Float) {
        self.avPlayer?.rate = rate
    }
    
    @objc func playerDidFinishPlaying() {
        if let content = content {
            print("Deleting spots for content \(content.title) (ID=\(content.firestoreID))")
            ContentSpots.delete(content: content)
        } else {
            print("Cannot delete spots, content is nil")
        }
    }
    
    func saveSpot(_ spot: TimeInterval) {
        if let content = self.content {
            ContentSpots.save(content: content, spot: spot)
        }
    }
    
    fileprivate func addPeriodicTimeObserver() {
        self.periodicTimeObserver = avPlayer?.addPeriodicTimeObserver(forInterval: time, queue: .main) { [weak self] (time) in
            guard let self = self else { return }
            
            // Always update observed time.
            withAnimation {
                self.observedTime = time.seconds
                
                self.saveSpot(time.seconds)
            }
            
            switch self.scrubState {
            case .reset:
                withAnimation {
                    self.displayTime = time.seconds
                }
            case .scrubStarted:
                // When scrubbing, the displayTime is bound to the Slider view, so
                // do not update it here.
                break
            case .scrubEnded(let seekTime):
                withAnimation {
                    self.scrubState = .reset
                    self.displayTime = seekTime
                }
            }
        }
    }
    
    fileprivate func removePeriodicTimeObserver() {
        guard let periodicTimeObserver = self.periodicTimeObserver else {
            return
        }
        avPlayer?.removeTimeObserver(periodicTimeObserver)
        self.periodicTimeObserver = nil
    }
    
    fileprivate func addTimeControlStatusObserver() {
        timeControlStatusKVOPublisher = avPlayer?
            .publisher(for: \.timeControlStatus)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] (newStatus) in
                guard let self = self else { return }
                withAnimation {
                    self.timeControlStatus = newStatus
                }
            })
    }
    
    fileprivate func addItemDurationPublisher() {
        itemDurationKVOPublisher = avPlayer?
            .publisher(for: \.currentItem?.duration)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] (newStatus) in
                guard let newStatus = newStatus,
                      let self = self else { return }
                withAnimation {
                    self.itemDuration = newStatus.seconds
                }
            })
    }
    
    enum PlayerScrubState {
        case reset
        case scrubStarted
        case scrubEnded(TimeInterval)
    }
}

extension CMTime {
    func timeWithOffset(offset: TimeInterval) -> CMTime {
        
        let seconds = CMTimeGetSeconds(self)
        let secondsWithOffset = seconds + offset
        
        return CMTimeMakeWithSeconds(secondsWithOffset, preferredTimescale: timescale)
        
    }
}
