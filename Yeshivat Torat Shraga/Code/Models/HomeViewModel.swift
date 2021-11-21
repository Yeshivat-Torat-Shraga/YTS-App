//
//  HomeViewModel.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 11/11/21.
//

import Foundation
import SwiftUI

class HomeViewModel: ObservableObject {
    @Published var rebbeim: [DetailedRabbi]?
    
    init(rebbeim: [DetailedRabbi]) {
        self.rebbeim = rebbeim
    }
    
    init() {
        FirebaseConnection.loadRebbeim(includeProfilePictureURLs: true) { results, error in
            guard let rebbeim = results?.rebbeim as? [DetailedRabbi] else {
                fatalError(error!.localizedDescription)
            }
            withAnimation {
                self.rebbeim = rebbeim
            }
        }
    }
}
