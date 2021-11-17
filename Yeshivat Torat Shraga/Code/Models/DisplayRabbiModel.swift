//
//  DisplayRabbiModel.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 11/16/21.
//

import Foundation

class DisplayRabbiModel: ObservableObject {
    @Published var rabbi: Rabbi
    init(rabbi: Rabbi) {
        self.rabbi = rabbi
    }
}
