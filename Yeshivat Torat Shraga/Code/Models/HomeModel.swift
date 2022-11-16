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
    internal var errorToShow: Error?
    internal var retry: (() -> Void)?
    var showErrorOnRoot: ((Error, (() -> Void)?) -> Void)?
    
    var hideLoadingScreen: (() -> Void)?
    var homePageAlertToShow: HomePageAlert? = nil
    private var shouldRetryOnAppCheckFailure = true
    private var appCheckRetryCount = 0
    @Published internal var isLoading = false
    
    @Published var recentlyUploadedContent: AVContent?
    @Published var sortables: [SortableYTSContent]?
    @Published var rebbeim: [DetailedRabbi]?
    @Published var slideshowImages: [SlideshowImage]?
    @Published var tags: [Tag]?
    
    let thingsToLoad = 4
    
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
        isLoading = true
        
        let group = DispatchGroup()
        
        for _ in 1...thingsToLoad {
            group.enter()
        }
        
        FirebaseConnection.loadRebbeim(options: (limit: -1, includePictureURLs: true, startAfterDocumentID: nil, includeServiceProfiles: false)) { results, error in
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
                return
            }
            @AppStorage("lastViewedAlertID") var previousAlertID = ""
            if previousAlertID != homeAlert.id {
                self.showAlert = true
                self.homePageAlertToShow = homeAlert
            }
        }
        
        FirebaseConnection.loadCategories() { tags, error in
            if error?._code == -9 {
                self.handleAppCheckError(error: error!)
                return
            }
            
            guard let tags = tags else {
                self.showErrorOnRoot?(error ?? YTSError.unknownError, self.load)
                return
            }
            
            self.tags = tags
            group.leave()
        }
        
        group.notify(queue: .main) {
            withAnimation {
                self.isLoading = false
                self.hideLoadingScreen?()
                self.objectWillChange.send()
            }
        }
    }
    
    func reload() {
        withAnimation {
            self.isLoading = true
            load()
        }
    }
    
    private func handleAppCheckError(error: Error) {
        if self.appCheckRetryCount > self.thingsToLoad * 5 ||
            self.appCheckRetryCount % (self.thingsToLoad + 1) == 0 {
            self.showErrorOnRoot?(error , self.load)
            return
        }
        self.appCheckRetryCount += 1
        print("Silently handling AppCheck Failure")
        self.load()
        return
    }
}
