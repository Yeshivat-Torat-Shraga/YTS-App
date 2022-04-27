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
    @Published internal var loadedAllArticles: Bool = false
    @Published internal var loadingArticles: Bool = false
    internal var lastLoadedArticleID: FirestoreID?
    var errorToShow: Error?
    var retry: (() -> Void)?

    init() {}
    
    func loadOnlyIfNeeded() {
        if articles == nil {
            load()
        }
    }
    
    func load() {
        loadingArticles = true
        FirebaseConnection.loadNews(lastLoadedDocumentID: lastLoadedArticleID, limit: 10) { results, error in
            guard let sortedArticles = results?.articles.sorted(by: { lhs, rhs in
                return lhs.uploaded > rhs.uploaded
            }) else {
                self.showError(error: error ?? YTSError.unknownError, retry: self.load)
                return
            }
            
            
            if let metadata = results?.metadata {
                if let newLastLoadedArticleID = metadata.newLastLoadedDocumentID {
                    self.lastLoadedArticleID = newLastLoadedArticleID
                }
                self.loadedAllArticles = metadata.finalCall
            }
            
            if self.articles == nil {
                self.articles = []
            }
            self.articles?.append(contentsOf: sortedArticles)
            self.loadingArticles = false
        }
    }
}
