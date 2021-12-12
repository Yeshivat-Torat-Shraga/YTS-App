//
//  DisplayRabbiModel.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 11/16/21.
//

import Foundation
import SwiftUI

class DisplayRabbiModel: ObservableObject, ErrorShower {
    var showError: Bool = false
    internal var errorToShow: Error?
    internal var retry: (() -> Void)?
    
    @Published var rabbi: DetailedRabbi
    @Published var content: Content?
    @Published var sortables: [SortableYTSContent]?
    
    init(rabbi: DetailedRabbi) {
        self.rabbi = rabbi
    }
    
    func load() {
        FirebaseConnection.loadContent(
            searchData: ["field": "attributionID",
                         "value": self.rabbi.firestoreID],
            includeThumbnailURLs: true) { results, error in
                guard let results = results else {
                    self.showError(error: error ?? YTSError.unknownError, retry: self.load)
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
    }
}
