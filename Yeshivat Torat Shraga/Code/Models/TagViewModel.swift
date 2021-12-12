//
//  TagViewModel.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 11/12/2021.
//

import Foundation

class TagViewModel: ObservableObject {
    let tag: Tag
    
    init(tag: Tag) {
        self.tag = tag
    }
}
