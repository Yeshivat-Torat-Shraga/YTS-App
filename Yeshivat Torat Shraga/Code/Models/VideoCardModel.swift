//
//  VideoCardModel.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 08/12/2021.
//

import Foundation

class VideoCardModel: ObservableObject {
    @Published var video: Video
    
    init(video: Video) {
        self.video = video
    }
}
