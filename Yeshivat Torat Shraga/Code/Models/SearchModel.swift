//
//  SearchModel.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 28/12/2021.
//

import SwiftUI

class SearchModel: ObservableObject, ErrorShower {
    @Published var showError: Bool = false
    @Published var rebbeim: [Rabbi] = []
    @Published var sortables: [SortableYTSContent] = []
    @Published var content: Content?
    var errorToShow: Error?
    var retry: (() -> Void)?

    func search(_ query: String) {
        FirebaseConnection.search(query: query) { results, error in
            guard let rebbeim = results?.rebbeim else {
                self.showError(error: error ?? YTSError.unknownError, retry: {})
                return
            }
            
            guard let contents = results?.content else {
                self.showError(error: error ?? YTSError.unknownError, retry: {})
                return
            }
            
            withAnimation {
                self.sortables = []
                self.rebbeim = []
                self.content = contents
                for audio in self.content!.audios {
                    self.sortables.append(audio.sortable)
                }
                for video in self.content!.videos {
                    self.sortables.append(video.sortable)
                }
                
                self.sortables = self.sortables.sorted(by: { lhs, rhs in
                    return lhs.date! > rhs.date!
                })

                for rabbi in rebbeim {
                    self.rebbeim.append(rabbi)
                }
            }
        }
    }
}
