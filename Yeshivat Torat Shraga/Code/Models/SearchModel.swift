//
//  SearchModel.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 28/12/2021.
//

import SwiftUI

class SearchModel: ObservableObject, ErrorShower {
    @Published var content: AVContent?
    @Published var rebbeim: [Rabbi]?
    @Published var sortables: [SortableYTSContent]?
    
    var contentIsEmpty: Bool {
        return content?.videos.isEmpty ?? true && content?.audios.isEmpty ?? true
    }
    
    @Published internal var loadingContent: Bool = false
    @Published internal var loadingRebbeim: Bool = false
    @Published internal var retreivedAllContent: Bool = false
    @Published internal var retreivedAllRebbeim: Bool = false
    internal var lastLoadedContentID: FirestoreID?
    internal var lastLoadedRabbiID: FirestoreID?
    internal var calledInitialLoad: Bool = false
    var searchQuery: String = ""
    
    @Published var showError: Bool = false
    var errorToShow: Error?
    var retry: (() -> Void)?
    
    func newSearch(_ query: String) {
        reset()
        calledInitialLoad = true
        
        search(query)
    }
    
    func searchForMoreContent() {
        search(self.searchQuery, rebbeimLimit: 0)
    }
    
    func searchForMoreRebbeim() {
        search(self.searchQuery, contentLimit: 0)
    }
    
    private func search(_ query: String, contentLimit: Int = 5, rebbeimLimit: Int = 5) {
        if (query == "") {
            print("Query is empty, not searching.")
            return
        }
        self.searchQuery = query
        
        loadingContent = true
        loadingRebbeim = true
        FirebaseConnection.search(query: query,
                                  contentOptions: (limit: contentLimit,
                                                   includeThumbnailURLs: true,
                                                   includeDetailedAuthors: false,
                                                   startAfterDocumentID: lastLoadedContentID),
                                  rebbeimOptions: (limit: rebbeimLimit,
                                                   includePictureURLs: true,
                                                   startAfterDocumentID: lastLoadedRabbiID)) { results, error in
            guard let content = results?.content else {
                self.loadingContent = false
                self.loadingRebbeim = false
                self.showError(error: error ?? YTSError.unknownError, retry: {})
                return
            }
            
            guard let rebbeim = results?.rebbeim else {
                self.loadingContent = false
                self.loadingRebbeim = false
                self.showError(error: error ?? YTSError.unknownError, retry: {})
                return
            }
            
            withAnimation {
                if self.content == nil {
                    self.content = content
                } else {
                    self.content!.videos.append(contentsOf: content.videos)
                    self.content!.audios.append(contentsOf: content.audios)
                }
                
                if self.rebbeim == nil {
                    self.rebbeim = rebbeim
                } else {
                    self.rebbeim!.append(contentsOf: rebbeim)
                }
                
                if self.sortables == nil {
//                  MARK: Possible issue when the return is nil, not sure how this will be handled
                    self.sortables = []
                    for video in content.videos {
                        self.sortables!.append(video.sortable)
                    }
                    for audio in content.audios {
                        self.sortables!.append(audio.sortable)
                    }
                } else {
                    for video in content.videos {
                        self.sortables!.append(video.sortable)
                    }
                    for audio in content.audios {
                        self.sortables!.append(audio.sortable)
                    }
                }
                
                self.sortables?.sort(by: { lhs, rhs in
                    return lhs.date! > rhs.date!
                })
            }
            
            if let metadata = results?.metadata {
                if let newLastLoadedDocumentID = metadata.content?.newLastLoadedDocumentID {
                    self.lastLoadedContentID = newLastLoadedDocumentID
                }
                
                if let newLastLoadedDocumentID = metadata.rebbeim?.newLastLoadedDocumentID {
                    self.lastLoadedRabbiID = newLastLoadedDocumentID
                }
                
                self.retreivedAllContent = metadata.content?.finalCall ?? self.retreivedAllContent
                self.retreivedAllRebbeim = metadata.rebbeim?.finalCall ?? self.retreivedAllRebbeim
            }
            
            withAnimation {
                self.loadingContent = false
                self.loadingRebbeim = false
            }
        }
    }
    
    private func reset() {
        self.lastLoadedContentID = nil
        self.lastLoadedRabbiID = nil
        withAnimation {
            self.content = nil
            self.rebbeim = nil
            self.sortables = nil
        }
    }
}
