//
//  FavoritesModel.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 28/01/2022.
//

import SwiftUI

class FavoritesModel: ObservableObject {
    @Published var sortables: [SortableYTSContent]?
    @Published var rebbeim: [DetailedRabbi]?
    init() {
        // Loading happens onAppear
        // load()
    }
    
    func load() {
        var sortables: [SortableYTSContent] = []
        Favorites.getFavorites() { dataTuple, err in
            guard let data = dataTuple else {
                print("The dataTuple returned nil from the favorites loader")
                return
            }

            if let videos = data.videos {
                for video in videos {
                    sortables.append(video.sortable)
                }
            }
            if let audios = data.audios {
                for audio in audios {
                    sortables.append(audio.sortable)
                }
            }
            if let rebbeim = data.people {
                self.rebbeim = rebbeim
            }
        }
    }
}
