//
//  TagModel.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 11/12/2021.
//

import Foundation
import SwiftUI

class TagModel: ObservableObject {
    @Published var tag: Tag
    @Published var sortables: [SortableYTSContent]?
    @Published var content: Content?
    
    init(tag: Tag) {
        self.tag = tag
    }
    
    func set(tag: Tag) {
        withAnimation {
        self.tag = tag
        self.content = nil
        self.load()
        }
    }
    
    func load() {
        FirebaseConnection.loadContent(matchingTag: tag, includeThumbnailURLs: false) { results, error in
                guard let results = results else {
//                    self.showError(error: error ?? YTSError.unknownError, retry: self.load)
                    fatalError(error!.localizedDescription)
                }
                print(results)
                withAnimation {
                    self.content = results.content
                    
                    var sortables: [SortableYTSContent] = []
                    for audio in self.content!.audios {
                        sortables.append(audio.sortable)
                    }
                    for video in self.content!.videos {
                        sortables.append(video.sortable)
                    }
                    
                    self.sortables = sortables.sorted(by: { lhs, rhs in
                        return lhs.date! > rhs.date!
                    })
                    
                    
                }
                
//                DispatchQueue.global(qos: .background).async {
//                    for audio in self.content!.audios {
//                        if !(audio.author is DetailedRabbi) {
//                            audio.author = self.rabbi
//                        }
//                    }
//                    for video in self.content!.videos {
//                        if !(video.author is DetailedRabbi) {
//                            video.author = self.rabbi
//                        }
//                    }
//                }
            }
    }
}
