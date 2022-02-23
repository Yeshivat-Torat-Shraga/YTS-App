//
//  HomeModel.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 11/11/21.
//

import SwiftUI

class HomeModel: ObservableObject, ErrorShower {
    @Published var showError: Bool = false
    var errorToShow: Error?
    var retry: (() -> Void)?
    var rootModel: RootModel?
    var hideLoadingScreen: (() -> Void)?
    var showErrorOnRoot: ((Error, (() -> Void)?) -> Void)?
    @Published var bannerAlert: HomePageAlert? = HomePageAlert(title: "Rabbi Olshin is flying to USA!", body: "He will be on the East coast from August 11 - August 31")
    @Published var recentlyUploadedContent: AVContent?
    @Published var sortables: [SortableYTSContent]?
    @Published var rebbeim: [DetailedRabbi]?
    @Published var slideshowImages: [SlideshowImage]?
    
    init() {
        load()
    }
    
    init(hideLoadingScreen: @escaping (() -> Void),
         showErrorOnRoot:   @escaping ((Error, (() -> Void)?) -> Void)
    ) {
        self.hideLoadingScreen = hideLoadingScreen
        self.showErrorOnRoot = showErrorOnRoot
        load()
    }
    
    func load() {

        let savedFavorites:[FirestoreID] = Favorites.shared.getfavoriteIDs()
        
        let group = DispatchGroup()

        for _ in ["Rebbeim", "Sortables", "Slideshow images"] {
            group.enter()
        }
        
        FirebaseConnection.loadRebbeim() { results, error in
            guard let rebbeim = results?.rebbeim as? [DetailedRabbi] else {
                self.showErrorOnRoot?(error ?? YTSError.unknownError, self.load)
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
                self.showErrorOnRoot?(error ?? YTSError.unknownError, self.load)
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
//            if let errorToShow = self.errorToShow {
//                self.showErrorOnRoot?(errorToShow, self.retry)
//            }
        }
    }
}
