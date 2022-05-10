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
    private let thingsToLoad = ["Rebbeim", "Sortables", "Slideshow images", "HomePageAlert", "Tags"]
    private var appCheckRetryCount = 0
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

        for _ in thingsToLoad {
            group.enter()
        }
        
        FirebaseConnection.loadRebbeim() { results, error in
            if error?._code == -9 {
                self.handleAppCheckError(error: error!)
                return
            }
            guard let rebbeim = results?.rebbeim as? [DetailedRabbi] else {
                self.showErrorOnRoot?(error ?? YTSError.unknownError, self.load)
                return
            }
            self.rebbeim = rebbeim
            group.leave()

        }
        
        FirebaseConnection.loadContent(options: (limit: 10, includeThumbnailURLs: true, includeDetailedAuthors: true, startAfterDocumentID: nil)) { results, error in
            guard let content = results?.content else {
                if error?._code == -9 {
                    self.handleAppCheckError(error: error!)
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
            if error?._code == -9 {
                self.handleAppCheckError(error: error!)
                return
            }
            self.slideshowImages = results?.images.sorted(by: { lhs, rhs in
                lhs.uploaded > rhs.uploaded
            })

            group.leave()
        }
        
        FirebaseConnection.loadAlert() { result, error in
            if error?._code == -9 {
                self.handleAppCheckError(error: error!)
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
            if error?._code == -9 {
                self.handleAppCheckError(error: error!)
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
        }
    }
    
    private func handleAppCheckError(error: Error) {
        if self.appCheckRetryCount > self.thingsToLoad.count * 5 ||
            self.appCheckRetryCount % (self.thingsToLoad.count + 1) == 0 {
            self.showErrorOnRoot?(error , self.load)
            return
        }
        self.appCheckRetryCount += 1
        print("Silently handling AppCheck Failure")
        self.load()
        return
    }
}
