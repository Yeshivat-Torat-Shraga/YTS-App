//
//  TagModel.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 11/12/2021.
//

import Foundation
import SwiftUI

class TagModel: ObservableObject, ErrorShower {
    var showError: Bool = false
    
    var errorToShow: Error?
    
    var retry: (() -> Void)?
    
    @Published var tag: Tag
    @Published var sortables: [Tag: [SortableYTSContent]]?
    //    @Published var
    
    init(tag: Tag) {
        self.tag = tag
    }
    
    func set(tag: Tag) {
        withAnimation {
            self.tag = tag
            self.load()
        }
    }
    
    func loadOnlyIfNeeded() {
        if sortables == nil {
            load()
        }
    }
    
    
    func load() {
        FirebaseConnection.loadContent(matching: tag) { results, error in
            guard let results = results else {
                self.showError(error: error ?? YTSError.unknownError, retry: self.load)
                return
            }
            
            withAnimation {
                // The data will be unsorted, we need to sort the data by
                // tagID
                var sortedContent: [Tag: [SortableYTSContent]] = [:]
                for video in results.content.videos {
                    if sortedContent[video.tag] == nil {
                        sortedContent[video.tag] = []
                    }
                    sortedContent[video.tag]!.append(video.sortable)
                }
                
                for audio in results.content.audios {
                    if sortedContent[audio.tag] == nil {
                        sortedContent[audio.tag] = []
                    }
                    sortedContent[audio.tag]!.append(audio.sortable)
                }
                
                self.sortables = sortedContent
            }
        }
    }
}
