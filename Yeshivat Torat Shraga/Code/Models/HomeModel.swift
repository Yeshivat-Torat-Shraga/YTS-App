//
//  HomeModel.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 11/11/21.
//

import Foundation
import SwiftUI

class HomeModel: ObservableObject, ErrorShower {
    @Published var showError: Bool = false
    var errorToShow: Error?
    var retry: (() -> Void)?
    var rootModel: RootModel?
    var hideLoadingScreen: (() -> Void)?
    @Published var recentlyUploadedContent: Content?
    @Published var sortables: [SortableYTSContent]?
    @Published var rebbeim: [DetailedRabbi]?
    @Published var slideshowImages: [SlideshowImage]?
    
    init() {
        load()
    }
    
    init(hideLoadingScreen: @escaping (() -> Void)) {
        self.hideLoadingScreen = hideLoadingScreen
        load()
    }
    
    func load() {
//        self.rebbeim = DetailedRabbi.samples
//        self.sortables = [SortableYTSContent(audio: .sample),
//                          SortableYTSContent(video: .sample),
//                          SortableYTSContent(audio: .sample),
//                          SortableYTSContent(video: .sample),
//                          SortableYTSContent(video: .sample),
//                          SortableYTSContent(audio: .sample)]
        
        let savedFavorites:[FirestoreID] = Favorites.getfavoriteIDs()
        
        let group = DispatchGroup()

        for _ in ["Rebbeim", "Sortables", "Slideshow images"] {
            group.enter()
        }
        
        FirebaseConnection.loadRebbeim() { results, error in
            guard let rebbeim = results?.rebbeim as? [DetailedRabbi] else {
                self.showError(error: error ?? YTSError.unknownError, retry: self.load)
                return
            }
            for rebbi in rebbeim {
                if savedFavorites.contains(rebbi.firestoreID) {
                    rebbi.isFavorite = true
                }
            }
            self.rebbeim = rebbeim
            group.leave()

        }
        
        FirebaseConnection.loadContent(options: (limit: 10, includeThumbnailURLs: true, includeDetailedAuthors: true, startFromDocumentID: nil)) { results, error in
            guard let content = results?.content else {
                self.showError(error: error ?? YTSError.unknownError, retry: self.load)
                return
            }

            self.recentlyUploadedContent = content

            var sortables: [SortableYTSContent] = []

            for video in content.videos {
                sortables.append(video.sortable)
            }

            for audio in content.audios {
                sortables.append(audio.sortable)
            }

            self.sortables = sortables.sorted(by: { lhs, rhs in
                return lhs.date! > rhs.date!
            })

            group.leave()
        }
        
        FirebaseConnection.loadSlideshowImages(limit: 25) { results, error in
            self.slideshowImages = results?.images.sorted(by: { lhs, rhs in
                lhs.uploaded > rhs.uploaded
            })

            group.leave()
        }
        
        group.notify(queue: .main) {
            self.hideLoadingScreen?()
        }
    }
}
