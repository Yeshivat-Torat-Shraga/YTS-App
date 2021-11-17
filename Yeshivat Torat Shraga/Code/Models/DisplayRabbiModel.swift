//
//  DisplayRabbiModel.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 11/16/21.
//

import Foundation

class DisplayRabbiModel: ObservableObject {
    @Published var rabbi: Rabbi
    @Published var videos: [Video]?
    @Published var audios: [Audio]?
    init(rabbi: Rabbi) {
        self.rabbi = rabbi
        FirebaseConnection.loadContent(includeThumbnailURLs: true) { results, error in
            guard let results = results else {
                fatalError("There was an issue fetching results from FirebaseConnection.loadContent.")
            }
            self.audios = results.content.audios
            self.videos = results.content.videos
        }
    }
}
