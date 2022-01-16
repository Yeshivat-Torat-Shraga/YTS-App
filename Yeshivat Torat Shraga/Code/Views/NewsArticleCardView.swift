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
            
            // START GRADIENT {
            
//            LinearGradient(gradient: Gradient(stops: [Gradient.Stop(color: Color(hue: 0.0744011430855257, saturation: 1.0, brightness: 1.0, opacity: 1.0), location: 0.0), Gradient.Stop(color: Color(hue: 0.13440065498811654, saturation: 1.0, brightness: 1.0, opacity: 1.0), location: 0.663504849947416)]), startPoint: UnitPoint.top, endPoint: UnitPoint.trailing)
            
                .fill(LinearGradient(
                    gradient: Gradient(
                        stops: [
                            Gradient.Stop(
                                color: Color(
                                    hue:        0.610,
                                    saturation: 0.500,
                                    brightness: 0.190),
                                location:       0.000),
                            Gradient.Stop(
                                color: Color(
                                    hue:        0.616,
                                    saturation: 0.431,
                                    brightness: 0.510),
                                location:       1.000)]),
                    startPoint: UnitPoint.bottomLeading,
                    endPoint: UnitPoint.trailing))
            
            // } END GRADIENT
            
                .frame(width: 70)
//                .cornerRadius(3, corners: [.topRight, .bottomRight])
//                .shadow(radius: 3)
                .overlay(
                    Image(systemName: "newspaper")
                        .scaleEffect(1.35)
                        .foregroundColor(Color("ShragaGold"))
                )
                .foregroundColor(Color("ShragaGold"))
            
            
            // Rest of card goes here:
            VStack(alignment: .leading) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(article.title)
                            .font(.title3)
                            .bold()
                            .foregroundColor(.primary)
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
        .cornerRadius(UI.cornerRadius)
        .clipped()
        .background(
            RoundedRectangle(cornerRadius: UI.cornerRadius)
                .fill(Color.white)
                .shadow(radius: UI.shadowRadius))
        //        .frame(maxHeight: 130)
    }
}

struct NewsArticleView_Previews: PreviewProvider {
    static var previews: some View {
        NewsArticleCardView(.sample)
        //            .previewLayout(.sizeThatFits)
    }
}
