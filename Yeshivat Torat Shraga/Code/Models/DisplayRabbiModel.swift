//
//  DisplayRabbiModel.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 11/16/21.
//

import Foundation

class DisplayRabbiModel: ObservableObject, ErrorShower {
    var showError: Bool = false
    internal var errorToShow: Error?
    internal var retry: (() -> Void)?
    
    @Published var rabbi: Rabbi
    @Published var videos: [Video]?
    @Published var audios: [Audio]?

    init(rabbi: Rabbi) {
        self.rabbi = rabbi
        
        load()
    }
    
    func load() {
        FirebaseConnection.loadContent(includeThumbnailURLs: true) { results, error in
            guard let results = results else {
                self.showError(error: error ?? YTSError.unknownError, retry: self.load)
                fatalError(error!.localizedDescription)
                return
            }
            print(results)
            self.audios = results.content.audios
            self.videos = results.content.videos
        }
    }
}
