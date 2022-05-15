//
//  NewsArticleView.swift
//  Yeshivat Torat Shraga
//
//  Created by Benji Tusk on 16/01/2022.
//

import SwiftUI

struct NewsArticleCardView: View {
    var article: NewsArticle
    init(_ article: NewsArticle) {
        self.article = article
    }
    var body: some View {
        HStack {
            Rectangle()
                .fill(UI.cardBlueGradient)
                        
                .frame(width: 70)
//                .cornerRadius(3, corners: [.topRight, .bottomRight])
//                .shadow(radius: 3)
                .overlay(
                    Image(systemName: "newspaper")
                        .scaleEffect(1.35)
                        .foregroundColor(Color("ShragaGold"))
                )
                .foregroundColor(Color("ShragaGold"))
                .unredacted()
            
            
            // Rest of card goes here:
            VStack(alignment: .leading) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(article.title)
                            .font(.title3)
                            .bold()
//                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                }
                Text(article.body)
                    .font(.callout)
                    .foregroundColor(.gray)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                Spacer()
                HStack {
                    HStack {
                        Image(systemName: "person.fill")
                        Text(article.author)
                            .foregroundColor(Color("Gray"))
                    }
                    Spacer()
                    HStack {
                        let month = Date.monthNameFor(article.uploaded.get(.month), short: true)!
                        HStack {
                            let yearAsString = String(article.uploaded.get(.year))
                            Text("\(month) \(article.uploaded.get(.day)), \(yearAsString)")
                                .foregroundColor(Color("Gray"))
                            Image(systemName: "calendar")
                        }
                        
                    }
                    .padding(.trailing, 5)
                }
                .font(.footnote)
            }
            
            .padding([.vertical, .trailing])
            .padding(.leading, 5)
        }
        .frame(maxHeight: 150)
        .cornerRadius(UI.cornerRadius)
        .clipped()
        .background(
            RoundedRectangle(cornerRadius: UI.cornerRadius)
                .fill(Color.cardViewBG)
                .shadow(radius: UI.shadowRadius))
        //        .frame(maxHeight: 130)
    }
}

struct NewsArticleCardView_Previews: PreviewProvider {
    static var previews: some View {
        NewsArticleCardView(.sample)
            .padding()
            .foregroundColor(.shragaBlue)
            .previewLayout(.sizeThatFits)
    }
}
