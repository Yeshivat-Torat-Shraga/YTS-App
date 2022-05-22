//
//  NewsArticleView.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 20/01/2022.
//

import SwiftUI
import MarkdownUI

struct NewsArticleView: View {
    var article: NewsArticle
    var miniPlayerShowing: Binding<Bool>
    
    init(_ article: NewsArticle, miniPlayerShowing: Binding<Bool>) {
        self.article = article
        self.miniPlayerShowing = miniPlayerShowing
    }
    
    var body: some View {
        ScrollView {
            HStack {
                Markdown(article.body)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.primary)
                    .padding(.horizontal)
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
            
            Spacer()
            
            if miniPlayerShowing.wrappedValue {
                Spacer().frame(height: UI.playerBarHeight)
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
            NavigationLink(destination: NewsArticleView(.sample, miniPlayerShowing: .constant(false))) {
                NewsArticleCardView(.sample)
            }
            .padding()
        }
        .foregroundColor(.shragaBlue)
    }
}
