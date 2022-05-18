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
    @Published var sortables: [SortableYTSContent]?
    //    @Published var
    
    init(tag: Tag) {
        self.tag = tag
    }
    
    func loadOnlyIfNeeded() {
        if sortables == nil {
            load()
        }
    }
    
    
    func load() {
        FirebaseConnection.loadContent(matching: tag) { results, error in
            guard let results = results else {
                print(error?.localizedDescription ?? "Unknown error occured")
                self.showError(error: error ?? YTSError.unknownError, retry: self.load)
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
                
            }
        }
    }
}
