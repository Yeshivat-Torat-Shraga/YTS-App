//
//  HomeViewModel.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 11/11/21.
//

import Foundation
import SwiftUI

class HomeViewModel: ObservableObject, ErrorShower {
    @Published var showError: Bool = false
    var errorToShow: Error?
    var retry: (() -> Void)?
    
    @Published var recentlyUploadedContent: Content?
    @Published var sortables: [SortableYTSContent]?
    @Published var rebbeim: [DetailedRabbi]?
    
    init() {
        initialLoad()
    }
    
    func initialLoad() {
        FirebaseConnection.loadRebbeim(includeProfilePictureURLs: true) { results, error in
            guard let rebbeim = results?.rebbeim as? [DetailedRabbi] else {
                self.showError(error: error ?? YTSError.unknownError, retry: self.initialLoad)
                return
            }
            
            withAnimation {
                self.rebbeim = rebbeim
            }
        }
        
        FirebaseConnection.loadContent(includeThumbnailURLs: true, includeAllAuthorData: true) { results, error in
            guard let content = results?.content else {
                self.showError(error: error ?? YTSError.unknownError, retry: self.initialLoad)
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
    }
}
