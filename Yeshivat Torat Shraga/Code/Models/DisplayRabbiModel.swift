//
//  DisplayRabbiModel.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 11/16/21.
//

import Foundation
import SwiftUI

class DisplayRabbiModel: ObservableObject, ErrorShower {
    var showError: Bool = false
    internal var errorToShow: Error?
    internal var retry: (() -> Void)?
    
    @Published var rabbi: DetailedRabbi
    @Published var videos: [Video]?
    @Published var audios: [Audio]?

    init(rabbi: DetailedRabbi) {
        self.rabbi = rabbi
    }
    
    func load() {
        FirebaseConnection.loadContent(attributionRabbi: self.rabbi, includeThumbnailURLs: true) { results, error in
            guard let results = results else {
                self.showError(error: error ?? YTSError.unknownError, retry: self.load)
                fatalError(error!.localizedDescription)
            }
            print(results)
            withAnimation {
                self.audios = results.content.audios
                self.videos = results.content.videos
            }
            
            DispatchQueue.global(qos: .background).async {
                for audio in self.audios! {
                    if !(audio.author is DetailedRabbi) {
                        audio.author = self.rabbi
                    }
                }
                for video in self.videos! {
                    if !(video.author is DetailedRabbi) {
                        video.author = self.rabbi
                    }
                }
            }
        }
    }
}
