//
//  AudioContentModel.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 11/22/21.
//

import Foundation

class AudioCardModel: ObservableObject {
    @Published var audio: Audio
    
    init(audio: Audio) {
        self.audio = audio
    }
}
