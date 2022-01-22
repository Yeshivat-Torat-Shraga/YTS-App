//
//  NewsView.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 10/12/2021.
//

import SwiftUI

struct NewsView: View {
    @ObservedObject var model = NewsModel()
    var body: some View {
        NavigationView {
            ScrollView {
                if let articles = model.articles {
                    ForEach(articles) { article in
                        NavigationLink(destination: NewsArticleView(article)) {                        
                            NewsArticleCardView(article)
                                .padding(.horizontal)
                        }
//                        .background(Color.white.cornerRadius(10).shadow(radius: UI.shadowRadius))
                    }
                }
            }
                .navigationTitle("YTS News")
        }
//        .onAppear {
//            self.model.load()
//        }
    }
}

struct NewsView_Previews: PreviewProvider {
    static var previews: some View {
        NewsView()
    }
}
