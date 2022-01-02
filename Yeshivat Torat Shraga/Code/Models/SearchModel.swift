//
//  SearchModel.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 28/12/2021.
//

import Foundation

class SearchModel: ObservableObject {
    func search() {
        FirebaseConnection.searchFirestore(query: <#T##String#>, searchOptions: <#T##NSDictionary?#>, completion: <#T##((videos: [Video], audios: [Audio], rabbis: [Rabbi])?, Error?) -> Void##((videos: [Video], audios: [Audio], rabbis: [Rabbi])?, Error?) -> Void##(_ results: (videos: [Video], audios: [Audio], rabbis: [Rabbi])?, _ error: Error?) -> Void#>)
    }
}
