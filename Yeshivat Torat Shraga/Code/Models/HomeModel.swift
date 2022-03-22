//
//  HomeModel.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 11/11/21.
//

import SwiftUI

class HomeModel: ObservableObject, ErrorShower {
    @Published var showError: Bool = false
    @Published var showAlert: Bool = false
    var errorToShow: Error?
    var retry: (() -> Void)?
    var rootModel: RootModel?
    var hideLoadingScreen: (() -> Void)?
    var showErrorOnRoot: ((Error, (() -> Void)?) -> Void)?
    var homePageAlertToShow: HomePageAlert? = nil
    @Published var recentlyUploadedContent: Content?
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
        
        let group = DispatchGroup()

        for _ in ["Rebbeim", "Sortables", "Slideshow images", "HomePageAlert"] {
            group.enter()
        }
        
        FirebaseConnection.loadRebbeim() { results, error in
            guard let rebbeim = results?.rebbeim as? [DetailedRabbi] else {
                self.showErrorOnRoot?(error ?? YTSError.unknownError, self.load)
                return
            }
            self.rebbeim = rebbeim
            group.leave()

        }
        
        FirebaseConnection.loadContent(options: (limit: 10, includeThumbnailURLs: true, includeDetailedAuthors: true, startAfterDocumentID: nil)) { results, error in
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
        
        FirebaseConnection.loadAlert() { result, error in
            guard let homeAlert = result else {
                group.leave()
                return
            }
            @AppStorage("lastViewedAlertID") var previousAlertID = ""
            print("previousAlertID: \(previousAlertID)")
            print("upcomingAlertID: \(homeAlert.id)")
            if previousAlertID != homeAlert.id {
                self.showAlert = true
                self.homePageAlertToShow = homeAlert
            }
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
