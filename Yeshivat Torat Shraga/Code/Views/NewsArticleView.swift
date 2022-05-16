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
            HStack {
                Text(article.body)
                    .multilineTextAlignment(.leading)
                    .padding()
                Spacer()
                }
            if article.images.count > 0 {
                SlideshowView(article.images)
                    .frame(height: 250)
                    .clipped()
                    .cornerRadius(UI.cornerRadius)
                    .shadow(radius: UI.shadowRadius)
                    .padding(.bottom)
            }
        }
        .navigationTitle(article.title)
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarTrailing) {
                LogoView(size: .small)
//                    .padding(.bottom)
            }
        })
    }
}

struct NewsArticleView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            NavigationLink(destination: NewsArticleView(.sample)) {
                NewsArticleCardView(.sample)
            }
            .padding()
        }
        .foregroundColor(.shragaBlue)
    }
}
