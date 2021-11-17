//
//  Root.swift
//  Yeshivat Torat Shraga
//
//  Created by David Reese on 11/9/21.
//

import Foundation
import SwiftUI

class RootModel: ObservableObject {

    @Published var rebbeim: [DetailedRabbi]?
    
    init() {
        FirebaseConnection.loadRebbeim(includeProfilePictureURLs: true) { results, error in
            guard let results = results else {
                fatalError(error!.localizedDescription)
            }
            withAnimation {
            self.rebbeim = results.rabbis as! [DetailedRabbi]
            }
        }
    }
}
