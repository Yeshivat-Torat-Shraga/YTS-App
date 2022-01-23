//
//  HomeModel.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 11/11/21.
//

import Foundation
import SwiftUI

class HomeModel: ObservableObject, ErrorShower {
    @Published var showError: Bool = false
    var errorToShow: Error?
    var retry: (() -> Void)?
    
    @Published var recentlyUploadedContent: Content?
    @Published var sortables: [SortableYTSContent]?
    @Published var rebbeim: [DetailedRabbi]?
    @Published var slideshowImages: [SlideshowImage]?
    
    init() {
        load()
    }
    
    func load() {
        FirebaseConnection.loadRebbeim(includeProfilePictureURLs: true) { results, error in
            guard let rebbeim = results?.rebbeim as? [DetailedRabbi] else {
                self.showError(error: error ?? YTSError.unknownError, retry: self.load)
                return
            }
            
            withAnimation {
                self.rebbeim = rebbeim
            }
        }
        
        FirebaseConnection.loadContent(includeThumbnailURLs: true, includeAllAuthorData: true) { results, error in
            guard let content = results?.content else {
                self.showError(error: error ?? YTSError.unknownError, retry: self.load)
                return
            }

            withAnimation {
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
            }
        }
        
        FirebaseConnection.loadSlideshowImages(limit: 25) { results, error in
            self.slideshowImages = results?.images.sorted(by: { lhs, rhs in
                lhs.uploaded > rhs.uploaded
            })
        }
    }
}
