//
//  DisplayRabbiModel.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 11/16/21.
//

import Foundation
import SwiftUI

class DisplayRabbiModel: ObservableObject, ErrorShower, SequentialLoader {
    @Published var rabbi: DetailedRabbi
    @Published var content: AVContent?
    @Published var sortables: [SortableYTSContent]?
    @Published var favorites: [SortableYTSContent]?
    
    @Published internal var loadingContent: Bool = false
    internal var reloadingContent: Bool = false
    @Published internal var retreivedAllContent: Bool = false
    var lastLoadedDocumentID: FirestoreID?
    internal var calledInitialLoad: Bool = false
    
    var showError: Bool = false
    internal var errorToShow: Error?
    internal var retry: (() -> Void)?
    
    init(rabbi: DetailedRabbi) {
        self.rabbi = rabbi
    }
    
    func load(next increment: Int = 10) {
        
        self.loadingContent = true
        
        let group = DispatchGroup()
        
        group.enter()
        FirebaseConnection.loadContent(options: (limit: increment, includeThumbnailURLs: true, includeDetailedAuthors: false, startAfterDocumentID: lastLoadedDocumentID), matching: rabbi) { results, error in
            guard let results = results else {
                self.showError(error: error ?? YTSError.unknownError, retry: {
                    self.load(next: increment)
                })
                print("Error getting content")
                group.leave()
                return
            }
            
            withAnimation {
                if self.content == nil {
                    self.content = results.content
                } else {
                    if self.content!.videos == nil {
                        self.content!.videos = results.content.videos
                    } else {
                        self.content!.videos.append(contentsOf: results.content.videos)
                    }
                    
                    if self.content!.audios == nil {
                        self.content!.audios = results.content.audios
                    } else {
                        self.content!.audios.append(contentsOf: results.content.audios)
                    }
                }
                
                
                self.lastLoadedDocumentID = results.metadata.newLastLoadedDocumentID
                self.retreivedAllContent = results.metadata.finalCall
                
                var sortables: Set<SortableYTSContent> = []
                for audio in self.content!.audios {
                    sortables.insert(audio.sortable)
                }
                for video in self.content!.videos {
                    sortables.insert(video.sortable)
                }
                                
                self.sortables = sortables.sorted(by: { lhs, rhs in
                    return lhs.date! > rhs.date!
                })
            }
            group.leave()
            
            DispatchQueue.global(qos: .background).async {
                for audio in self.content!.audios {
                    if !(audio.author is DetailedRabbi) {
                        audio.author = self.rabbi
                    }
                }
                for video in self.content!.videos {
                    if !(video.author is DetailedRabbi) {
                        video.author = self.rabbi
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            withAnimation {
                self.loadingContent = false
                self.reloadingContent = false
            }
        }
    }
    
    func initialLoad() {
        // Load Favorites (This will be called onAppear
        var favorites: [SortableYTSContent] = []
        if let allFavorites = Favorites.shared.favorites,
           let audios = allFavorites.audios,
           let videos = allFavorites.videos {
            for audio in audios {
                if audio.author.firestoreID == self.rabbi.firestoreID {
                    favorites.append(audio.sortable)
                }
            }
            for video in videos {
                if video.author.firestoreID == self.rabbi.firestoreID {
                    favorites.append(video.sortable)
                }
            }
        }
        withAnimation {
            self.favorites = favorites
        }
        
        
        if !calledInitialLoad {
            self.calledInitialLoad = true
            load()
        }
    }
    
    func reload() {
        if !reloadingContent {
            reloadingContent = true
            self.lastLoadedDocumentID = nil
            self.content = nil
            //            self.favoriteContent = nil
            self.calledInitialLoad = false
            initialLoad()
            //            loadFavorites()
        }
    }
}
