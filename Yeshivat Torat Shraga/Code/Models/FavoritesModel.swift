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
    @Published var favorites = Favorites.shared.favorites
    init() {
    }
    
    func load() {
        var sortables: [SortableYTSContent] = []
        guard let favorites = Favorites.shared.favorites else {
            print("An error occured whilst loading favorites")
            return
        }
            if let videos = favorites.videos {
                for video in videos {
                    sortables.append(video.sortable)
                }
            }
            if let audios = favorites.audios {
                for audio in audios {
                    sortables.append(audio.sortable)
                }
            }
            if let rebbeim = favorites.people {
                self.rebbeim = rebbeim
            }
        self.sortables = sortables
    }
}
