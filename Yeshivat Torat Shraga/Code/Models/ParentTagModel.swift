//
//  ParentTagModel.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 5/17/22.
//

import SwiftUI

class ParentTagModel: ObservableObject, ErrorShower {
    var showError: Bool = false
    var errorToShow: Error?
    
    var retry: (() -> Void)?
    
    typealias Metadata = (newLastLoadedDocumentID: FirestoreID?, finalCall: Bool, isLoadingContent: Bool)
    let tag: Tag
    @Published var content: [Tag: (sortables: [SortableYTSContent]?, metadata: Metadata)] = [:]
    @Published var runningInitialLoad: Bool = true
    
    init(_ tag: Tag) {
        self.tag = tag
    }
    
    func loadOnlyIfNeeded() {
        if runningInitialLoad {
            load(next: 2)
        }
    }
    
    func loadIndividualChild(child: Tag, next increment: Int = 10, group: DispatchGroup? = nil) {
        if self.content[child] == nil {
            let metadata: Metadata = (newLastLoadedDocumentID: nil, finalCall: false, isLoadingContent: true)
            child.metadata = metadata
            self.content[child] = (sortables: nil, metadata: metadata)
        } else {
            withAnimation {
                self.content[child]!.metadata.isLoadingContent = true
            }
        }
        FirebaseConnection.loadContent(options: (limit: increment,
                                                 includeThumbnailURLs: false,
                                                 includeDetailedAuthors: false,
                                                 startAfterDocumentID: self.content[child]!.metadata.newLastLoadedDocumentID),
                                       matching: child) { results, error in

            guard let results = results else {
                print(error?.localizedDescription ?? "Unknown error occured")
                self.showError(error: error ?? YTSError.unknownError, retry: {
                    self.load(next: increment)
                })
                group?.leave()
                return
            }
            
            withAnimation {
                if !results.content.videos.isEmpty ||
                    !results.content.audios.isEmpty {
                    if self.content[child]!.sortables == nil {
                        self.content[child]!.sortables = []
                    }
                }
                for audio in results.content.audios {
                    self.content[child]!.sortables!.append(audio.sortable)
                }
                
                for video in results.content.videos {
                    self.content[child]!.sortables!.append(video.sortable)
                }
                
            }
            self.content[child]!.metadata.newLastLoadedDocumentID = results.metadata.newLastLoadedDocumentID
            self.content[child]!.metadata.finalCall = results.metadata.finalCall
            self.content[child]!.metadata.isLoadingContent = false
            group?.leave()
        }
    }
    
    func load(next increment: Int = 4) {
        // We know that there will be children, because the parent view is only called if there are children
        guard let children = tag.children else {
            print("Warning: ParentTagModel was initialized on a Tag with nil children! This will result in unexpected behavior.")
            return
        }
        
        let group  = DispatchGroup()

        for child in children {
            group.enter()
            loadIndividualChild(child: child, next: increment, group: group)
        }
        group.notify(queue: .main) {
            withAnimation {
                self.runningInitialLoad = false
            }
        }
    }
}
