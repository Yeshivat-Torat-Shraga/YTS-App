//
//  NewsArticleView.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 20/01/2022.
//

import SwiftUI

struct NewsArticleView: View {
    var article: NewsArticle
    init(_ article: NewsArticle) {
        self.article = article
    }
    var body: some View {
        ScrollView {
            Text(article.body)
            if article.images.count > 0 {
                SlideshowView(article.images)
                    .frame(height: 250)
                    .clipped()
                    .cornerRadius(UI.cornerRadius)
                    .shadow(radius: UI.shadowRadius)
                    .padding(.bottom)
            }
        }
        .padding(.horizontal)
        .navigationTitle(article.title)
    }
}

struct NewsArticleView_Previews: PreviewProvider {
    static var previews: some View {
        NewsView()
    }
}
