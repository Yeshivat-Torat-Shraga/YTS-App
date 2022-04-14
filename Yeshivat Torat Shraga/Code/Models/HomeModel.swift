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
    private var shouldRetryOnAppCheckFailure = true
    @Published var recentlyUploadedContent: AVContent?
    @Published var sortables: [SortableYTSContent]?
    @Published var rebbeim: [DetailedRabbi]?
    @Published var slideshowImages: [SlideshowImage]?
    @Published var tags: [Tag]?
    
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

        for _ in ["Rebbeim", "Sortables", "Slideshow images", "HomePageAlert", "Tags"] {
            group.enter()
        }
        
        FirebaseConnection.loadRebbeim() { results, error in
            guard let rebbeim = results?.rebbeim as? [DetailedRabbi] else {
                if error?._code == 9 {
                    self.retryOnceOnAppCheckFailure(error: error!)
                    return
                }
                self.showErrorOnRoot?(error ?? YTSError.unknownError, self.load)
                return
            }
            self.rebbeim = rebbeim
            group.leave()

        }
        
        FirebaseConnection.loadContent(options: (limit: 10, includeThumbnailURLs: true, includeDetailedAuthors: true, startAfterDocumentID: nil)) { results, error in
            guard let content = results?.content else {
                if error?._code == 9 {
                    self.retryOnceOnAppCheckFailure(error: error!)
                    return
                }
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
            if error?._code == 9 {
                self.retryOnceOnAppCheckFailure(error: error!)
                return
            }

            self.slideshowImages = results?.images.sorted(by: { lhs, rhs in
                lhs.uploaded > rhs.uploaded
            })

            group.leave()
        }
        
        FirebaseConnection.loadAlert() { result, error in
            if error?._code == 9 {
                self.retryOnceOnAppCheckFailure(error: error!)
                return
            }

            guard let homeAlert = result else {
                group.leave()
                return
            }
            @AppStorage("lastViewedAlertID") var previousAlertID = ""
            if previousAlertID != homeAlert.id {
                self.showAlert = true
                self.homePageAlertToShow = homeAlert
            }
            group.leave()
        }
        
        FirebaseConnection.loadCategories() { tags, error in
            if error?._code == 9 {
                self.retryOnceOnAppCheckFailure(error: error!)
                return
            }

            guard let tags = tags else {
                group.leave()
                self.showErrorOnRoot?(error ?? YTSError.unknownError, self.load)
                return
            }
            self.tags = tags
            group.leave()
        }
        
        group.notify(queue: .main) {
            self.hideLoadingScreen?()
//            if let errorToShow = self.errorToShow {
//                self.showErrorOnRoot?(errorToShow, self.retry)
//            }
        }
    }
    
    private func retryOnceOnAppCheckFailure(error: Error) {
        guard self.shouldRetryOnAppCheckFailure == true else {
            self.showErrorOnRoot?(error , self.load)
            return
        }
            self.shouldRetryOnAppCheckFailure = false
            print("Silently handling AppCheck Failure")
            self.load()
            return
    }
}
