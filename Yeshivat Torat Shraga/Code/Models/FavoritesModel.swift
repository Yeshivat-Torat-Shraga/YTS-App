//
//  FavoritesModel.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 28/01/2022.
//

import SwiftUI

class FavoritesModel: ObservableObject {
    @Published var videos:  [Video]?
    @Published var audios:  [Audio]?
    @Published var rebbeim: [DetailedRabbi]?
    init() {
        load()
    }
    
    func load() {
        Favorites.loadFavorites() { dataTuple, err in
            guard let data = dataTuple else {
                print("The dataTuple returned nil from the favorites loader")
                return
            }
//            guard let videos = data.videos,
//                  let audios = data.audios,
//                  let rebbeim = data.people
//            else {
//                print("One of Videos, Audios, or Rebbeim was returned as nil from the favorites loader.")
//                return
//            }
            
            withAnimation {
                if data.videos?.count ?? 0 > 0 {
                    self.videos = data.videos
                }
                if data.audios?.count ?? 0 > 0 {
                    self.audios = data.audios
                }
                if data.people?.count ?? 0 > 0 {
                    self.rebbeim = data.people
                }
            }
            
        }
    }
}
