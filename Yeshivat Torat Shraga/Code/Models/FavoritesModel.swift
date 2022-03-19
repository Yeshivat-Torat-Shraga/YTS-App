//
//  FavoritesModel.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 28/01/2022.
//

import SwiftUI

class FavoritesModel: ObservableObject {
    @Published var favorites = Favorites.shared.favorites
    @Published var sortables: [DetailedRabbi: [SortableYTSContent]]?
    init() {
    }
    
    func load() {
        var sortables: [DetailedRabbi: [SortableYTSContent]] = [:]
        guard let favorites = Favorites.shared.favorites else {
            print("An error occured whilst loading favorites")
            return
        }
            if let videos = favorites.videos {
                for video in videos {
                    if let author = video.author as? DetailedRabbi {
                        if sortables[author] == nil {
                            sortables[author] = []
                        }
                        sortables[author]!.append(video.sortable)
                    }
                }
            }
            if let audios = favorites.audios {
                for audio in audios {
                    if let author = audio.author as? DetailedRabbi {
                        if sortables[author] == nil {
                            sortables[author] = []
                        }
                        sortables[author]!.append(audio.sortable)
                    }
                }
            }
        self.sortables = sortables
    }
}
