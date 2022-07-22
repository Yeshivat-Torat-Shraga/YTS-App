//
//  PendingShiurimModel.swift
//  Yeshivat Torat Shraga
//
//  Created by David Reese on 7/22/22.
//

import Foundation
import SwiftUI

class PendingShiurimModel: ErrorShower, SequentialLoader {
    @Published var sortables: [SortableYTSContent]?
    
    @Published internal var loadingContent: Bool = false
    internal var reloadingContent: Bool = false
    @Published internal var retreivedAllContent: Bool = false
    var lastLoadedDocumentID: FirestoreID?
    internal var calledInitialLoad: Bool = false
    
    @Published var showError: Bool = false
    internal var errorToShow: Error?
    internal var retry: (() -> Void)?
    
    init() {
    }
    
    internal func load(next increment: Int = 10) {
        self.loadingContent = true
        self.objectWillChange.send()
        
        let group = DispatchGroup()
        
        group.enter()
        FirebaseConnection.loadPendingContent(options: (limit: increment, includeThumbnailURLs: true, includeDetailedAuthors: false, startAfterDocumentID: lastLoadedDocumentID)) { results, error in
            guard let results = results else {
                self.showError(error: error ?? YTSError.unknownError, retry: {
                    self.load(next: increment)
                })
                print("Error getting content")
                group.leave()
                return
            }
            
            withAnimation {
                // The data will be unsorted, we need to sort the data by
                // tagID
                if self.sortables == nil {
                    self.sortables = []
                }
                
                for video in results.content.videos {
                    self.sortables!.append(video.sortable)
                }
                
                for audio in results.content.audios {
                    self.sortables!.append(audio.sortable)
                }
                
//                self.sortables = sortedContent
//                Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
//                    print("Sortables: \(self.sortables)")
//                    self.objectWillChange.send()
//                }
                
                self.lastLoadedDocumentID = results.metadata.newLastLoadedDocumentID
                self.retreivedAllContent = results.metadata.finalCall
                                
                self.sortables = self.sortables!.sorted(by: { lhs, rhs in
                    return lhs.date! > rhs.date!
                })
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in
                    self.loadingContent = false
                    self.reloadingContent = false
            }
        }
    }
    
    func initialLoad() {
        if !calledInitialLoad {
            self.calledInitialLoad = true
            load()
        }
    }
    
    func reload() {
        if !reloadingContent {
            reloadingContent = true
            self.lastLoadedDocumentID = nil
            self.sortables = nil
            //            self.favoriteContent = nil
            self.calledInitialLoad = false
            initialLoad()
        }
    }
    
    
}
