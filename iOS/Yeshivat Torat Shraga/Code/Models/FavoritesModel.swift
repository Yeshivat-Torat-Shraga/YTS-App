//
//  FavoritesModel.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 28/01/2022.
//

import SwiftUI

class FavoritesModel: ObservableObject {
    @Published var sortables: [DetailedRabbi: [SortableYTSContent]]?
    
    init(){
    }
    
    func reload(favorites: Favorites) {
        load(favorites: favorites)
    }
    
    func load(favorites: Favorites) {
        var sortables: [DetailedRabbi: [SortableYTSContent]] = [:]
        
        if let contents = favorites.favorites?.content {
            for content in contents {
                if let video = content.video {
                    if let author = video.author as? DetailedRabbi {
                        if sortables[author] == nil {
                            sortables[author] = []
                        }
                        sortables[author]!.append(video.sortable)
                    }
                } else if let audio = content.audio {
                    if let author = audio.author as? DetailedRabbi {
                        if sortables[author] == nil {
                            sortables[author] = []
                        }
                        sortables[author]!.append(audio.sortable)
                    }
                    
                }
            }
        }
        
        if self.sortables != nil {
            withAnimation {
                self.sortables = sortables
            }
        } else {
            self.sortables = sortables
        }
    }
}
