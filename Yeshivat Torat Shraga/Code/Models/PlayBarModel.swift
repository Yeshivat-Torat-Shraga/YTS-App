//
//  PlayBarModel.swift
//  Yeshivat Torat Shraga
//
//  Created by David Reese on 11/27/21.
//

import Foundation

class PlayBarModel: ObservableObject {
//    @Published var audioCurrentlyPlaying: Audio?
//
//    init(audioCurrentlyPlaying: Audio?) {
//        self.audioCurrentlyPlaying = audioCurrentlyPlaying
//
//    }
    
    init() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.objectWillChange.send()
        }
    }
}
