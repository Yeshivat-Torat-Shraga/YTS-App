//
//  Root.swift
//  Yeshivat Torat Shraga
//
//  Created by David Reese on 11/9/21.
//

import Foundation

class Root: ObservableObject {

    @Published var rebbeim: [Rabbi]?
    
    init() {
        FirebaseConnection.loadRabbis { results, error in
            guard let results = results else {
                fatalError(error!.localizedDescription)
            }
            rebbeim = results.rabbis
        }
    }
}
