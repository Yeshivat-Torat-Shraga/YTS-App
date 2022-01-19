//
//  NewsModel.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 16/01/2022.
//

import SwiftUI
class NewsModel: ObservableObject, ErrorShower {
    @Published var articles: [NewsArticle]?
    @Published var showError: Bool = false
    var errorToShow: Error?
    var retry: (() -> Void)?

    init() {
        load()
    }
    
    func load() {
        self.articles = []
        FirebaseConnection.loadNews(limit: 10) { results, error in
            guard let sortedArticles = results?.articles.sorted(by: { lhs, rhs in
                return lhs.uploaded > rhs.uploaded
            }) else {
                self.showError(error: error ?? YTSError.unknownError, retry: self.load)
                return
            }
            
            for article in sortedArticles {
                withAnimation {
                    self.articles!.append(article)
                }
            }
        }
    }
}
